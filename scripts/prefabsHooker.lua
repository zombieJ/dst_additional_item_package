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

---------------------------------------- 树精卫士 ----------------------------------------
-- 掉落树叶笔记
function dropLeafNote(inst)
	if _G.TheWorld.ismastersim and inst.components.lootdropper ~= nil and additional_chesspieces then
		inst.components.lootdropper:AddChanceLoot("aip_leaf_note", dev_mode and 1 or 0.1)
	end
end

AddPrefabPostInit("leif", dropLeafNote)
AddPrefabPostInit("leif_sparse", dropLeafNote)

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
local function canActOnLiving(inst, doer, target)
	return target.prefab == "aip_joker_face"
end

local function onDoLivingTargetAction(inst, doer, target)
	-- 填充燃料
	if target.components.fueled ~= nil then
		target.components.fueled:DoDelta(target.components.fueled.maxfuel / 5, doer)

		_G.aipRemove(inst)
	end
end

AddPrefabPostInit("livinglog", function(inst)
	-- 燃料注入
	inst:AddComponent("aipc_action_client")
	inst.components.aipc_action_client.canActOn = canActOnLiving

	if not _G.TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("aipc_action")
	inst.components.aipc_action.onDoTargetAction = onDoLivingTargetAction
end)

------------------------------------------ 金块 ------------------------------------------
local function canActOnGold(inst, doer, target)
	return target.prefab == "aip_xinyue_hoe"
end

local function onDoGoldTargetAction(inst, doer, target)
	-- 充满
	if target.components.fueled ~= nil then
		target.components.fueled:DoDelta(target.components.fueled.maxfuel, doer)

		_G.aipRemove(inst)
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

