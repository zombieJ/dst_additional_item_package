local config = require("configurations/aip_pig_king_train")
local vitals = require("aip_pig_king_train_vitals")
local devMode = aipGetModConfig("dev_mode") == "enabled"
local LOG_PREFIX = "[PigKingTrain][Passenger]"
local VERTICAL_ERROR_BUCKETS = { 0.05, 0.10, 0.15, 0.25 }

-- 开发模式记录原矿车运动状态和高度误差，避免逐帧日志淹没控制台。
local function Debug(...)
	if devMode then aipPrint(LOG_PREFIX, ...) end
end

-- 高架轨道沿用旧驾驶器的净空补偿，地面总站仍保持零高度。
local function RideHeight(trackY)
	if trackY <= config.GROUND_HEIGHT then return trackY end
	return trackY + config.RIDE_CLEARANCE
end

-- 读取物理启用状态，供乘车诊断和退出恢复使用。
local function PhysicsActive(inst)
	return inst.Physics ~= nil and inst.Physics:IsActive()
end

-- 拒绝 NaN 与无穷值，防止非法运动向量把乘客永久卡在轨道上。
local function IsFinite(value)
	return type(value) == "number" and value == value and math.abs(value) < math.huge
end

-- 捕获误差峰值所在轨道、坡度和运动向量，结束时可一次性复盘而不逐帧刷屏。
local function CaptureVerticalSnapshot(inst, run, driver, expectedY, signedError, verticalStep)
	local x, actualY, z = inst.Transform:GetWorldPosition()
	local motorX, motorY, motorZ = inst.Physics:GetMotorVel()
	local velocityX, velocityY, velocityZ = inst.Physics:GetVelocity()
	local control = driver.lastVerticalControl or {}
	local profile = run.plan.segmentProfiles ~= nil and run.plan.segmentProfiles[run.pointIndex] or nil
	return { tick = TheSim:GetTick(), point = run.pointIndex, x = x, y = actualY, z = z,
		trackY = run.position.y, expectedY = expectedY, error = signedError, step = verticalStep,
		motorX = motorX, motorY = motorY, motorZ = motorZ,
		velocityX = velocityX, velocityY = velocityY, velocityZ = velocityZ,
		sourceY = control.sourceY or run.position.y, targetY = control.targetY or run.position.y,
		progress = control.progress or 0, slope = control.slope or 0,
		feedForward = control.feedForward or 0,
		gravityCompensation = control.gravityCompensation or 0,
		mode = profile ~= nil and profile.mode or "unknown",
		ramp = profile ~= nil and profile.ramp == true or math.abs(control.slope or 0) > 0.001 }
end

-- 将垂直诊断快照压缩为单行 AIP 日志。
local function FormatVerticalSnapshot(snapshot)
	if snapshot == nil then return "snapshot=nil" end
	return string.format(
		"tick=%s point=%s mode=%s ramp=%s pos=(%.2f,%.3f,%.2f) trackY=%.3f rideY=%.3f error=%+.4f step=%+.4f endpoints=%.3f->%.3f progress=%.3f slope=%+.4f motor=(%.2f,%.3f,%.2f) velocity=(%.2f,%.3f,%.2f) feed=%+.3f gravity=%+.3f",
		tostring(snapshot.tick), tostring(snapshot.point), tostring(snapshot.mode), tostring(snapshot.ramp),
		snapshot.x, snapshot.y, snapshot.z, snapshot.trackY, snapshot.expectedY,
		snapshot.error, snapshot.step, snapshot.sourceY, snapshot.targetY, snapshot.progress,
		snapshot.slope, snapshot.motorX, snapshot.motorY, snapshot.motorZ,
		snapshot.velocityX, snapshot.velocityY, snapshot.velocityZ,
		snapshot.feedForward, snapshot.gravityCompensation)
end

