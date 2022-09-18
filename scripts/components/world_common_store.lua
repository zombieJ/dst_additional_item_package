local open_beta = aipGetModConfig("open_beta") == "open"

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

-- 世界打雷
local function OnSendLightningStrike(inst, pos)
	local pt = aipGetSpawnPoint(pos, 10)
	if pt ~= nil then
		aipSpawnPrefab(inst, "aip_particles", pt.x, pt.y, pt.z)
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

	-- 当前的豆酱图腾
	self.douTotem = nil

	-- 记录所有的飞行点
	self.flyTotems = {}

	-- 记录所有的鱼点
	self.fishShoals = {}

	-- 是否赐予过 《额外物品包》这本书
	self.storyBook = false

	-- 粒子加载管理器
	self.particles = {}

	-- 后置世界计算
	self:PostWorld()

	self.inst:ListenForEvent("ms_registerfishshoal", onFishShoalAdded)

	-- 笑脸 BOSS 出现时间（小于等于 0 说明可以召唤，每天都会减少一次计时）
	self.smileLeftDays = 0
	inst:WatchWorldState("isnight", function(_, isnight)
		if isnight then
			self.smileLeftDays = math.min(self.smileLeftDays - 1)
		end
	end)

	inst:ListenForEvent("ms_sendlightningstrike", OnSendLightningStrike, TheWorld)
end)

function CommonStore:OnSave()
    return {
        storyBook = self.storyBook,
    }
end

function CommonStore:OnLoad(data)
	if data ~= nil then
		self.storyBook = data.storyBook
	end
end

function CommonStore:isShadowFollowing()
	return self.shadow_follower_count > 0
end

-- 创建 饼干粉碎机: 如果给了坐标，就找一个尽量远的坐标
function CommonStore:CreateCoookieKing(pos)
	-- 只有地面可以有
	if not TheWorld:HasTag("forest") then
		return
	end

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

-- 获取一下豆酱图腾
function CommonStore:FindDouTotem()
	if not self.douTotem then
		self.douTotem = TheSim:FindFirstEntityWithTag("aip_dou_totem_final")
	end
	return self.douTotem
end

-- 创建 魔方，在墓地附近寻找
function CommonStore:CreateRubik()
	-- 只有地面可以有
	if not TheWorld:HasTag("forest") then
		return
	end

	-- 存在且没有坐标就跳过
	local ent = TheSim:FindFirstEntityWithTag("aip_rubik")
	if ent ~= nil then
		return ent
	end

	-- 寻找一个墓地
	local grave = TheSim:FindFirstEntityWithTag("grave")
	local pos = nil
	if grave ~= nil then
		pos = grave:GetPosition()
	end

	if not pos then
		pos = aipGetSecretSpawnPoint(Vector3(0, 0, 0), 0, 1000)
	end

	pos = aipGetSecretSpawnPoint(pos, 0, 50, 5)

	if pos == nil then
		return nil
	end

	local rubik = aipSpawnPrefab(nil, "aip_rubik", pos.x, pos.y, pos.z)
	rubik.components.fueled:MakeEmpty()

	return rubik
end

-- 创建 古神蛛巢，随机找一个触手怪
function CommonStore:CreateSpiderden()
	-- 只有地面可以有
	if not TheWorld:HasTag("forest") then
		return
	end

	-- 存在且没有坐标就跳过
	local ent = TheSim:FindFirstEntityWithTag("aip_oldone_spiderden")
	if ent ~= nil then
		return ent
	end

	-- 寻找一个触手
	local tentacle = aipFindRandomEnt("tentacle")
	local pos = nil
	if tentacle ~= nil then
		pos = tentacle:GetPosition()
	end

	if not pos then
		pos = aipGetSecretSpawnPoint(Vector3(0, 0, 0), 0, 1000)
	end

	pos = aipGetSecretSpawnPoint(pos, 0, 50, 5)

	if pos == nil then
		return nil
	end

	local spiderden = aipSpawnPrefab(nil, "aip_oldone_spiderden", pos.x, pos.y, pos.z)

	return spiderden
end

-- 创建 雕像，随机找一个触手怪
function CommonStore:CreateMarble()
	-- 只有地面可以有
	if not TheWorld:HasTag("forest") then
		return
	end

	-- 存在且没有坐标就跳过
	local marble = TheSim:FindFirstEntityWithTag("aip_oldone_marble")
	if marble ~= nil then
		return marble
	end

	-- 如果没有雕像则在沼泽创造
	if marble == nil then
		for i = 1, 10 do
			local reeds = aipFindRandomEnt("reeds")

			if reeds ~= nil then
				local rx, ry, rz = reeds.Transform:GetWorldPosition()

				if TheWorld.Map:GetTileAtPoint(rx, ry, rz) == GROUND.MARSH then
					local tgtPT = aipGetSecretSpawnPoint(reeds:GetPosition(), 1, 10, 5)
					if tgtPT ~= nil then
						marble = aipSpawnPrefab(nil, "aip_oldone_marble", tgtPT.x, tgtPT.y, tgtPT.z)
						break
					end
				end
			end
		end
	end

	return marble
end


