local dev_mode = aipGetModConfig("dev_mode") == "enabled"

local function findFarAwayOcean(pos)
	local ocean_pos = nil
	local longestDist = -1

	for i = 1, 30 do
		local rndPos = aipFindRandomPointInOcean(20, 4)

		local dist = (rndPos ~= nil and pos ~= nil) and aipDist(rndPos, pos) or 0

		-- 尽量远
		if dist >= longestDist then
			longestDist = dist
			ocean_pos = rndPos
		end
	end

	-- 随便找一个附近的点
	if ocean_pos == nil then
		ocean_pos = FindNearbyOcean(Vector3(0,0,0))

	-- 删除附近的障碍物
	else
		local ents = aipFindNearEnts(
			ocean_pos,
			{"seastack", "messagebottle","driftwood_log"}, 
			dev_mode and 20 or 5
		)
		for i,ent in ipairs(ents) do
			if ent:IsValid() then
				ent:Remove()
			end
		end
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
	if ent ~= nil and pos == nil then
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
	if ent ~= nil and pos == nil then
		return ent
	end

	local ocean_pos = findFarAwayOcean(pos)

	if ocean_pos ~= nil then
		return aipSpawnPrefab(nil, "aip_suwu_mound", ocean_pos.x, ocean_pos.y, ocean_pos.z)
	end

	return nil
end

function CommonStore:PostWorld()
	-- 我们在世界启动后做操作以防止世界没有准备好

	--------------------------- 创建图腾 ---------------------------
	self.inst:DoTaskInTime(5, function()
		local dou_totem = aipFindEnt("aip_dou_totem_broken", "aip_dou_totem_powerless", "aip_dou_totem")

		if dou_totem == nil then
			local fissurePT = aipGetTopologyPoint("lunacyarea", "moon_fissure")
			if fissurePT then
				local tgt = aipGetSecretSpawnPoint(fissurePT, 0, 50, 5)
				aipSpawnPrefab(nil, "aip_dou_totem_broken", tgt.x, tgt.y, tgt.z)
			end
		end

		
	end)

	--------------------------- 创建饼干 ---------------------------
	self.inst:DoTaskInTime(10, function()
		self:CreateCoookieKing()
	end)

	--------------------------- 开发模式 ---------------------------
	if dev_mode then
		self.inst:DoTaskInTime(2, function()
			if ThePlayer then
				aipSpawnPrefab(ThePlayer, "aip_rubik")

				local px = 1000
				local py = 0
				local pz = 1000
				local tile = TheWorld.Map:GetTileAtPoint(px, py, pz)
				aipPrint("Tile Type:", tile)

				if tile == GROUND.INVALID then
					local tileX, tileY = TheWorld.Map:GetTileCoordsAtPoint(px, py, pz)
					TheWorld.Map:SetTile(tileX, tileY, GROUND.DIRT)
					TheWorld.Map:RebuildLayer(GROUND.DIRT, tileX, tileY)

					ThePlayer.Physics:Teleport(px, py, pz)
				end


				-- aipPrint("Next Tile Type:", TheWorld.Map:GetTileAtPoint(px, py, pz))

				-- for px = 0, 1000 do
				-- 	local py = 0
				-- 	local pz = 0
				-- 	local tile = TheWorld.Map:GetTileAtPoint(px, py, pz)
				-- 	aipPrint("Tile Type:", px, tile)
				-- end
			end
		end)

		-- self.inst:DoPeriodicTask(1, function()
		-- 	if ThePlayer then
		-- 		local x, y, z = ThePlayer.Transform:GetWorldPosition()
		-- 		local tile = TheWorld.Map:GetTileAtPoint(x,y,z)
		-- 		aipPrint("Player Tile Type:", tile)
		-- 	end
		-- end)
	end
end

return CommonStore


-- for i, v in ipairs(AllPlayers) do
--     OnPlayerJoined(self, v)
-- end

-- inst:ListenForEvent("ms_playerjoined", OnPlayerJoined, TheWorld)
-- inst:ListenForEvent("ms_playerleft", OnPlayerLeft, TheWorld)



-- 水中物品
-- 0: "boatfragment03"
-- 1: "boatfragment04"
-- 2: "boatfragment05"
-- 3: "bullkelp_plant"
-- 4: "bullkelp_plant_leaves"
-- 5: "crabking"
-- 6: "dark_observer_vest"
-- 7: "driftwood_log"
-- 8: "fireflies"
-- 9: "float_fx_back"
-- 10: "float_fx_front"
-- 11: "lightrays_canopy"
-- 12: "messagebottle"
-- 13: "moonglass_wobster_den"
-- 14: "oceanfish_shoalspawner"
-- 15: "oceantree"
-- 16: "oceantree_ripples_short"
-- 17: "oceantree_roots_short"
-- 18: "oceanvine"
-- 19: "oceanvine_cocoon"
-- 20: "oceanvine_deco"
-- 21: "saltstack"
-- 22: "seastack"
-- 23: "waterplant"
-- 24: "waterplant_base"
-- 25: "watertree_pillar"
-- 26: "watertree_pillar_ripples"
-- 27: "watertree_pillar_roots"
-- 28: "watertree_root"
