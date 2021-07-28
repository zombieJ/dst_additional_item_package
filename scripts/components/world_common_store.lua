local dev_mode = aipGetModConfig("dev_mode") == "enabled"

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

	-- 后置世界计算
	self:PostWorld()
end)

function CommonStore:isShadowFollowing()
	return self.shadow_follower_count > 0
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

				-- if dev_mode then
				-- 	for i, player in pairs(AllPlayers) do
				-- 		player.Physics:Teleport(fissurePT.x, fissurePT.y, fissurePT.z)
				-- 	end
				-- end
			end
		end
	end)
end

return CommonStore


-- for i, v in ipairs(AllPlayers) do
--     OnPlayerJoined(self, v)
-- end

-- inst:ListenForEvent("ms_playerjoined", OnPlayerJoined, TheWorld)
-- inst:ListenForEvent("ms_playerleft", OnPlayerLeft, TheWorld)