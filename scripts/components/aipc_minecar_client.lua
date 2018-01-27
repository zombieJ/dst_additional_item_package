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

	-- 同步 Tag
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
	self.net_driver_userid = net_string(inst.GUID, "aipc_minecar.driver_userid", "driverChange")
	self.inst:ListenForEvent("driverChange", OnDriverChange)
end)

------------------------------------------------------------------------------------------
function MineCar:SetDriver(driver)
	-- 设置 驾驶员
	local userid = driver and driver.userid or ""
	self.net_driver_userid:set(userid)
end

function MineCar:ClearDrivers()
	if self.driver then
		self.driver:RemoveTag("aip_minecar_driver")
	end
end

function MineCar:HasDriver(driver)
	if not driver then
		return false
	end

	local userid = self.net_driver_userid:value()

	return driver.userid == userid
end

function MineCar:CurrentDriver()
	local userid = self.net_driver_userid:value()

	if userid == "" or not userid then
		return nil
	end

	local driver = nil
	for i, player in pairs(AllPlayers) do
		if player.userid == userid then
			driver = player
		end
	end

	return driver
end

function MineCar:CanDrive()
	local userid = self.net_driver_userid:value()

	return userid == "" or not userid
end

MineCar.OnRemoveEntity = MineCar.ClearDrivers

return MineCar