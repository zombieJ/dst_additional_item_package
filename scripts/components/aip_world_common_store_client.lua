local CommonStoreClient = Class(function(self, inst)
	self.inst = inst

	-- 添加飞行图腾的一些数据
	self.flyTotems = net_string(inst.GUID, "aipc_fly_totem", "aipc_fly_totem")
end)

----------------------------------- 飞行图腾 -----------------------------------
local split = "_AIP_FLY_TOTEM_"

function CommonStoreClient:UpdateTotems(totemNames)
	local strs = table.concat(totemNames, split)
	self.flyTotems:set(strs)
end

function CommonStoreClient:GetTotems()
	return aipSplit(self.flyTotems:value(), split)
end

return CommonStoreClient
