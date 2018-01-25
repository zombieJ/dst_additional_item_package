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
local SEARCH_RANGE = 1.2
local MIN_READJUST_RANGE = .5 -- 如果玩家和车太远将被重置坐标
local MIN_READJUST_RANGE_Q = MIN_READJUST_RANGE * MIN_READJUST_RANGE

local MineCar = Class(function(self, inst)
	self.inst = inst
	self.driver = nil
	self.updatetask = nil
	self.orbit = nil
	self.nextOrbit = nil
	self.lastDistance = 1000
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
		inst.Transform:SetPosition(tx, y, tz)
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

	if not self.nextOrbit then
		-- 重置 矿车 和 驾驶员 位置
		if self.orbit then
			local cx, cy, cz = self.orbit.Transform:GetWorldPosition()
			self.inst.Transform:SetPosition(cx, y, cz)
			self.driver.Transform:SetPosition(cx, cy, cz)
		end

		self:StopMove()
		return
	end

	local ox, oy, oz = self.nextOrbit.Transform:GetWorldPosition()
	local angle = self.inst:GetAngleToPoint(ox, y, oz)

	self.inst.Transform:SetRotation(angle)
	self.inst.Physics:SetMotorVel(carSpeed, 0, 0)

	self:StartUpdatingInternal()
end

function MineCar:StopMove()
	self.inst.Physics:Stop()
	if self.driver then
		self.driver.Physics:Stop()
	end
	self:StopUpdatingInternal()
end

function MineCar:GoDirect(direct)
	if TheCamera == nil or not self.driver then
		return
	end

	-- 重置矿车
	self:MoveToClosestOrbit()
	if not self.orbit then
		return
	end

	-- 计算角度
	local screenRotation = TheCamera:GetHeading() -- 指向屏幕左侧
	local rotation = -(screenRotation - 45) + 45

	if direct == "left" then
		rotation = rotation
	elseif direct == "down" then
		rotation = rotation - 90
	elseif direct == "right" then
		rotation = rotation + 180
	elseif direct == "up" then
		rotation = rotation + 90
	end

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

	self:SyncDriver()

	if orbit then
		self:StartMove(orbit)
	end
end

----------------------------------------- 驾驶员 -----------------------------------------
function MineCar:AddDriver(inst)
	if self.driver ~= nil or inst:HasTag("aip_minecar_driver") then
		return
	end

	self.inst.Physics:SetCollides(false)
	self.driver = inst
	self.driver:AddTag("aip_minecar_driver")

	-- 速度加成
	if self.driver.components.locomotor then
		self.driver.components.locomotor:SetExternalSpeedMultiplier(self.inst, "aipc_minecar_speed", 0)
	end

	-- 同步位置
	local dx, dy, dz = self.driver.Transform:GetWorldPosition()
	local tx, ty, tz = self.inst.Transform:GetWorldPosition()
	self.driver.Transform:SetPosition(tx, dy, tz)
end

-- TODO: Support multi driver later
function MineCar:RemoveDriver(inst)
	self.inst.Physics:SetCollides(true)
	self.driver:RemoveTag("aip_minecar_driver")

	-- 速度减成
	if self.driver.components.locomotor then
		self.driver.components.locomotor:RemoveExternalSpeedMultiplier(self.inst, "aipc_minecar_speed")
	end

	self.driver = nil
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

	local dsq = distsq(dx, dz, tx, tz)
	if dRotation ~= tRotation or dsq > MIN_READJUST_RANGE_Q then
		-- 停止移动
		if self.driver.components.locomotor then
			self.driver.components.locomotor:StopMoving()
		end

		-- 同步坐标
		self.driver.Transform:SetPosition(tx, dy, tz)

		-- 同步位移
		self.driver.Transform:SetRotation(self.inst.Transform:GetRotation())
		self.driver.Physics:SetMotorVel(carSpeed, 0, 0)
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
	local carSpeed = self:GetSpeed()
	local x, y, z = self.inst.Transform:GetWorldPosition()
	local ox, oy, oz = self.nextOrbit.Transform:GetWorldPosition()

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
	if self.driver ~= nil then
		data.driver = self.driver:GetSaveRecord() or nil
	end
	return data
end

function MineCar:OnLoad(data)
	if data and data.driver ~= nil then
		local driver = SpawnSaveRecord(data.driver)
		self:AddDriver(driver)
	end

	self.inst:DoTaskInTime(0, function()
		self:MoveToClosestOrbit()
	end)
end

return MineCar