-- 按地面、平高架、上坡和下坡汇总误差，便于一次实机运行比较控制参数效果。
local function UpdateVerticalRegime(diagnostics, driver, trackY, signedError)
	local slope = driver.lastVerticalControl ~= nil and driver.lastVerticalControl.slope or 0
	local name = slope > 0.001 and "up-ramp" or slope < -0.001 and "down-ramp"
		or trackY > config.GROUND_HEIGHT and "elevated-flat" or "ground-flat"
	local regime = diagnostics.regimes[name]
	regime.samples = regime.samples + 1
	regime.errorSum = regime.errorSum + signedError
	regime.absoluteErrorSum = regime.absoluteErrorSum + math.abs(signedError)
	regime.maxAbsoluteError = math.max(regime.maxAbsoluteError, math.abs(signedError))
end

-- 将四类纵向工况压缩为样本数、平均偏差、平均绝对偏差和峰值。
local function FormatVerticalRegimes(diagnostics)
	local values = {}
	for _, name in ipairs({ "ground-flat", "elevated-flat", "up-ramp", "down-ramp" }) do
		local regime = diagnostics.regimes[name]
		local divisor = math.max(1, regime.samples)
		table.insert(values, string.format("%s:%d/%+.4f/%.4f/%.4f", name, regime.samples,
			regime.errorSum / divisor, regime.absoluteErrorSum / divisor, regime.maxAbsoluteError))
	end
	return table.concat(values, ",")
end

-- 只对本地乘客切换镜头；实体物理由原矿车驱动器维持，不在客户端反复开关。
local function OnTourDirty(inst)
	local passenger = inst.components.aipc_pig_king_train_passenger
	if inst ~= ThePlayer or passenger == nil then return end
	local active = passenger.active:value()
	Debug("local-tour", "tourActive=" .. tostring(active),
		"physicsActive=" .. tostring(inst.Physics ~= nil and inst.Physics:IsActive()))
	if active and not passenger.cameraActive then
		passenger.cameraActive = true
		passenger.oldCameraMode = TheCamera._aipFlyModes ~= nil and TheCamera._aipFlyModes.driver or false
		TheCamera:SetFlyView(true, "driver")
	elseif not active and passenger.cameraActive then
		passenger.cameraActive = false
		TheCamera:SetFlyView(passenger.oldCameraMode or false, "driver")
	end
end

local Passenger = Class(function(self, inst)
	self.inst = inst
	self.run = nil
	self.active = net_bool(inst.GUID, "aip_train_passenger", "aip_train_passenger_dirty")
	inst:ListenForEvent("aip_train_passenger_dirty", OnTourDirty)
	if not TheWorld.ismastersim then return end
	self.active:set(false)

	-- 自动存档保留陆地总站坐标，服务器重启后不会把乘客留在消失的轨道上。
	local originalGetSaveRecord = inst.GetSaveRecord
	inst.GetSaveRecord = function(player, ...)
		local record, references = originalGetSaveRecord(player, ...)
		if self.run ~= nil then
			local point = self.run.plan.station
			record.x, record.y, record.z = point.x, nil, point.z
			record.puid, record.rx, record.ry, record.rz = nil, nil, nil, nil
		end
		return record, references
	end

	-- 包装当前玩家的矿车入口；普通驾驶完全沿用原组件的方法。
	local driver = inst.components.aipc_orbit_driver
	if driver == nil then return end
	local originalAbort, originalDriveTo, originalContinue = driver.AbortDrive, driver.DriveTo, driver.TryContinue
	driver.AbortDrive = function(current, ...)
		-- 原矿车的受击、落水回调没有原因参数，观光期间只允许实际死亡触发下车。
		if self.run ~= nil then
			if self:IsDead() then self:Finish("death") end
			return
		end
		return originalAbort(current, ...)
	end
	driver.DriveTo = function(current, x, z, exit)
		if self.run ~= nil then
			if exit then self:Finish("cancelled") end
			return
		end
		return originalDriveTo(current, x, z, exit)
	end
	driver.TryContinue = function(current, ...)
		if self.run ~= nil then return end
		return originalContinue(current, ...)
	end
end)

-- 判断实际死亡，兼容组件卸载和已经变成幽灵的玩家。
function Passenger:IsDead()
	local health = self.inst.components.health
	return self.inst:HasTag("playerghost") or health ~= nil and health:IsDead()
