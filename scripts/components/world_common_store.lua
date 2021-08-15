local dev_mode = aipGetModConfig("dev_mode") == "enabled"

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

-- 创建 饼干粉碎机
function CommonStore:CreateCoookieKing()
	-- 存在就跳过
	local ent = TheSim:FindFirstEntityWithTag("aip_cookiecutter_king")
	if ent ~= nil then
		return ent
	end

	if #self.fishShoals then
		local idx = math.random(#self.fishShoals)
		local fishShoal = self.fishShoals[idx]
		aipPrint("Pick King Pos:", #self.fishShoals, idx)

		local pt = FindSwimmableOffset(fishShoal:GetPosition(), math.random()*360, 20, nil, nil, nil, nil, false)
		return aipSpawnPrefab(nil, "aip_cookiecutter_king", pt.x, pt.y, pt.z)
	end

	local opt = FindNearbyOcean(Vector3(0,0,0))
	return aipSpawnPrefab(nil, "aip_cookiecutter_king", opt.x, opt.y, opt.z)
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

		-- if dev_mode then
		-- 	self:CreateCoookieKing()
		-- end
	end)
end

return CommonStore


-- for i, v in ipairs(AllPlayers) do
--     OnPlayerJoined(self, v)
-- end

-- inst:ListenForEvent("ms_playerjoined", OnPlayerJoined, TheWorld)
-- inst:ListenForEvent("ms_playerleft", OnPlayerLeft, TheWorld)