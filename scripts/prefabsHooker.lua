local _G = GLOBAL

-- 公测
local open_beta = _G.aipGetModConfig("open_beta") == "open"

-- 开发模式
local dev_mode = _G.aipGetModConfig("dev_mode") == "enabled"

-- 额外食物
local additional_food = _G.aipGetModConfig("additional_food") == "open"

-- 额外食物
local additional_chesspieces = _G.aipGetModConfig("additional_chesspieces") == "open"

------------------------------------ 贪婪观察者 ------------------------------------
-- 暗影跟随者
function ShadowFollowerPrefabPostInit(inst)
	if not _G.TheWorld.ismastersim then
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
AddPrefabPostInit("crabking", function(inst) ShadowFollowerPrefabPostInit(inst) end) -- 帝王蟹
AddPrefabPostInit("hermithouse", function(inst) ShadowFollowerPrefabPostInit(inst) end) -- 隐士之家
AddPrefabPostInit("malbatross", function(inst) ShadowFollowerPrefabPostInit(inst) end) -- 邪天翁

-- ------------------------------------- 豆酱权杖 -------------------------------------
local birds = { "crow", "robin", "robin_winter", "canary", "quagmire_pigeon", "puffin" }
if additional_chesspieces then
	for i, name in ipairs(birds) do
		AddPrefabPostInit(name, function(inst)
			-- 永不妥协 mod 会修改 randtime，兼容之。
			if inst.components.periodicspawner ~= nil and inst.components.periodicspawner.randtime ~= nil then
				-- 因为我们占用了一点概率，因而稍微加快一点生成间隔。
				inst.components.periodicspawner.randtime = inst.components.periodicspawner.randtime * 0.95

				local originPrefab = inst.components.periodicspawner.prefab

				-- 鸟儿掉落物如果是种子则有 2% 概率改成树叶笔记
				inst.components.periodicspawner.prefab = function(inst)
					local prefab = originPrefab
					if type(originPrefab) == "function" then
						prefab = originPrefab(inst)
					end

					if prefab == "seeds" and math.random() <= (dev_mode and 9 or .02) then
						return "aip_leaf_note"
					end

					return prefab
				end
			end
		end)
	end
end

----------------------------------------- 暗影怪 -----------------------------------------

function createFootPrint(inst)
	inst:ListenForEvent("death", function()
		-- 满足一定概率则生成脚印
		if math.random() <= (dev_mode and 1 or 0.33) then
			_G.aipSpawnPrefab(inst, "aip_dragon_footprint")
		end
	end)
end

AddPrefabPostInit("crawlinghorror", createFootPrint)
AddPrefabPostInit("terrorbeak", createFootPrint)
AddPrefabPostInit("crawlingnightmare", createFootPrint)
AddPrefabPostInit("nightmarebeak", createFootPrint)

------------------------------------------ 活木 ------------------------------------------
AddPrefabPostInit("livinglog", function(inst)
	-- 添加燃料类型
	inst:AddTag("LIVINGLOG_fuel")
end)

------------------------------------------ 金块 ------------------------------------------
local function canActOnGold(inst, doer, target)
	return target.prefab == "aip_xinyue_hoe"
end

local function onDoGoldTargetAction(inst, doer, target)
	-- 充满
	if target.components.fueled ~= nil then
		target.components.fueled:DoDelta(target.components.fueled.maxfuel, doer)

		if inst.components.stackable ~= nil then
			inst.components.stackable:Get():Remove()
		else
			inst:Remove()
		end
	end
end

AddPrefabPostInit("goldnugget", function(inst)
	-- 燃料注入
	inst:AddComponent("aipc_action_client")
	inst.components.aipc_action_client.canActOn = canActOnGold

	if not _G.TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("aipc_action")
	inst.components.aipc_action.onDoTargetAction = onDoGoldTargetAction
end)

------------------------------------------ 猪人 ------------------------------------------
AddPrefabPostInit("pigman", function(inst)
	-- 猪人会概率掉落西游人物卡
	if _G.TheWorld.ismastersim and inst.components.lootdropper ~= nil then
		inst.components.lootdropper:AddChanceLoot("aip_xiyou_card_pigsy", dev_mode and 1 or 0.01)
	end
end)

------------------------------------------ 兔人 ------------------------------------------
AddPrefabPostInit("bunnyman", function(inst)
	-- 兔人会概率掉落西游人物卡
	if _G.TheWorld.ismastersim and inst.components.lootdropper ~= nil then
		inst.components.lootdropper:AddChanceLoot("aip_xiyou_card_myth_yutu", dev_mode and 1 or 0.01)
	end
end)

------------------------------------------ 兔子 ------------------------------------------
AddPrefabPostInit("rabbit", function(inst)
	-- 兔子会极低概率掉落西游人物卡
	if _G.TheWorld.ismastersim and inst.components.lootdropper ~= nil then
		inst.components.lootdropper:AddChanceLoot("aip_xiyou_card_myth_yutu", dev_mode and 1 or 0.001)
	end
end)

