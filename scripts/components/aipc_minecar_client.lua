local foldername = KnownModIndex:GetModActualName(TUNING.ZOMBIEJ_ADDTIONAL_PACKAGE)

local Empty = Class(function()
end)

-- 矿车关闭
local additional_orbit = GetModConfigData("additional_orbit", foldername)
if additional_orbit ~= "open" then
	return Empty
end

------------------------------------------------------------------------------------------

local MineCar = Class(function(self, inst)
	self.inst = inst
	self.net_driver_guid = net_uint(inst.GUID, "aipc_minecar.driver_guid")
end)

function MineCar:SetDriver(driver)
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

function MineCar:CanDrive()
	local GUID = self.net_driver_guid:value()

	return GUID == 0
end

return MineCar