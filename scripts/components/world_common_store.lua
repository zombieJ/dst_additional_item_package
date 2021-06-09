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
		local hasDouTotem = false

		for _, ent in pairs(Ents) do
			-- 检测图腾
			if ent:IsValid() and (
				ent.prefab == "aip_dou_totem_broken" or
				ent.prefab == "aip_dou_totem_powerless" or
				ent.prefab == "aip_dou_totem"
			) then
				hasDouTotem = true
			end
		end

		--------------------------- 创建图腾 ---------------------------
		if hasDouTotem == false then
			for i, node in ipairs(TheWorld.topology.nodes) do
				if table.contains(node.tags, "lunacyarea") then
					local x = node.cent[1]
					local z = node.cent[2]

					-- TheSim:FindEntities(x, 0, z, dist, { "player", "_health" }, NOTAGS)

					-- aipTypePrint(">>>>>", node)
					-- aipTypePrint("neighbours", node.neighbours)
					-- aipTypePrint("poly", node.poly)
					-- aipTypePrint("validedges", node.validedges)



					local ents = TheSim:FindEntities(x, 0, z, 40)
					local fissures = aipFilterTable(ents, function(inst)
						return inst.prefab == "moon_fissure"
					end)

					local first = fissures[1]
					if first ~= nil then
						local tx, ty, tz = first.Transform:GetWorldPosition()

						for i, player in pairs(AllPlayers) do
							player.Physics:Teleport(tx, ty, tz)
						end
						break
					end
				end
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