-- 创建 漆黑的鹿
function CommonStore:CreateDeer()
	-- 只有洞穴可以有
	if not TheWorld:HasTag("cave") then
		return
	end

	-- 有鹿就不去
	if TheSim:FindFirstEntityWithTag("aip_oldone_deer") ~= nil then
		return
	end

	local rocky = TheSim:FindFirstEntityWithTag("rocky")
	if rocky == nil then
		return
	end

	-- 石虾附近搞一个
	local tgtPT = aipGetSecretSpawnPoint(rocky:GetPosition(), 5, 20, 5)
	if tgtPT ~= nil then
		aipSpawnPrefab(nil, "aip_oldone_deer", tgtPT.x, tgtPT.y, tgtPT.z)
	end
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

	--------------------------- 创建书本 ---------------------------
	self.inst:DoTaskInTime(1, function()
		if self.storyBook ~= true and TheWorld:HasTag("forest") then
			local portal = TheSim:FindFirstEntityWithTag("multiplayer_portal")

			if portal ~= nil then
				aipSpawnPrefab(portal, "aip_storybook")
				self.storyBook = true
			end
		end
	end)

	--------------------------- 创建图腾 ---------------------------
	self.inst:DoTaskInTime(5, function()
		local dou_totem = aipFindEnt(
			"aip_dou_totem_broken",
			"aip_dou_totem_powerless",
			"aip_dou_totem",
			"aip_dou_totem_cave" -- 洞穴里的图腾只有充能的能力
		)

		if dou_totem == nil then
			-- 寻找月岛地皮生成
			local fissurePT = aipGetTopologyPoint("lunacyarea", "moon_fissure")
			if fissurePT then
				local tgt = aipGetSecretSpawnPoint(fissurePT, 0, 50, 5)
				if tgt ~= nil then
					aipSpawnPrefab(nil, "aip_dou_totem_broken", tgt.x, tgt.y, tgt.z)
				else
					aipPrint("月岛图腾创建失败！")
				end

			else
				-- 寻找暗影灯座
				local targetPrefab = aipFindRandomEnt("rabbithouse")
				if targetPrefab ~= nil then
					local tgt = aipGetSecretSpawnPoint(targetPrefab:GetPosition(), 0, 50, 5)
					if tgt ~= nil then
						aipSpawnPrefab(nil, "aip_dou_totem_broken", tgt.x, tgt.y, tgt.z)
					else
						aipPrint("洞穴图腾创建失败！")
					end
				else
					aipPrint("兜底图腾创建失败！")
				end
			end
		end
	end)

	--------------------------- 创建饼干 ---------------------------
	self.inst:DoTaskInTime(10, function()
		self:CreateCoookieKing()
	end)

	--------------------------- 创建魔方 ---------------------------
	self.inst:DoTaskInTime(5, function()
		self:CreateRubik()
	end)

	------------------------- 创建古神蛛巢 -------------------------
	self.inst:DoTaskInTime(7, function()
		self:CreateSpiderden()
	end)

	------------------------- 创建沼泽雕塑 -------------------------
	self.inst:DoTaskInTime(3, function()
		self:CreateMarble()
	end)

	------------------------- 创建漆黑的鹿 -------------------------
	self.inst:DoTaskInTime(1, function()
		self:CreateDeer()
	end)

	--------------------------- 开发模式 ---------------------------

	if dev_mode then
		self.inst:DoTaskInTime(5, function()
		-- 	TheWorld:PushEvent("phasechanged", "night")
		-- 	TheWorld:PushEvent("ms_setmoonphase", {moonphase = "full"})
		-- aipPrint("do state!!!")
		-- ThePlayer.sg:GoToState("aip_drive")
		end)

		-- self.inst:DoPeriodicTask(2, function()
		-- 	local x, y, z = ThePlayer.Transform:GetWorldPosition()
		-- 	local tile = TheWorld.Map:GetTileAtPoint(x, y, z)
		-- 	aipPrint("Tile:", isNaturalPoint(Vector3(x, y, z)), tile)
		-- end)
	end
	-- if dev_mode then
	-- 	self.inst:DoTaskInTime(2, function()
	-- 		if ThePlayer and false then
	-- 			aipSpawnPrefab(ThePlayer, "aip_rubik")

	-- 			-- 避免和神话书说&小房子冲突
	-- 			local px = 1900
	-- 			local py = 0
	-- 			local pz = 1900

	-- 			ThePlayer.Physics:Teleport(px, py, pz)

	-- 			-- local tile = TheWorld.Map:GetTileAtPoint(px, py, pz)
	-- 			-- aipPrint("Tile Type:", tile)

	-- 			-- if tile == GROUND.INVALID then
	-- 			-- 	local tileX, tileY = TheWorld.Map:GetTileCoordsAtPoint(px, py, pz)
	-- 			-- 	TheWorld.Map:SetTile(tileX, tileY, GROUND.DIRT)
	-- 			-- 	TheWorld.Map:RebuildLayer(GROUND.DIRT, tileX, tileY)

	-- 			-- 	ThePlayer.Physics:Teleport(px, py, pz)
	-- 			-- end


	-- 			-- aipPrint("Next Tile Type:", TheWorld.Map:GetTileAtPoint(px, py, pz))

	-- 			-- for px = 0, 1000 do
	-- 			-- 	local py = 0
	-- 			-- 	local pz = 0
	-- 			-- 	local tile = TheWorld.Map:GetTileAtPoint(px, py, pz)
	-- 			-- 	aipPrint("Tile Type:", px, tile)
	-- 			-- end
	-- 		end
	-- 	end)

	-- 	-- self.inst:DoPeriodicTask(1, function()
	-- 	-- 	if ThePlayer then
	-- 	-- 		local x, y, z = ThePlayer.Transform:GetWorldPosition()
	-- 	-- 		local tile = TheWorld.Map:GetTileAtPoint(x,y,z)
	-- 	-- 		aipPrint("Player Tile Type:", tile)
	-- 	-- 	end
	-- 	-- end)
	-- end
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