end

-- 状态被覆盖后只恢复矿车动画，实际位移继续交给原矿车物理驱动器。
function Passenger:RestoreDrivingState()
	if self.inst.sg ~= nil then
		if self.inst.sg.currentstate == nil or self.inst.sg.currentstate.name ~= "aip_drive" then
			self.inst.sg:GoToState("aip_drive")
		end
		self.inst.sg:AddStateTag("nointerrupt")
	end
	if self.inst.components.drownable ~= nil then self.inst.components.drownable.enabled = false end
end

-- 根据原驱动器的当前端点计算轨道高度，只用于状态记录和偏差诊断。
function Passenger:UpdateTrackPosition(run, driver)
	local position = self.inst:GetPosition()
	local x, z = position.x, position.z
	local source = driver.orbitPoint
	local target = driver.nextOrbitPoint
	local trackY = run.position ~= nil and run.position.y or run.plan.station.y
	if source ~= nil and source:IsValid() then
		local sourcePos = source:GetPosition()
		trackY = sourcePos.y
		local rideY = RideHeight(sourcePos.y)
		if target ~= nil and target:IsValid() then
			local targetPos = target:GetPosition()
			local totalDistance = aipDist(sourcePos, targetPos)
			local ratio = totalDistance > 0 and math.min(1, aipDist(position, sourcePos) / totalDistance) or 1
			trackY = sourcePos.y + (targetPos.y - sourcePos.y) * ratio
			rideY = RideHeight(sourcePos.y)
				+ (RideHeight(targetPos.y) - RideHeight(sourcePos.y)) * ratio
		end
		run.position = { x = x, y = trackY, z = z }
		return rideY
	end
	run.position = { x = x, y = trackY, z = z }
	return RideHeight(trackY)
end

-- 检查物理向量与位移进度，异常或连续停滞时立即结束运行，让测试仍能报告并暂停。
function Passenger:ValidateMotion(run, driver, dt)
	local x, y, z = self.inst.Transform:GetWorldPosition()
	local motorX, motorY, motorZ = self.inst.Physics:GetMotorVel()
	if not PhysicsActive(self.inst) or not IsFinite(x) or not IsFinite(y) or not IsFinite(z)
		or not IsFinite(motorX) or not IsFinite(motorY) or not IsFinite(motorZ) then
		run.error = { code = "invalid_motion", detail = string.format(
			"point=%s,pos=(%s,%s,%s),motor=(%s,%s,%s),physicsActive=%s",
			tostring(run.pointIndex), tostring(x), tostring(y), tostring(z),
			tostring(motorX), tostring(motorY), tostring(motorZ), tostring(PhysicsActive(self.inst))) }
		Debug("ride-invalid", "run=" .. tostring(run.id), run.error.detail)
		self:Finish("invalid_motion")
		return false
	end
	local diagnostics = run.rideDiagnostics
	if diagnostics.lastMotionX ~= nil then
		local dx, dy, dz = x - diagnostics.lastMotionX, y - diagnostics.lastMotionY, z - diagnostics.lastMotionZ
		local moved = dx * dx + dy * dy + dz * dz >= config.RIDE_STALL_DISTANCE^2
		local advanced = diagnostics.lastOrbitPoint ~= driver.orbitPoint
		diagnostics.stallElapsed = (moved or advanced) and 0 or diagnostics.stallElapsed + dt
	end
	diagnostics.lastMotionX, diagnostics.lastMotionY, diagnostics.lastMotionZ = x, y, z
	diagnostics.lastOrbitPoint = driver.orbitPoint
	if diagnostics.stallElapsed >= config.RIDE_STALL_TIMEOUT then
		run.error = { code = "ride_stalled", detail = string.format(
			"point=%s,pos=(%.2f,%.3f,%.2f),stall=%.1fs", tostring(run.pointIndex), x, y, z,
			diagnostics.stallElapsed) }
		Debug("ride-stalled", "run=" .. tostring(run.id), run.error.detail)
		self:Finish("ride_stalled")
		return false
	end
	return true
end

