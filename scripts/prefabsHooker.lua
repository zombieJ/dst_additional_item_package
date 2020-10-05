local open_beta = GLOBAL.aipGetModConfig("open_beta")

------------------------------------ 贪婪观察者 ------------------------------------
-- 暗影跟随者
function ShadowFollowerPrefabPostInit(inst)
	if not GLOBAL.TheWorld.ismastersim then
		return
	end

	if not inst.components.shadow_follower then
		inst:AddComponent("shadow_follower")
	end
end

AddPrefabPostInit("dragonfly", function(inst) ShadowFollowerPrefabPostInit(inst) end) -- 龙蝇
AddPrefabPostInit("deerclops", function(inst) ShadowFollowerPrefabPostInit(inst) end) -- 鹿角怪
AddPrefabPostInit("bearger", function(inst) ShadowFollowerPrefabPostInit(inst) end) -- 熊獾
AddPrefabPostInit("moose", function(inst) ShadowFollowerPrefabPostInit(inst) end) -- 麋鹿鹅
AddPrefabPostInit("beequeen", function(inst) ShadowFollowerPrefabPostInit(inst) end) -- 蜂后
AddPrefabPostInit("klaus", function(inst) ShadowFollowerPrefabPostInit(inst) end) -- 克劳斯
AddPrefabPostInit("klaus_sack", function(inst) ShadowFollowerPrefabPostInit(inst) end) -- 克劳斯袋子
AddPrefabPostInit("antlion", function(inst) ShadowFollowerPrefabPostInit(inst) end) -- 蚁狮
AddPrefabPostInit("toadstool", function(inst) ShadowFollowerPrefabPostInit(inst) end) -- 蟾蜍王
AddPrefabPostInit("toadstool_dark", function(inst) ShadowFollowerPrefabPostInit(inst) end) -- 苦难蟾蜍王

-- ------------------------------------- 豆酱权杖 -------------------------------------
-- GLOBAL.LOCKTYPE.AIP_DOU_OPAL = "aip_dou_opal"

local birds = { "crow", "robin", "robin_winter", "canary", "quagmire_pigeon", "puffin" }
for i, name in ipairs(birds) do
	AddPrefabPostInit(name, function(inst)
		if open_beta ~= "open" then
			return nil
		end

		if inst.components.periodicspawner ~= nil then
			-- 因为我们占用了一点概率，因而稍微加快一点生成间隔
			inst.components.periodicspawner.randtime = inst.components.periodicspawner.randtime * 0.9

			local originPrefab = inst.components.periodicspawner.prefab

			-- 鸟儿掉落物如果是种子则有 10% 概率改成树叶笔记
			inst.components.periodicspawner.prefab = function(inst)
				local prefab = originPrefab
				if type(originPrefab) == "function" then
					prefab = originPrefab(inst)
				end

				if prefab == "seeds" and math.random() < .1 then
					return "aip_leaf_note"
				end

				return prefab
			end
		end
	end)
end

------------------------------------------ 活木 ------------------------------------------
AddPrefabPostInit("livinglog", function(inst)
	-- 添加燃料类型
	inst:AddTag("LIVINGLOG_fuel")
end)