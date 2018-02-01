local foldername = KnownModIndex:GetModActualName(TUNING.ZOMBIEJ_ADDTIONAL_PACKAGE)

local Empty = Class(function()
end)

-- 矿车关闭
local additional_orbit = GetModConfigData("additional_orbit", foldername)
if additional_orbit ~= "open" then
	return Empty
end

------------------------------------------------------------------------------------------
local function inRange(current, target, range)
	local mCurrent = math.mod(current + 720, 360)
	local mTarget = math.mod(target + 720, 360)

	local min = mTarget - range
	local max = mTarget + range

	for i = -1, 1 do
		local rangeMin = min + (360 * i)
		local rangeMax = max + (360 * i)

		if rangeMin <= mCurrent and mCurrent <= rangeMax then
			return true
		end
	end

	return false
end

------------------------------------------------------------------------------------------
local PLAYER_SPEED_MULTI = 1.05 -- 玩家速度慢于矿车，所以需要一个速度加成
local SEARCH_RANGE = 1.2
local MIN_READJUST_RANGE = 1 -- 如果玩家和车太远将被重置坐标
local MIN_READJUST_RANGE_Q = MIN_READJUST_RANGE * MIN_READJUST_RANGE

local MineCar = Class(function(self, inst)
	self.inst = inst
	self.driver = nil
	self.drivable = true
	self.orbit = nil
	self.nextOrbit = nil
	self.lastDistance = 1000

	self.isDriving = false

	self.mineCarY = 0
	self.driverMass = 0

	self.onPlaced = nil
	self.onStartDrive = nil
	self.onStopDrive = nil
	self.onAddDriver = nil
	self.onRemoveDriver = nil
end)

function MineCar:MoveToClosestOrbit()
	local inst = self.inst

	local x, y, z = inst.Transform:GetWorldPosition()
	local instPoint = Point(inst.Transform:GetWorldPosition())
	local orbits = TheSim:FindEntities(x, 0, z, 2, { "aip_orbit" })

	-- Find closest one
	local closestDist = 100
	local closest = nil
	for i, target in ipairs(orbits) do
		local targetPoint = Point(target.Transform:GetWorldPosition())
		local dsq = distsq(instPoint, targetPoint)

		if closestDist > dsq then
			closestDist = dsq
			closest = target
		end
	end

	if closest ~= nil then
		local tx, ty, tz = closest.Transform:GetWorldPosition()
		inst.Physics:Teleport(tx, y, tz)
		self.orbit = closest
	end
end

------------------------------------------ 轨道 ------------------------------------------
function MineCar:FindNextOrbit()
	local prevOrbit = self.orbit
	local curOrbit = self.nextOrbit
	local nextOrbit = nil

	local x, y, z = curOrbit.Transform:GetWorldPosition()
	local orbits = TheSim:FindEntities(x, y, z, SEARCH_RANGE, { "aip_orbit" })

	for i, target in ipairs(orbits) do
		if target ~= prevOrbit and target ~= curOrbit then
			-- 只允许存在一条可以的走的路
			if nextOrbit == nil then
				nextOrbit = target
			else
				return nil
			end
		end
	end

	return nextOrbit
end

function MineCar:Placed()
	if self.onPlaced then
		self.onPlaced(self.inst)
	end
end

---------------------------------------- 移动管理 ----------------------------------------
function MineCar:GetSpeed()
	return self.inst.components.locomotor and self.inst.components.locomotor:GetRunSpeed() or 0
end