---------------------------------------- 月亮玻璃 ----------------------------------------
AddPrefabPostInit("moonglass", function(inst)
	-- 燃料注入
	inst:AddComponent("aipc_fuel")
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

------------------------------------------ 幽灵 ------------------------------------------
AddPrefabPostInit("ghost", function(inst)
	-- 幽灵会概率掉落西游人物卡
	if _G.TheWorld.ismastersim then
		if inst.components.lootdropper == nil then
			inst:AddComponent("lootdropper")
		end

		inst.components.lootdropper:AddChanceLoot("aip_xiyou_card_yama_commissioners", dev_mode and 1 or 0.1)
	end
end)

------------------------------------------ 鱼人 ------------------------------------------
AddPrefabPostInit("merm", function(inst)
	-- 鱼人会极低概率掉 22 磅重的鲶鱼
	if _G.TheWorld.ismastersim and inst.components.lootdropper ~= nil then
		inst.components.lootdropper:AddChanceLoot("aip_22_fish", dev_mode and 1 or 0.001)
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
	-- 不开启食物就不能赠送了
	if additional_food and _G.TheWorld.ismastersim and inst.components.mapspotrevealer ~= nil then
		local originPrereveal = inst.components.mapspotrevealer.prerevealfn

		inst.components.mapspotrevealer.prerevealfn = function(inst, doer, ...)
			local chance = dev_mode and 1 or 0.05

			-- 如果玩家不会，我们就概率送蓝图
			if
				doer ~= nil and
				doer.components.builder ~= nil and
				not doer.components.builder:KnowsRecipe("aip_olden_tea") and
				math.random() <= chance
			then
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

---------------------------------------- 魔法扫把 ----------------------------------------
AddPrefabPostInit("reskin_tool", function(inst)
	if inst.components.spellcaster ~= nil then
		local originCanCast = inst.components.spellcaster.can_cast_fn
		local originSpell = inst.components.spellcaster.spell

		-- 注入对小麦的改造
		if originCanCast and originSpell then
			inst.components.spellcaster:SetCanCastFn(function(doer, target, pos, ...)
				if target.prefab == "aip_wheat" then
					return true
				end
				return originCanCast(doer, target, pos, ...)
			end)

			inst.components.spellcaster:SetSpellFn(function(tool, target, pos, ...)
				if target and target.prefab == "aip_wheat" then
					_G.aipSpawnPrefab(target, "explode_reskin")
					_G.aipReplacePrefab(target, "grass")
					return
				end
				return originSpell(tool, target, pos, ...)
			end)
		end
	end
end)

------------------------------------------ 燧石 ------------------------------------------
AddPrefabPostInit("flint", function(inst)
	inst:AddTag("allow_action_on_impassable") -- 允许对海使用

	if inst.components.aipc_water_drift == nil then
		inst:AddComponent("aipc_water_drift")
	end
end)

------------------------------------------ 乌贼 ------------------------------------------
local function onSquidDead(inst)
	local chance = _G.aipBufferExist(inst, "oldonePoison") and 1 or 0.1

	if math.random() <= chance then
		_G.aipFlingItem(
			_G.aipSpawnPrefab(inst, "aip_oldone_fisher")
		)
	end
end

AddPrefabPostInit("squid", function(inst)
	inst:ListenForEvent("death", onSquidDead)
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

		-- 万圣节药剂也可以变化
		if inst.components.halloweenmoonmutable == nil then
			inst:AddComponent("halloweenmoonmutable")
			inst.components.halloweenmoonmutable:SetPrefabMutated("aip_wheat")
		end
	end
end)

local function spawnNearBy(inst, prefabName, dist, maxCount)
	dist = dist or 40
	maxCount = maxCount or 999

	local pos = _G.aipGetSecretSpawnPoint(inst:GetPosition(), dist, dist + 5, 5)
	if pos ~= nil then
		local prefab = _G.SpawnPrefab(prefabName)
		prefab.Transform:SetPosition(pos.x, pos.y, pos.z)

		-- 超过最大数我们就不创建了
		local ents = _G.aipFindNearEnts(prefab, { prefabName }, 20)
		if #ents > maxCount then
			prefab:Remove()
			return false
		else
			return true
		end

		-- 如果有建筑物就不创建
		local buildings = TheSim:FindEntities(
			pos.x, pos.y, pos.z,
			12, nil, nil, { "structure", "wall" }
		)
		if #buildings > 0 then
			prefab:Remove()
			return false
		end
	end

	return false
end

local function spawnNearPlayer(prefabName, dist, maxCount)
	for i, player in ipairs(_G.AllPlayers) do
		if not player:HasTag("playerghost") and player.entity:IsVisible() then
			spawnNearBy(player, prefabName, dist, maxCount)
		end
	end
end


if _G.TheNet:GetIsServer() or _G.TheNet:IsDedicated() then
	AddPrefabPostInit("world", function (inst)
		if additional_food then
			-- 季节变换时，生成向日葵
			inst:WatchWorldState("season", function ()
				spawnNearPlayer("aip_sunflower")
			end)
		end

		inst:WatchWorldState("isnight", function(_, isnight)
			if isnight then
				-- 每天都有一定概率给玩家附近生成一个 怪异的球茎（最多 3 个）
				inst:DoTaskInTime(1, function() -- 延迟生效以防卡顿
					local chance = dev_mode and 1 or 0.2

					if math.random() < chance then
						local spawnPoint = _G.aipFindRandomEnt("spawnpoint_multiplayer", "spawnpoint_master")
						spawnNearBy(spawnPoint, "aip_oldone_plant", 120, 3)
					end
				end)

				-- 每天都有一定概率在地图随机位置创建一次鲜花迷宫，如果已经有了就不再创建
				inst:DoTaskInTime(0.5, function()
					local chance = dev_mode and 1 or 0.3

					if math.random() < chance then
						local ent = TheSim:FindFirstEntityWithTag("aip_olden_flower")
						if ent == nil then
							local pt = _G.aipFindRandomPointInLand(5)

							-- 如果可以创造鲜花，则创建
							if pt ~= nil then
								local rnd = math.random()

								local flowers = {
									"aip_four_flower",			-- 鲜花迷宫
									"aip_watering_flower",		-- 枯萎鲜花
									"aip_oldone_rock",			-- 石头谜团
									"aip_oldone_salt_hole",		-- 小型盐洞
									"aip_oldone_lotus",			-- 荷花水漂
									"aip_oldone_pot",			-- 闹鬼陶罐
									"aip_oldone_tree",			-- 旺盛之树
									"aip_oldone_once",			-- 瞬息宇宙
									"aip_oldone_black",			-- 幕后黑手
									"aip_oldone_jellyfish",		-- 搁浅水母
								}

								-- 春天还有额外的几率出现春日谜团
								if _G.TheWorld.state.isspring then
									if dev_mode then -- 测试环境一定是特定谜团
										flowers = {}
									end

									table.insert(flowers, "aip_oldone_plant_flower")
								end

								-- 夏天还有额外的几率出现化缘谜团
								if _G.TheWorld.state.issummer then
									if dev_mode then -- 测试环境一定是特定谜团
										flowers = {}
									end

									table.insert(flowers, "aip_oldone_hot")
								end

								-- 秋天还有额外的几率出现枯叶谜团
								if _G.TheWorld.state.isautumn then
									if dev_mode then -- 测试环境一定是特定谜团
										flowers = {}
									end

									table.insert(flowers, "aip_oldone_leaves")
								end

								-- 冬天还有额外的几率出现雪人谜团
								if _G.TheWorld.state.iswinter then
									if dev_mode then -- 测试环境一定是特定谜团
										flowers = {}
									end

									table.insert(flowers, "aip_oldone_snowman")
								end

								-- 测试专用
								if dev_mode then -- aip_oldone_tree
									flowers = { "aip_oldone_jellyfish" }
								end

								local flowerName = _G.aipRandomEnt(flowers)
								local flower = _G.aipSpawnPrefab(nil, flowerName, pt.x, pt.y, pt.z)
								
								if dev_mode then
									_G.aipPrint("Create Puzzle:", flowerName)
								end

								flower:AddComponent("perishable")
								flower.components.perishable:StartPerishing()
								flower.components.perishable:SetPerishTime(TUNING.PERISH_MED)
								flower.components.perishable.onperishreplacement = "seeds"
							end
						end
					end
				end)
			end
		end)

		-- 每个季节变换都会在 猪王 附近重置一条 袜子蛇
		inst:WatchWorldState("season", function ()
			inst:DoTaskInTime(1.5, function() -- 延迟生效以防卡顿
				local pigking = _G.aipFindEnt("pigking")
				if pigking then
					local pos = pigking:GetPosition()
					local ents = TheSim:FindEntities(pos.x, pos.y, pos.z, 100, { "aip_oldone_thestral" })

					if #ents == 0 then
						_G.aipSpawnPrefab(pigking, "aip_oldone_thestral")
					end
				end
			end)
		end)
	end)
end

local cookbookAtlas = {
	"aip_oldone_plant_broken",
	"aip_oldone_deer_eye_fruit",
}

-- 给蔬菜赋值
local VEGGIES = _G.require('prefabs/aip_veggies_list')

for name, data in pairs(VEGGIES) do
	local fullname = "aip_veggie_"..name
	table.insert(cookbookAtlas, fullname)
	env.AddIngredientValues({fullname}, data.tags or {}, data.cancook or false, data.candry or false)
end

-- 粘衣赋值
env.AddIngredientValues(
	{"aip_oldone_plant_broken"},
	{ indescribable = 2 }, -- tags
	false, -- cancook
	false -- candry
)

env.RegisterInventoryItemAtlas("images/inventoryimages/aip_oldone_plant_broken.xml", "aip_oldone_plant_broken.tex")

-- 菇茑赋值
env.AddIngredientValues(
	{"aip_oldone_deer_eye_fruit"},
	{ indescribable = 1, fruit = .5 } -- 是 迷因 也是 水果
)

-- 遍历添加食谱图标
for _, atlas in ipairs(cookbookAtlas) do
	env.RegisterInventoryItemAtlas(
		"images/inventoryimages/"..atlas..".xml",
		atlas..".tex"
	)
end
