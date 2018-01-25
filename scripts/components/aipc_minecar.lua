local foldername = KnownModIndex:GetModActualName(TUNING.ZOMBIEJ_ADDTIONAL_PACKAGE)

local Empty = Class(function()
end)

-- 矿车关闭
local additional_orbit = GetModConfigData("additional_orbit", foldername)
if additional_orbit ~= "open" then
	return Empty
end

------------------------------------------------------------------------------------------
local REFRESH_INTERVAL = 0.5
local ENABLE_BIND = false

-- 绑定矿车位置
local function UpdateDrive(inst)
	if not ENABLE_BIND then
		return
	end

	local self = inst.components.aipc_minecar
	if self and self.driver then
		--[[if self.driver.components.locomotor then
			self.driver.components.locomotor:Stop()
		end]]

		local x, y, z = inst.Transform:GetWorldPosition()
		self.driver.Transform:SetPosition(x, 0, z)
	end
end

local MineCar = Class(function(self, inst)
	self.inst = inst
	self.driver = nil
	self.updatetask = nil
	self.speedMuli = 1
end)

function MineCar:AddDriver(inst)
	if self.driver ~= nil or inst:HasTag("aip_minecar_driver") then
		return
	end

	self.inst.Physics:SetCollides(false)
	self.driver = inst
	self.driver:AddTag("aip_minecar_driver")

	-- 速度加成
	if self.driver.components.locomotor then
		self.driver.components.locomotor:SetExternalSpeedMultiplier(self.inst, "aipc_minecar_speed", self.speedMuli)
	end

	self:StartDrive()
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
	self:StopDrive()
end

function MineCar:StartDrive()
	if self.updatetask ~= nil then
		self.updatetask:Cancel()
		self.updatetask = nil
	end

	self.updatetask = self.inst:DoPeriodicTask(REFRESH_INTERVAL, UpdateDrive)
	UpdateDrive(self.inst)
end

function MineCar:StopDrive()
	if self.updatetask ~= nil then
		self.updatetask:Cancel()
		self.updatetask = nil
	end
end

function MineCar:GoDirect(direct)
	if TheCamera == nil or not self.driver then
		return
	end

	local rotation = TheCamera:GetHeading() -- 指向屏幕左侧
	--print(">>> Go Dir:"..tostring(direct))
	print("-> Go Dir:"..tostring(rotation))

	rotation = -(rotation - 45) + 45

	if direct == "left" then
		rotation = rotation
	elseif direct == "down" then
		rotation = rotation - 90
	elseif direct == "right" then
		rotation = rotation + 180
	elseif direct == "up" then
		rotation = rotation + 90
	end

	local driverSpeed = self.driver.components.locomotor and self.driver.components.locomotor:GetRunSpeed() or 0
	local carSpeed = self.inst.components.locomotor and self.inst.components.locomotor:GetRunSpeed() or 0

	-- 同步玩家坐标
	UpdateDrive(self.inst)

	-- 移动矿车
	if self.inst.components.locomotor then
		self.inst.components.locomotor.runspeed = driverSpeed
		self.inst.components.locomotor:RunInDirection(rotation)
		self.inst.components.locomotor:RunForward()
		--speed = self.inst.components.locomotor:GetRunSpeed()
	end

	-- 移动驾驶员
	if self.driver ~= nil and self.driver.components.locomotor then
		--self.driver.Physics:SetActive(false)
		
		--self.driver.components.locomotor:RunInDirection(rotation)
		--self.driver.components.locomotor:RunForward()
		
		--[[self.driver.components.locomotor:RunInDirection(rotation)
		self.driver.components.locomotor:RunForward()

		self.driver.Physics:SetMotorVel(speed, 0, 0)
		self.driver.components.locomotor:StartUpdatingInternal()]]

		self.driver.Transform:SetRotation(rotation)
		self.driver.Physics:SetMotorVel(driverSpeed, 0, 0)
	end
end

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
end

return MineCar