function MineCar:StartMove(nextOrbit)
	local carSpeed = self:GetSpeed()
	local x, y, z = self.inst.Transform:GetWorldPosition()

	if nextOrbit then
		self.nextOrbit = nextOrbit
	else
		local tmpOrbit = self.nextOrbit
		self.nextOrbit = self:FindNextOrbit()
		self.orbit = tmpOrbit
	end

	if not self.nextOrbit or not self.driver then
		-- 重置 矿车 和 驾驶员 位置
		if self.orbit then
			local cx, cy, cz = self.orbit.Transform:GetWorldPosition()
			self.inst.Physics:Teleport(cx, y, cz)
			if self.driver and self.driver.Physics then
				self.driver.Physics:Teleport(cx, cy, cz)
			end
		end

		self:StopMove()
		return
	end

	self.isDriving = true

	local ox, oy, oz = self.nextOrbit.Transform:GetWorldPosition()
	local angle = self.inst:GetAngleToPoint(ox, y, oz)

	self.inst.Transform:SetRotation(angle)
	self.inst.Physics:SetMotorVel(carSpeed, 0, 0)

	-- 同步驾驶员
	self:SyncDriver()

	self:StartUpdatingInternal()
end

function MineCar:StopMove()
	self.inst.Physics:Stop()
	if self.driver then
		self.driver.Physics:Stop()
	end
	self:StopUpdatingInternal()

	if self.isDriving and self.onStopDrive then
		self.onStopDrive(self.inst)
	end

	self.isDriving = false
end

function MineCar:GoDirect(rotation)
	if TheCamera == nil or not self.driver or not self.drivable then
		return
	end

	-- 重置矿车
	self:MoveToClosestOrbit()
	if not self.orbit then
		return
	end

	rotation = tonumber(rotation)

	-- 寻找轨道（第一次寻找需要根据页面角度来）
	local orbit = nil
	local x, y, z = self.inst.Transform:GetWorldPosition()
	local orbits = TheSim:FindEntities(x, 0, z, SEARCH_RANGE, { "aip_orbit" })
	for i, target in ipairs(orbits) do
		if target ~= self.orbit then
			local tx, ty, tz = target.Transform:GetWorldPosition()
			local angle = self.inst:GetAngleToPoint(tx, y, tz)

			if inRange(angle, rotation, 70) then
				orbit = target
				break
			end
		end
	end

	if orbit then
		self:StartMove(orbit)

		if self.onStartDrive then
			self.onStartDrive(self.inst)
		end
	else
		self:StopMove()
	end
end

----------------------------------------- 驾驶员 -----------------------------------------
function MineCar:AddDriver(driver)
	if self.driver ~= nil or driver:HasTag("aip_minecar_driver") then
		return
	end

	self.driver = driver

	if not self.driver then
		return
	end

	-- 速度加成
	if self.driver.components.locomotor then
		self.driver.components.locomotor:SetExternalSpeedMultiplier(self.inst, "aipc_minecar_speed", 0)
	end

	-- 同步位置
	local dx, dy, dz = self.driver.Transform:GetWorldPosition()
	local tx, ty, tz = self.inst.Transform:GetWorldPosition()
	self.driver.Physics:Teleport(tx, dy, tz)

	-- 碰撞移除
	self.driverMass = self.driver.Physics:GetMass()
	self.driver.Physics:SetCollides(false)
	self.driver.Physics:SetMass(0)

	-- 矿车高度加一以防止下不去
	self.mineCarY = ty
	self.inst.Physics:Teleport(tx, ty + .02, tz)

	-- 驾驶员事件
	if self.onAddDriver then
		self.onAddDriver(self.inst, self.driver)
	end

	-- 网络同步驾驶员ID
	if self.inst.components.aipc_minecar_client then
		self.inst.components.aipc_minecar_client:SetDriver(self.driver)
	end
end

-- TODO: Support multi driver later
function MineCar:RemoveDriver(driver)
	-- 速度减成
	if self.driver and self.driver.components.locomotor then
		self.driver.components.locomotor:RemoveExternalSpeedMultiplier(self.inst, "aipc_minecar_speed")
	end

	-- 没有司机就不开车了
	self:StopMove()

	-- 碰撞回归
	if self.driver then
		-- 玩家如果死了，就不用管了
		if not self.inst.components.health or not self.inst.components.health:IsDead() then
			self.driver.Physics:SetCollides(true)
			self.driver.Physics:SetMass(self.driverMass)
		end
	end

	-- 驾驶员事件
	if self.onRemoveDriver and self.driver then
		self.onRemoveDriver(self.inst, self.driver)
	end

	self.driver = nil

	-- 矿车高度回归
	local tx, ty, tz = self.inst.Transform:GetWorldPosition()
	self.inst.Physics:Teleport(tx, self.mineCarY, tz)

	-- 网络同步驾驶员ID
	if self.inst.components.aipc_minecar_client then
		self.inst.components.aipc_minecar_client:SetDriver()
	end
