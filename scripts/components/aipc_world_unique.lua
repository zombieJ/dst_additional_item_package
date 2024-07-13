local open_beta = aipGetModConfig("open_beta") == "open"

local dev_mode = aipGetModConfig("dev_mode") == "enabled"

-- 服务端：全局唯一 Prefab 控制器
-- TODO: 暂时还没用

local WorldUnique = Class(function(self, inst)
	self.inst = inst

	self.prefabs = {}

	-- 记录 憎恨之刃 击杀数
	self.aip_oldone_hand_kill = 0

	-- 初始化
	self:SetupEnv()
end)

------------------------------ 唯一 ------------------------------
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

-- 确保 prefab 存在，如果不存在则创建。这个功能只有在游戏开始时才能调用。
-- 否则性能消耗会比较大。
function WorldUnique:EnsurePrefab(prefabName, findFn)
	local tryFindPrefab = nil

	findFn = findFn or prefabName
	
	if type(findFn) == "function" then
		tryFindPrefab = findFn()
	elseif type(findFn) == "string" then
		tryFindPrefab = TheSim:FindFirstEntityWithTag(findFn)
	end

	local needCreate = tryFindPrefab == nil

	if needCreate then
		self.prefabs[prefabName] = SpawnPrefab(prefabName)
	else
		self.prefabs[prefabName] = tryFindPrefab
	end

	return self.prefabs[prefabName], needCreate
end

------------------------------ 生态 ------------------------------
function WorldUnique:SetupEnv()
	-- 创造 贪吃熊峰
	self.inst:DoTaskInTime(3, function()
		local junk_pile_big = TheSim:FindFirstEntityWithTag("junk_pile_big")

		if junk_pile_big then
			local torchStandMain, newCreate = self:EnsurePrefab("aip_torch_stand_main")

			-- 把 贪吃熊峰 挪到 垃圾堆 附近
			if newCreate then
				local junkPt = junk_pile_big:GetPosition()
				junkPt = aipGetSecretSpawnPoint(junkPt, 60, 100)
				torchStandMain.Transform:SetPosition(junkPt.x, junkPt.y, junkPt.z)
			end
		end
	end)
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