------------------------------------------ 猴子 ------------------------------------------
AddPrefabPostInit("monkey", function(inst)
	-- 猴子会概率掉落西游人物卡
	if _G.TheWorld.ismastersim and inst.components.lootdropper ~= nil then
		inst.components.lootdropper:AddChanceLoot("aip_xiyou_card_monkey_king", dev_mode and 1 or 0.01)
	end
end)

------------------------------------------ 骨骸 ------------------------------------------
AddPrefabPostInit("stalker", function(inst)
	-- 骨骸会概率掉落西游人物卡
	if _G.TheWorld.ismastersim and inst.components.lootdropper ~= nil then
		inst.components.lootdropper:AddChanceLoot("aip_xiyou_card_white_bone", dev_mode and 1 or 0.1)
	end
end)

AddPrefabPostInit("skeleton", function(inst)
	-- 骨骸会概率掉落西游人物卡
	if _G.TheWorld.ismastersim and inst.components.lootdropper ~= nil then
		inst.components.lootdropper:AddChanceLoot("aip_xiyou_card_white_bone", dev_mode and 1 or 0.01)
	end
end)

AddPrefabPostInit("skeleton_player", function(inst)
	-- 骨骸会概率掉落西游人物卡
	if _G.TheWorld.ismastersim and inst.components.lootdropper ~= nil then
		inst.components.lootdropper:AddChanceLoot("aip_xiyou_card_white_bone", dev_mode and 1 or 0.01)
	end
end)

------------------------------------------ 牛牛 ------------------------------------------
AddPrefabPostInit("beefalo", function(inst)
	-- 概率性替换成螃蟹
	if _G.TheWorld.ismastersim and inst.components.periodicspawner ~= nil then
		local originOnSpawn = inst.components.periodicspawner.onspawn

		inst.components.periodicspawner.onspawn = function(inst, prefab, ...)
			prefab:DoTaskInTime(dev_mode and 2 or 60, function()
				local chance = dev_mode and 1 or 0.1
				if
					prefab:IsValid() and
					prefab.prefab == "poop" and
					math.random() <= chance and
					(
						prefab.components.inventoryitem == nil or
						prefab.components.inventoryitem:GetContainer() == nil
					) and
					#_G.aipFindNearEnts(prefab, { "aip_mud_crab" }, 20) <= 2
				then
					_G.ReplacePrefab(prefab, "aip_mud_crab")
				end
			end)

			if originOnSpawn ~= nil then
				return originOnSpawn(inst, prefab, _G.unpack(arg))
			end
		end
	end
end)

----------------------------------------- 漂流瓶 -----------------------------------------
AddPrefabPostInit("messagebottle", function(inst)
	if additional_food and _G.TheWorld.ismastersim and inst.components.mapspotrevealer ~= nil then
		local originPrereveal = inst.components.mapspotrevealer.prerevealfn

		inst.components.mapspotrevealer.prerevealfn = function(inst, doer, ...)
			local chance = dev_mode and 1 or 0.1
			if math.random() <= chance then
				local blueprint = _G.aipSpawnPrefab(inst, "aip_olden_tea_blueprint")
				local bottle = _G.aipSpawnPrefab(inst, "messagebottleempty")

				-- 尝试给予
				local container = inst.components.inventoryitem:GetContainer()
				inst:Remove()

				if container ~= nil then
					container:GiveItem(bottle)
					container:GiveItem(blueprint)
				end

				return false
			end

			return originPrereveal(inst, doer, _G.unpack(arg))
		end
	end
end)

------------------------------------------ 食物 ------------------------------------------
AddPrefabPostInit("grass", function(inst)
	if not _G.TheWorld.ismastersim then
		return inst
	end

	-- 开启食物时就可以动态草变小麦
	if additional_food then
		if inst.components.pickable ~= nil then
			local oriPickedFn = inst.components.pickable.onpickedfn

			inst.components.pickable.onpickedfn = function(inst, picker, ...)
				oriPickedFn(inst, picker, ...)

				local PROBABILITY = dev_mode and 1 or 0.01

				-- 满足一定概率则生成一个小麦
				if math.random() <= PROBABILITY then
					local wheat = _G.aipReplacePrefab(inst, "aip_wheat")
					wheat.components.pickable:MakeEmpty()
				end
			end
		end
	end
end)


if additional_food and (_G.TheNet:GetIsServer() or _G.TheNet:IsDedicated()) then
	AddPrefabPostInit("world", function (inst)
		inst:WatchWorldState("season", function ()
			for i, player in ipairs(_G.AllPlayers) do
				if not player:HasTag("playerghost") and player.entity:IsVisible() then
					local pos = _G.aipGetSpawnPoint(player:GetPosition())
					if pos ~= nil then
						local sunflower = _G.SpawnPrefab("aip_sunflower")
						sunflower.Transform:SetPosition(pos.x, pos.y, pos.z)
						break
					end
				end
			end
		end)
	end)
end

-- 给蔬菜赋值
local VEGGIES = _G.require('prefabs/aip_veggies_list')

for name, data in pairs(VEGGIES) do
	env.AddIngredientValues({"aip_veggie_"..name}, data.tags or {}, data.cancook or false, data.candry or false)
end