end

function MineCar:SyncDriver()
	if not self.driver then
		return
	end

	local carSpeed = self:GetSpeed()
	local dx, dy, dz = self.driver.Transform:GetWorldPosition()
	local tx, ty, tz = self.inst.Transform:GetWorldPosition()
	local dRotation = self.driver.Transform:GetRotation()
	local tRotation = self.inst.Transform:GetRotation()
	local dSpeed = self.driver.Physics:GetMotorSpeed()
	local tSpeed = self.inst.Physics:GetMotorSpeed()
	local dRunning = self.driver.components.locomotor and self.driver.components.locomotor.isrunning or false

	local dsq = distsq(dx, dz, tx, tz)
	if dRotation ~= tRotation or dsq > MIN_READJUST_RANGE_Q or dSpeed ~= tSpeed or dRunning then
		-- 停止移动
		if self.driver.components.locomotor then
			self.driver.components.locomotor:StopMoving()
			self.driver.components.locomotor:Clear()
		end

		-- 同步坐标 (使用SetPosition会比Teleport有更平滑的位移效果)
		-- self.driver.Physics:Teleport(tx, dy, tz)
		self.driver.Transform:SetPosition(tx, dy, tz)

		-- 同步位移
		self.driver.Transform:SetRotation(self.inst.Transform:GetRotation())
		self.driver.Physics:SetMotorVel(carSpeed * PLAYER_SPEED_MULTI, 0, 0)
	end
end

---------------------------------------- 更新检查 ----------------------------------------
function MineCar:StartUpdatingInternal()
	self.inst:StartUpdatingComponent(self)
end

function MineCar:StopUpdatingInternal()
	self.inst:StopUpdatingComponent(self)
end

function MineCar:OnUpdate(dt)
	-- 如果都没有
	if not self.inst or not self.driver or not self.nextOrbit then
		self:StopMove()
		return
	end

	local carSpeed = self:GetSpeed()
	local x, y, z = self.inst.Transform:GetWorldPosition()
	local ox, oy, oz = self.nextOrbit.Transform:GetWorldPosition()

	-- 坐标都没有就别开了
	if x == nil or z == nil or ox == nil or oz == nil then
		self:StopMove()
		return
	end

	-- 检查是否到达目标轨道
	local reached_dest = false
	local dsq = distsq(x, z, ox, oz)

	if self.lastDistance < dsq then
		reached_dest = true
	else
		local run_dist = carSpeed * dt * .5
		local reached_dest = dsq <= math.max(run_dist * run_dist, .15 * .15)
	end
	self.lastDistance = dsq

	-- 位移驾驶员
	self:SyncDriver()

	if reached_dest then
		self.lastDistance = 1000
		self:StartMove()
	end
end

---------------------------------------- 存储逻辑 ----------------------------------------
function MineCar:OnSave()
	local data = {}
	--[[if self.driver ~= nil then
		data.driver = self.driver:GetSaveRecord() or nil
	end]]
	return data
end

function MineCar:OnLoad(data)
	--[[if data and data.driver ~= nil then
		local driver = SpawnSaveRecord(data.driver)
		self:AddDriver(driver)
	end]]

	self.inst:DoTaskInTime(0, function()
		self:MoveToClosestOrbit()
	end)
end

MineCar.OnRemoveFromEntity = MineCar.RemoveDriver
MineCar.OnRemoveEntity = MineCar.RemoveDriver

return MineCar