local dev_mode = aipGetModConfig("dev_mode") == "enabled"

local function findFarAwayOcean(pos)
	aipPrint("最优解!!!") -- 445, 546
	local ocean_pos = nil
	local longestDist = -1

	-- 随机一个附近没有物体的海洋点（20 范围内没有陆地， 10 范围内没物体）
	for i = 1, 50 do
		local rndPos = aipFindRandomPointInOcean(50)
		local dist = (rndPos ~= nil and pos ~= nil) and aipDist(rndPos, pos) or 0

		-- 尽量远
		if dist >= longestDist and aipValidateOceanPoint(rndPos, 10, 4) then
			longestDist = dist
			ocean_pos = rndPos
		end
	end
	aipTypePrint(ocean_pos)

	-- 随机一个附近没有物体的海洋点（5 范围内没有陆地、物体）
	if ocean_pos == nil then
		aipPrint("次优解!!!")

		for i = 1, 50 do
			local rndPos = aipFindRandomPointInOcean(100)
			local dist = (rndPos ~= nil and pos ~= nil) and aipDist(rndPos, pos) or 0

			-- 尽量远
			if dist > longestDist and aipValidateOceanPoint(rndPos, 2) then
				longestDist = dist
				ocean_pos = rndPos
			end
		end
		aipTypePrint(ocean_pos)
	end

	-- 如果没有找到适合的点，降级就找远一点的点
	if ocean_pos == nil then
		aipPrint("最坏解!!!")
		longestDist = -1

		for i = 1, 10 do
			local rndPos = aipFindRandomPointInOcean(100)
			local dist = (rndPos ~= nil and pos ~= nil) and aipDist(rndPos, pos) or 0
	
			-- 尽量远
			if dist >= longestDist then
				longestDist = dist
				ocean_pos = rndPos
			end
		end
		aipTypePrint(ocean_pos)
	end

	-- 随便找一个附近的点
	if ocean_pos == nil then
		ocean_pos = FindNearbyOcean(Vector3(0,0,0))
		aipPrint("兜底解!!!")
		aipTypePrint(ocean_pos)
	end

	return ocean_pos
end

local function onFishShoalAdded(inst)
	if TheWorld.components.world_common_store ~= nil then
		table.insert(
			TheWorld.components.world_common_store.fishShoals,
			inst
		)
	end
end

local CommonStore = Class(function(self, inst)
	self.inst = inst
	self.shadow_follower_count = 0

	-- 当前管理物品的箱子
	self.chestOpened = false
	-- 记录目前哪个箱子被打开了
	self.holderChest = nil
	-- 记录所有的箱子
	self.chests = {}

	-- 记录所有的飞行点
	self.flyTotems = {}

	-- 记录所有的鱼点
	self.fishShoals = {}

	-- 后置世界计算
	self:PostWorld()

	self.inst:ListenForEvent("ms_registerfishshoal", onFishShoalAdded)
end)

function CommonStore:isShadowFollowing()
	return self.shadow_follower_count > 0
end

-- 创建 饼干粉碎机: 如果给了坐标，就找一个尽量远的坐标
function CommonStore:CreateCoookieKing(pos)
	-- 存在且没有坐标就跳过
	local ent = TheSim:FindFirstEntityWithTag("aip_cookiecutter_king")
	if ent ~= nil and pos == nil and not dev_mode then
		return ent
	end

	local ocean_pos = findFarAwayOcean(pos)

	if ocean_pos ~= nil then
		return aipSpawnPrefab(nil, "aip_cookiecutter_king", ocean_pos.x, ocean_pos.y, ocean_pos.z)
	end

	return nil
end

function CommonStore:CreateSuWuMound(pos)
	-- 存在且没有坐标就跳过
	local ent = TheSim:FindFirstEntityWithTag("aip_suwu_mound")
	if ent ~= nil and pos == nil and not dev_mode then
		return ent
	end

	local ocean_pos = findFarAwayOcean(pos)

	if ocean_pos ~= nil then
		return aipSpawnPrefab(nil, "aip_suwu_mound", ocean_pos.x, ocean_pos.y, ocean_pos.z)
	end

	return nil
end

function CommonStore:PostWorld()
	-- 我们在世界启动后 5 做操作以防止世界没有准备好
	self.inst:DoTaskInTime(5, function()
		local dou_totem = aipFindEnt("aip_dou_totem_broken", "aip_dou_totem_powerless", "aip_dou_totem")

		--------------------------- 创建图腾 ---------------------------
		if dou_totem == nil then
			local fissurePT = aipGetTopologyPoint("lunacyarea", "moon_fissure")
			if fissurePT then
				local tgt = aipGetSecretSpawnPoint(fissurePT, 0, 50, 5)
				aipSpawnPrefab(nil, "aip_dou_totem_broken", tgt.x, tgt.y, tgt.z)
			end
		end

		if dev_mode then
			self:CreateCoookieKing()
		end
	end)
end

return CommonStore


-- for i, v in ipairs(AllPlayers) do
--     OnPlayerJoined(self, v)
-- end

-- inst:ListenForEvent("ms_playerjoined", OnPlayerJoined, TheWorld)
-- inst:ListenForEvent("ms_playerleft", OnPlayerLeft, TheWorld)