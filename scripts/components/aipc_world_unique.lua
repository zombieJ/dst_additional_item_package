local open_beta = aipGetModConfig("open_beta") == "open"

local dev_mode = aipGetModConfig("dev_mode") == "enabled"

-- 服务端：全局唯一 Prefab 控制器
-- TODO: 暂时还没用

local WorldUnique = Class(function(self, inst)
	self.inst = inst

	self.prefabs = {}

	-- 记录 憎恨之刃 击杀数
	self.aip_oldone_hand_kill = 0
end)

function WorldUnique:RegisterPrefab(item)
	self.prefabs[item.prefab] = item
end

------------------------------ 唯一 ------------------------------
-- 获取 prefab，如果不存在则返回 nil（并且清理数据）
function WorldUnique:GetPrefab(prefabName)
	local prefab = self.prefabs[prefabName]

	if prefab ~= nil and prefab:IsValid() then
		return prefab
	end

	self.prefabs[prefabName] = nil

	return nil
end

------------------------------ 道具 ------------------------------
-- 保存杀害数
function WorldUnique:OldoneKillCount(count)
	if count ~= nil then
		self.aip_oldone_hand_kill = count
	end
	return self.aip_oldone_hand_kill
end

------------------------------ 存取 ------------------------------
function WorldUnique:OnSave()
	return {
		aip_oldone_hand_kill = self.aip_oldone_hand_kill,
	}
end

function WorldUnique:OnLoad(data)
	if data ~= nil then
		self.aip_oldone_hand_kill = data.aip_oldone_hand_kill or 0
	end
end

------------------------------ 返回 ------------------------------
return WorldUnique