-- 记录连续物理移动的目标、实测高度与速度，便于识别真实坐标抖动。
function Passenger:UpdateDiagnostics(run, driver, dt)
	local x, actualY, z = self.inst.Transform:GetWorldPosition()
	local expectedY = self:UpdateTrackPosition(run, driver)
	local diagnostics = run.rideDiagnostics
	local signedError = actualY - expectedY
	local absoluteError = math.abs(signedError)
	local verticalStep = diagnostics.lastActualY ~= nil and actualY - diagnostics.lastActualY or 0
	local direction = math.abs(verticalStep) >= 0.002 and (verticalStep > 0 and 1 or -1) or 0
	if direction ~= 0 and diagnostics.lastDirection ~= nil and direction ~= diagnostics.lastDirection then
		diagnostics.directionChanges = diagnostics.directionChanges + 1
		local control = driver.lastVerticalControl or {}
		if math.abs(control.slope or 0) > 0.001 then
			diagnostics.rampDirectionChanges = diagnostics.rampDirectionChanges + 1
		else
			diagnostics.flatDirectionChanges = diagnostics.flatDirectionChanges + 1
		end
	end
	if direction ~= 0 then diagnostics.lastDirection = direction end
	diagnostics.lastActualY = actualY
	diagnostics.elapsed = diagnostics.elapsed + dt
	diagnostics.samples = diagnostics.samples + 1
	diagnostics.maxPositiveError = math.max(diagnostics.maxPositiveError, signedError)
	diagnostics.minNegativeError = math.min(diagnostics.minNegativeError, signedError)
	UpdateVerticalRegime(diagnostics, driver, run.position.y, signedError)
	local bucketIndex = #VERTICAL_ERROR_BUCKETS + 1
	for index, threshold in ipairs(VERTICAL_ERROR_BUCKETS) do
		if absoluteError <= threshold then bucketIndex = index break end
	end
	diagnostics.errorBuckets[bucketIndex] = diagnostics.errorBuckets[bucketIndex] + 1
	if absoluteError > diagnostics.maxVerticalError then
		diagnostics.maxVerticalError = absoluteError
		diagnostics.maxVerticalErrorSnapshot = CaptureVerticalSnapshot(
			self.inst, run, driver, expectedY, signedError, verticalStep)
		local logStep = math.max(0.001, config.RIDE_VERTICAL_PEAK_LOG_STEP or 0.025)
		local peakLevel = math.floor(absoluteError / logStep)
		if absoluteError >= VERTICAL_ERROR_BUCKETS[1] and peakLevel > diagnostics.lastPeakLogLevel then
			diagnostics.lastPeakLogLevel = peakLevel
			Debug("ride-vertical-peak", "run=" .. tostring(run.id),
				FormatVerticalSnapshot(diagnostics.maxVerticalErrorSnapshot))
		end
	end
	if math.abs(verticalStep) > diagnostics.maxVerticalStep then
		diagnostics.maxVerticalStep = math.abs(verticalStep)
		diagnostics.maxVerticalStepSnapshot = CaptureVerticalSnapshot(
			self.inst, run, driver, expectedY, signedError, verticalStep)
	end
	if diagnostics.elapsed >= config.RIDE_DIAGNOSTIC_INTERVAL then
		local motorX, motorY, motorZ = self.inst.Physics:GetMotorVel()
		local velocityX, velocityY, velocityZ = self.inst.Physics:GetVelocity()
		local state = self.inst.sg ~= nil and self.inst.sg.currentstate ~= nil and self.inst.sg.currentstate.name or "nil"
		local platform = self.inst.GetCurrentPlatform ~= nil and self.inst:GetCurrentPlatform() or nil
		Debug("ride-motion", "run=" .. tostring(run.id), "tick=" .. tostring(TheSim:GetTick()),
			"point=" .. tostring(run.pointIndex),
			string.format("pos=(%.2f,%.3f,%.2f) trackY=%.3f rideY=%.3f error=%+.4f maxError=%.4f maxStep=%.4f",
				x, actualY, z, run.position.y, expectedY, signedError,
				diagnostics.maxVerticalError, diagnostics.maxVerticalStep),
			string.format("motor=(%.2f,%.3f,%.2f) velocity=(%.2f,%.3f,%.2f)",
				motorX, motorY, motorZ, velocityX, velocityY, velocityZ),
			"physicsActive=" .. tostring(PhysicsActive(self.inst)), "state=" .. tostring(state),
			"platform=" .. tostring(platform ~= nil and (platform.prefab or platform.GUID) or "nil"),
			string.format("directionChanges=%d(flat=%d,ramp=%d) overLimit=%d",
				diagnostics.directionChanges, diagnostics.flatDirectionChanges,
				diagnostics.rampDirectionChanges, diagnostics.errorBuckets[5]))
		diagnostics.elapsed = 0
	end
