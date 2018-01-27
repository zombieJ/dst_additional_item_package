local foldername = KnownModIndex:GetModActualName(TUNING.ZOMBIEJ_ADDTIONAL_PACKAGE)

local Empty = Class(function()
end)

-- 矿车关闭
local additional_orbit = GetModConfigData("additional_orbit", foldername)
if additional_orbit ~= "open" then
	return Empty
end

------------------------------------------------------------------------------------------
local function OnDriverChange(inst)
	local mineCarComponent = inst.components.aipc_minecar_client
	if not mineCarComponent then
		return
	end

	local prevDriver = mineCarComponent.driver
	local currentDriver = mineCarComponent:CurrentDriver()

	if prevDriver then
		prevDriver:RemoveTag("aip_minecar_driver")
	end
	if currentDriver then
		currentDriver:AddTag("aip_minecar_driver")
	end
	mineCarComponent.driver = currentDriver
end

local MineCar = Class(function(self, inst)
	self.inst = inst
	self.driver = nil
	self.net_driver_guid = net_uint(inst.GUID, "aipc_minecar.driver_guid", "driverChange")
	self.inst:ListenForEvent("driverChange", OnDriverChange)
end)

function MineCar:SetDriver(driver)
	-- 设置 驾驶员
	local GUID = driver and driver.GUID or 0
	self.net_driver_guid:set(GUID)
end

function MineCar:HasDriver(driver)
	if not driver then
		return false
	end

	local GUID = self.net_driver_guid:value()

	return driver.GUID == GUID
end

function MineCar:CurrentDriver()
	local GUID = self.net_driver_guid:value()

	if GUID == 0 then
		return nil
	else
		return c_inst(GUID)
	end
end

function MineCar:CanDrive()
	local GUID = self.net_driver_guid:value()

	return GUID == 0
end

return MineCar