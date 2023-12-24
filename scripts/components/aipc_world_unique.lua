local open_beta = aipGetModConfig("open_beta") == "open"

local dev_mode = aipGetModConfig("dev_mode") == "enabled"

-- 服务端：全局唯一 Prefab 控制器
-- TODO: 暂时还没用

local WorldUnique = Class(function(self, inst)
	self.inst = inst

	self.prefabs = {}
end)

function WorldUnique:RegisterPrefab(item)
	self.prefabs[item.prefab] = item
end

-- 获取 prefab，如果不存在则返回 nil（并且清理数据）
function WorldUnique:GetPrefab(prefabName)
	local prefab = self.prefabs[prefabName]

	if prefab ~= nil and prefab:IsValid() then
		return prefab
	end

	self.prefabs[prefabName] = nil

	return nil
end

return WorldUnique

-- Divine Rapier