end

-- 进入观景圆弧时降低原驱动器速度，离开圆弧后恢复观光列车巡航速度。
function Passenger:UpdateRideSpeed(run, driver)
	local scenic = run.plan.scenicSegments ~= nil and run.plan.scenicSegments[run.pointIndex] == true
	local speed = scenic and config.SCENIC_SPEED or config.SPEED
	if driver.speed ~= speed then
		driver.speed = speed
		Debug("ride-speed", "run=" .. tostring(run.id), "point=" .. tostring(run.pointIndex),
			"mode=" .. (scenic and "scenic-arc" or "cruise"), "speed=" .. tostring(speed))
	end
end

-- 使用既有矿车动画上车，观光移动和所有临时状态由本组件维护。
function Passenger:Begin(run)
	local driver = self.inst.components.aipc_orbit_driver
	local rider, flyer = self.inst.components.rider, self.inst.components.aipc_flyer_sc
	if driver == nil or self.run ~= nil or driver:isDriving() or driver:IsInvalidDriver() or self.inst:HasTag("playerghost")
		or (rider ~= nil and rider:IsRiding()) or (flyer ~= nil and flyer:IsFlying()) then return false end
	-- 在原驾驶器开始修改状态前就登记运行；上车中途报错时也能清空它的矿车引用。
	self.run = run
	run.pointIndex = 1
	run.driverSpeed = driver.speed
	run.driverGroundHeight = driver.groundHeight
	run.driverRideClearance = driver.rideClearance
	run.driverGravityCompensation = driver.verticalGravityCompensation
	run.driverVerticalFeedForward = driver.useVerticalFeedForward
	driver.groundHeight = config.GROUND_HEIGHT
	driver.rideClearance = config.RIDE_CLEARANCE
	driver.verticalGravityCompensation = config.RIDE_VERTICAL_GRAVITY_COMPENSATION
	driver.useVerticalFeedForward = true
	run.position = { x = run.plan.station.x, y = run.plan.station.y, z = run.plan.station.z }
	run.pointLookup = {}
	for index, point in pairs(run.points) do run.pointLookup[point] = index end
	run.hadNoTarget = self.inst:HasTag("notarget")
	local drownable = self.inst.components.drownable
	run.drownableEnabled = drownable ~= nil and drownable.enabled
	if not driver:UseMineCar(run.car, run.points[1]) then
		driver.groundHeight = run.driverGroundHeight
		driver.rideClearance = run.driverRideClearance
		driver.verticalGravityCompensation = run.driverGravityCompensation
		driver.useVerticalFeedForward = run.driverVerticalFeedForward
		self.run = nil
		return false
	end
	driver.speed = config.SPEED
	run.vitalsLock = vitals.Lock(self.inst)
	if drownable ~= nil then drownable.enabled = false end
	self.inst:AddTag("notarget")
	-- 临时折线只提供唯一下一端点，移动、转向和上下坡全部复用原矿车驱动器。
	driver:SetRouteProvider(function(current, excluded)
		if self.run ~= run or current == nil then return {} end
		local index = run.pointLookup[current] or current._aip_train_point_index
		local nextPoint = index ~= nil and run.points[index + 1] or nil
		local link = index ~= nil and run.links[index] or nil
		return nextPoint ~= nil and nextPoint:IsValid() and nextPoint ~= excluded
			and link ~= nil and link:IsValid() and { nextPoint } or {}
	end)
	local first, second = run.points[1], run.points[2]
	if first == nil or second == nil then self:Finish("track_lost") return false end
	local firstPosition, secondPosition = first:GetPosition(), second:GetPosition()
	driver:DriveFromPoint(aipGetAngle(firstPosition, secondPosition))
	if driver.nextOrbitPoint ~= second then self:Finish("track_lost") return false end
	self:RestoreDrivingState()
	run.rideDiagnostics = { elapsed = 0, samples = 0, maxVerticalError = 0, maxVerticalStep = 0,
		maxPositiveError = 0, minNegativeError = 0, directionChanges = 0,
		flatDirectionChanges = 0, rampDirectionChanges = 0, stallElapsed = 0,
		errorBuckets = { 0, 0, 0, 0, 0 }, lastPeakLogLevel = -1,
		regimes = {
			["ground-flat"] = { samples = 0, errorSum = 0, absoluteErrorSum = 0, maxAbsoluteError = 0 },
			["elevated-flat"] = { samples = 0, errorSum = 0, absoluteErrorSum = 0, maxAbsoluteError = 0 },
			["up-ramp"] = { samples = 0, errorSum = 0, absoluteErrorSum = 0, maxAbsoluteError = 0 },
			["down-ramp"] = { samples = 0, errorSum = 0, absoluteErrorSum = 0, maxAbsoluteError = 0 },
		} }
	Debug("ride-begin", "run=" .. tostring(run.id), "physicsActive=" .. tostring(PhysicsActive(self.inst)),
		"movement=original-motor", string.format("trackY=%.3f rideY=%.3f", run.position.y, RideHeight(run.position.y)),
		string.format("verticalGain=%.1f feedForward=true gravityCompensation=%.2f clearance=%.2f",
			driver.ySpeed, driver.verticalGravityCompensation, driver.rideClearance))
	self.active:set(true)
	if not TheNet:IsDedicated() then OnTourDirty(self.inst) end
	self.inst:StartUpdatingComponent(self)
	return true
