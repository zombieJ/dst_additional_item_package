local foldername = KnownModIndex:GetModActualName(TUNING.ZOMBIEJ_ADDTIONAL_PACKAGE)

-- 配置
local additional_dress = GetModConfigData("additional_dress", foldername)
if additional_dress ~= "open" then
	return nil
end

local prefabList = {}

-- TODO: Add aip_dress template lua for template dress generation
local dresses = {
	aip_horse_head = {},
	aip_som = {},
}

for name,data in pairs(dresses) do
	local prefab = require("prefabs/"..name)
	table.insert(prefabList, prefab)
end

return unpack(prefabList)