end

-- 保护更新入口；意外 Lua 错误转为安全回村，由测试器记录失败而不扩大成崩溃。
function Passenger:OnUpdate(dt)
	if self.run == nil then return end
	local ok, err = pcall(self.Advance, self, dt)
	if not ok and self.run ~= nil then
		self.run.error = { code = "passenger_update_failed", detail = tostring(err) }
		self:Finish("passenger_update_failed")
	end
end

-- 观察原矿车驱动器的端点推进，负责到站、保护和诊断，不再强制写人物坐标。
function Passenger:Advance(dt)
	local run = self.run
	if run == nil then return end
	if self:IsDead() then self:Finish("death") return end
	if not self.inst:IsValid() then self:Finish("passenger_removed") return end
	local driver = self.inst.components.aipc_orbit_driver
	if driver == nil or run.car == nil or not run.car:IsValid() then
		self:Finish("track_lost")
		return
	end
	-- 临时进入 Limbo 时保持锁定等待；离线与换分片由运行管理器单独结束。
	if self.inst:IsInLimbo() then return end
	vitals.Maintain(run.vitalsLock)
	self:RestoreDrivingState()
	local observedIndex = run.pointLookup[driver.orbitPoint]
		or driver.orbitPoint ~= nil and driver.orbitPoint._aip_train_point_index
	if observedIndex ~= nil and observedIndex > run.pointIndex then
		for index = run.pointIndex + 1, observedIndex do
			run.pointIndex = index
			local stop = run.plan.stops[index]
			if stop ~= nil then run.onStop(stop) end
		end
		if run.onAdvance ~= nil then run.onAdvance(run.pointIndex) end
	end
	self:UpdateRideSpeed(run, driver)
	if run.pointIndex == #run.plan.points then self:Finish("complete") return end
	local target = driver.nextOrbitPoint
	if target == nil or target ~= run.points[run.pointIndex + 1] or not target:IsValid() then
		self:Finish("track_lost")
		return
	end
	if not self:ValidateMotion(run, driver, dt) then return end
	self:UpdateDiagnostics(run, driver, dt)
end

-- 解除驾驶并恢复原有状态，再通知运行管理器回村和清理，防止重复结束。
function Passenger:Finish(reason)
	local run = self.run
	if run == nil then return end
	self.run = nil
	local diagnostics = run.rideDiagnostics
	if diagnostics ~= nil then
		Debug("ride-finish", "run=" .. tostring(run.id), "reason=" .. tostring(reason),
			"samples=" .. tostring(diagnostics.samples),
			string.format("maxVerticalError=%.4f signedRange=%+.4f/%+.4f maxVerticalStep=%.4f directionChanges=%d(flat=%d,ramp=%d)",
				diagnostics.maxVerticalError, diagnostics.minNegativeError, diagnostics.maxPositiveError,
				diagnostics.maxVerticalStep, diagnostics.directionChanges,
				diagnostics.flatDirectionChanges, diagnostics.rampDirectionChanges))
		Debug("ride-vertical-buckets", "run=" .. tostring(run.id),
			string.format("absError<=0.05:%d,<=0.10:%d,<=0.15:%d,<=0.25:%d,>0.25:%d",
				diagnostics.errorBuckets[1], diagnostics.errorBuckets[2], diagnostics.errorBuckets[3],
				diagnostics.errorBuckets[4], diagnostics.errorBuckets[5]))
		Debug("ride-vertical-regimes", "run=" .. tostring(run.id),
			"format=samples/meanSigned/meanAbs/maxAbs", FormatVerticalRegimes(diagnostics))
		Debug("ride-vertical-max-error", "run=" .. tostring(run.id),
			FormatVerticalSnapshot(diagnostics.maxVerticalErrorSnapshot))
		Debug("ride-vertical-max-step", "run=" .. tostring(run.id),
			FormatVerticalSnapshot(diagnostics.maxVerticalStepSnapshot))
	end
	vitals.Release(run.vitalsLock)
	self.inst:StopUpdatingComponent(self)
	local driver = self.inst.components.aipc_orbit_driver
	local valid = self.inst:IsValid()
	if driver ~= nil then
		driver.speed = run.driverSpeed or driver.speed
		driver.groundHeight = run.driverGroundHeight or driver.groundHeight
		driver.rideClearance = run.driverRideClearance or driver.rideClearance
		driver.verticalGravityCompensation = run.driverGravityCompensation or 0
		driver.useVerticalFeedForward = run.driverVerticalFeedForward == true
		if valid and self.inst.Physics ~= nil then driver:StopDrive()
		else self.inst:StopUpdatingComponent(driver) end
		driver:SetRouteProvider(nil)
		driver.minecar, driver.orbitPoint, driver.nextOrbitPoint, driver.lastRotate = nil, nil, nil, nil
	end
	if valid then
		self.inst:RemoveTag("aip_orbit_driver")
		if not run.hadNoTarget then self.inst:RemoveTag("notarget") end
	end
	local drownable = self.inst.components.drownable
	if drownable ~= nil then drownable.enabled = run.drownableEnabled end
	if valid then
		self.inst.Physics:SetActive(true)
		if self.inst:HasTag("playerghost") then
			MakeGhostPhysics(self.inst, 1, .5)
		else
			MakeCharacterPhysics(self.inst, 75, .5)
		end
	end
	if valid and self.inst.sg ~= nil and self.inst.sg.currentstate ~= nil
		and self.inst.sg.currentstate.name == "aip_drive" and not self:IsDead() then
		self.inst.sg:GoToState("idle")
	end
	if valid and self.inst.components.aipc_orbit_driver_client ~= nil then
		self.inst.components.aipc_orbit_driver_client.isDriving:set(false)
	end
	if valid then self.active:set(false) end
	if not TheNet:IsDedicated() then OnTourDirty(self.inst) end
	if run.onFinish ~= nil then run.onFinish(reason) end
end

-- 组件被移除时也走同一条回退路径。
function Passenger:OnRemoveFromEntity()
	if self.run ~= nil then self:Finish("passenger_removed") end
end

return Passenger
