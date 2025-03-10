-- 配置
local additional_food = aipGetModConfig("additional_food")
if additional_food ~= "open" then
	return nil
end

local food_effect = aipGetModConfig("food_effect")
local language = aipGetModConfig("language")
local dev_mode = aipGetModConfig("dev_mode") == "enabled"

-- 默认参数
local EFFECT_MAP = {
	["shortage"] = 0.2,
	["less"] = 0.6,
	["normal"] = 1,
	["large"] = 1.5,
}
local effectPTG = EFFECT_MAP[food_effect]

-- 语言
local LANG_MAP = require("prefabs/foods_lang")
local LANG = LANG_MAP[language] or LANG_MAP.english
local LANG_ENG = LANG_MAP.english

------------------------------------ 文字描述 ------------------------------------
local BUFF_LANG_MAP = {
	english = {
		foodMaltose = "Sweetness",
		monster_salad = "Monster Essence",
		aip_food_plov = "Fullness",
		egg_pancake = "Egg Nanny",
		fish_froggle = "Anti-thief",
		veg_lohan = "Charlie Go Away",
		aip_food_kozinaki = "I'm Full",
		honey_drumstick = "Speed Up",
		veggie_skewers = "Spirit",
		stinky_mandarin_fish = "Aftertaste",
		aip_food_cherry_meat = "Greasy",
		aip_food_egg_tart = "More Sugar!",
		aip_food_braised_intestine = "Think back...",
		aip_food_nest_sausage = "Soul Resonance",
	},
	chinese = {
		foodMaltose = "甜蜜蜜",
		monster_salad = "怪物精华",
		aip_food_plov = "吃的饱饱",
		egg_pancake = "鸟蛋保姆",
		fish_froggle = "防盗者",
		veg_lohan = "查理走开",
		aip_food_kozinaki = "饱腹感",
		honey_drumstick = "飞毛腿",
		veggie_skewers = "精神饱满",
		stinky_mandarin_fish = "回味十足",
		aip_food_cherry_meat = "油腻腻",
		aip_food_egg_tart = "更多糖分!",
		aip_food_braised_intestine = "仔细一想...",
		aip_food_nest_sausage = "灵魂共鸣",
	},
}

local BUFF_LANG = BUFF_LANG_MAP[language] or BUFF_LANG_MAP.english

-------------------------------------- 资源 --------------------------------------
local prefabList = {}
local prefabs =
{
	"spoiled_food",
}

local HP = TUNING.HEALING_TINY -- 1 healing
local HU = TUNING.CALORIES_HUGE / 75 -- 1 hunger
local SAN = TUNING.SANITY_SUPERTINY -- 1 sanity
local PER = TUNING.PERISH_ONE_DAY -- 1 day
local CO = 1 / 20 -- 1 second

-- 方法
local function getCount(entity, name)
	return entity[name] or 0
end

-- 香料
local function oneaten_garlic(inst, eater)
    if eater.components.debuffable ~= nil and eater.components.debuffable:IsEnabled() and
        not (eater.components.health ~= nil and eater.components.health:IsDead()) and
        not eater:HasTag("playerghost") then
        eater.components.debuffable:AddDebuff("buff_playerabsorption", "buff_playerabsorption")
    end
end

local function oneaten_sugar(inst, eater)
    if eater.components.debuffable ~= nil and eater.components.debuffable:IsEnabled() and
        not (eater.components.health ~= nil and eater.components.health:IsDead()) and
        not eater:HasTag("playerghost") then
        eater.components.debuffable:AddDebuff("buff_workeffectiveness", "buff_workeffectiveness")
    end
end

local function oneaten_chili(inst, eater)
    if eater.components.debuffable ~= nil and eater.components.debuffable:IsEnabled() and
        not (eater.components.health ~= nil and eater.components.health:IsDead()) and
        not eater:HasTag("playerghost") then
        eater.components.debuffable:AddDebuff("buff_attack", "buff_attack")
    end
end

local SPICES = {
    SPICE_GARLIC = { rgba = { 0.6, 0.6, 1.0, 0.9 }, oneatenfn = oneaten_garlic, prefabs = { "buff_playerabsorption" } },
    SPICE_SUGAR  = { rgba = { 1.0, 1.0, 0.3, 1.0 }, oneatenfn = oneaten_sugar, prefabs = { "buff_workeffectiveness" } },
    SPICE_CHILI  = { rgba = { 1.0, 0.5, 0.5, 1.0 }, oneatenfn = oneaten_chili, prefabs = { "buff_attack" } },
}

----------------------------------- 方法 -----------------------------------
-- 春天效果翻倍
local function getSpringBallHealth(inst, eater)
	if TheWorld.state.isspring then
		return inst.components.edible.healthvalue * 2
	end
	return inst.components.edible.healthvalue
end

local function getSpringBallSanity(inst, eater)
	if TheWorld.state.isspring then
		return inst.components.edible.sanityvalue * 2
	end
	return inst.components.edible.sanityvalue
end

-- 夏天效果翻倍
local function getSummerHealth(inst, eater)
	if TheWorld.state.issummer then
		return inst.components.edible.healthvalue * 2
	end
	return inst.components.edible.healthvalue
end

local function getSummerSanity(inst, eater)
	if TheWorld.state.issummer then
		return inst.components.edible.sanityvalue * 2
	end
	return inst.components.edible.sanityvalue
end

----------------------------------- 配方 -----------------------------------
local food_recipes = {
	egg_pancake = {
		test = function(cooker, names, tags) return tags.egg and tags.egg >= 3 and not tags.inedible end,
		priority = 1,
		weight = 1,
		foodtype = FOODTYPE.MEAT,
		health = HP * 20,
		hunger = HU * 80,
		sanity = SAN * 10,
		perishtime = PER * 5,
		cooktime = CO * 20,
		buff = {
			duration = 120,
			fn = function(source, eater, info)
				-- 加速腐化高脚鸟蛋
				local x, y, z = eater.Transform:GetWorldPosition()
				local ents = TheSim:FindEntities(x, 0, z, 3, { "tallbirdegg" })
				for i, egg in ipairs(ents) do
					if egg.components.hatchable ~= nil then
						local ptg = dev_mode and 99999 or info.interval
						egg.components.hatchable.progress = egg.components.hatchable.progress + ptg
					end
				end
			end,
		},
	},

	monster_salad = {
		test = function(cooker, names, tags) return tags.monster and tags.veggie and tags.veggie >= 3 and not tags.inedible end,
		priority = 0,
		weight = 1,
		foodtype = FOODTYPE.VEGGIE,
		health = HP * 5,
		hunger = HU * 65,
		sanity = SAN * 10,
		perishtime = PER * 6,
		cooktime = CO * 20,
		buff = {
			duration = dev_mode and 20 or 120,
		},
	},
	
	skunk_smoothies = {
		test = function(cooker, names, tags)
			return (names.durian or names.durian_cooked) and tags.frozen and tags.fruit and tags.fruit >= 2 and not tags.inedible
		end,
		priority = 1,
		weight = 1,
		foodtype = FOODTYPE.VEGGIE,
		health = HP * 5,
		hunger = HU * 20,
		sanity = SAN * 35,
		perishtime = PER * 6,
		cooktime = CO * 10,
		oneatenfn = function(inst, eater)
			if
				eater.prefab == "pigman" and eater.components.werebeast ~= nil and
				not eater.components.werebeast:IsInWereState()
			then
				eater.components.werebeast:SetWere()
			end
		end,
	},
	fish_froggle = {
		test = function(cooker, names, tags)
			return (names.froglegs or names.froglegs_cooked) and tags.fish and not tags.inedible
		end,
		priority = 2,
		weight = 1,
		foodtype = FOODTYPE.MEAT,
		health = HP * 30,
		hunger = HU * 80,
		sanity = SAN * 15,
		perishtime = PER * 6,
		cooktime = CO * 40,
		buff = {
			duration = 120,
		},
	},
	bamboo_light = {
		test = function(cooker, names, tags)
			return (names.corn or names.corn_cooked) and (names.carrot or names.carrot_cooked) and (names.pumpkin or names.pumpkin_cooked)
		end,
		priority = 1,
		weight = 1,
		foodtype = FOODTYPE.VEGGIE,
		health = HP * 100,
		hunger = HU * 5,
		sanity = SAN * 10,
		perishtime = PER * 20,
		cooktime = CO * 15,
		oneatenfn = function(inst, eater)
			-- 满血时治疗附近玩家
			if eater.components.health ~= nil and eater.components.health:GetPercent() == 1 then
				local players = aipFindNearPlayers(eater, 10)
				for i, player in ipairs(players) do
					if player.components.health ~= nil then
						aipSpawnPrefab(player, "farm_plant_happy")
						player.components.health:DoDelta(10)
					end
				end
			end
		end,
	},
	vegetaballs = {
		test = function(cooker, names, tags)
			return tags.meat and tags.meat == 2 and tags.veggie and not tags.inedible and not tags.frozen and not tags.fruit and not names.foliage
		end,
		priority = 0,
		weight = 1,
		foodtype = FOODTYPE.MEAT,
		health = HP * 5,
		hunger = HU * 60,
		sanity = SAN * 10,
		perishtime = PER * 10,
		cooktime = CO * 15,
		oneatenfn = function(inst, eater)
			-- 提升 女武神 激励值 40%
			if eater.components.singinginspiration ~= nil then
				local currentPTG = eater.components.singinginspiration:GetPercent()
				local nextPTG = math.min(currentPTG + 0.4, 1)
				if nextPTG > currentPTG then
					eater.components.singinginspiration:SetPercent(nextPTG)
				end
			end
		end,
	},
	veg_lohan = {
		test = function(cooker, names, tags)
			local red = getCount(names, "red_cap") +  getCount(names, "red_cap_cooked")
			local green = getCount(names, "green_cap") +  getCount(names, "green_cap_cooked")
			local blue = getCount(names, "blue_cap") +  getCount(names, "blue_cap_cooked")
			return red + green + blue > 3
		end,
		priority = 1,
		weight = 1,
		foodtype = FOODTYPE.VEGGIE,
		health = HP * 5,
		hunger = HU * 50,
		sanity = SAN * 15,
		perishtime = PER * 20,
		cooktime = CO * 30,
		buff = {
			duration = 60 * 10,
		},
	},
	honey_drumstick = {
		test = function(cooker, names, tags)
			return names.drumstick and tags.sweetener and tags.sweetener >= 2 and tags.meat and tags.meat < 1
		end,
		priority = 3,
		weight = 1,
		foodtype = FOODTYPE.MEAT,
		health = HP * 20,
		hunger = HU * 40,
		sanity = SAN * 5,
		perishtime = PER * 6,
		cooktime = CO * 30,
		tags = {"honeyed"},
		buff = {
			duration = 30,
			startFn = function(source, inst, info)
				if inst.components.locomotor ~= nil then
					inst.components.locomotor:SetExternalSpeedMultiplier(
						inst, "aip_honey_drumstick", dev_mode and 2 or 1.25
					)
				end
			end,
			endFn = function(source, inst, info)
				if inst.components.locomotor ~= nil then
					inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, "aip_honey_drumstick")
				end
			end,
		},
	},
	meat_burger = {
		test = function(cooker, names, tags)
			return tags.meat and tags.meat > 1 and tags.egg and (names.froglegs or names.froglegs_cooked) and tags.fish
		end,
		priority = 3,
		weight = 1,
		foodtype = FOODTYPE.MEAT,
		health = HP * 20,
		hunger = HU * 150,
		sanity = SAN * 5,
		perishtime = PER * 10,
		cooktime = CO * 15,
		oneatenfn = function(inst, eater)
			-- 健身效果 +40%
			if eater.components.mightiness ~= nil then
				local currentPTG = eater.components.mightiness:GetPercent()
				local nextPTG = math.min(currentPTG + 0.4, 1)
				if nextPTG > currentPTG then
					eater.components.mightiness:SetPercent(nextPTG)
				end
			end
		end,
	},
	veggie_skewers = {
		test = function(cooker, names, tags)
			return tags.veggie and tags.inedible and tags.inedible < 2 and not tags.meat
		end,
		priority = -1,
		weight = 1,
		foodtype = FOODTYPE.VEGGIE,
		health = HP * 5,
		hunger = HU * 30,
		sanity = SAN * 5,
		perishtime = PER * 15,
		cooktime = CO * 20,
		buff = {
			duration = 60 * 5,
		},
	},
	stinky_mandarin_fish = {
		test = function(cooker, names, tags)
			return tags.fish and tags.monster and not tags.inedible
		end,
		priority = 0,
		weight = 1,
		foodtype = FOODTYPE.MEAT,
		health = HP * -60,
		hunger = HU * 65,
		sanity = SAN * 5,
		perishtime = PER * 10,
		cooktime = CO * 30,
		buff = {
			duration = 20,
			fn = function(source, eater, info)
				-- 恢复生命
				if eater.components.health ~= nil and info.tickTime % 2 == 0 then
					eater.components.health:DoDelta(6)
				end
			end,
		},
	},
	watermelon_juice = {
		test = function(cooker, names, tags)
			return names.watermelon and tags.fruit and tags.fruit > 1 and tags.frozen
		end,
		priority = 1,
		weight = 1,
		foodtype = FOODTYPE.VEGGIE,
		health = HP * 15,
		hunger = HU * 20,
		sanity = SAN * 10,
		perishtime = PER * 6,
		cooktime = CO * 20,
		postFn = function(inst)
			inst.components.edible:SetGetHealthFn(getSummerHealth)
			inst.components.edible:SetGetSanityFn(getSummerSanity)
		end,
	},
	caterpillar_bread = {
		test = function(cooker, names, tags)
			return names.butterflywings and tags.meat
		end,
		priority = 10,
		weight = 1,
		foodtype = FOODTYPE.MEAT,
		health = HP * 15,
		hunger = HU * 50,
		sanity = SAN * 5,
		perishtime = PER * 15,
		cooktime = CO * 40,
		oneatenfn = function(inst, eater)
			-- 召唤 蝴蝶
			aipSpawnPrefab(eater, "butterfly")
		end,
	},
	durian_sugar = {
		test = function(cooker, names, tags)
			return (names.durian or names.durian_cooked) and tags.sweetener and tags.sweetener >= 2
		end,
		priority = 20,
		weight = 1,
		foodtype = FOODTYPE.VEGGIE,
		health = HP * (-10),
		hunger = HU * 20,
		sanity = SAN * 20,
		perishtime = PER * 15,
		cooktime = CO * 30,
		tags = {"honeyed"},
	},
	frozen_heart = {
		test = function(cooker, names, tags)
			return tags.frozen and tags.frozen > 3
		end,
		priority = 0.5,
		weight = 1,
		foodtype = FOODTYPE.VEGGIE,
		health = HP * 0,
		hunger = HU * 0,
		sanity = SAN * 0,
		perishtime = PER * 30,
		cooktime = CO * 10,
		temperature = TUNING.COLD_FOOD_BONUS_TEMP,
		temperatureduration = TUNING.FOOD_TEMP_LONG,
		goldvalue = TUNING.GOLD_VALUES.MEAT,
		tags = {"frozen", "aip_nectar_material"},
	},
	aip_food_egg_fried_rice = {
		test = function(cooker, names, tags)
			return tags.starch and tags.egg and not tags.fruit
		end,
		priority = 6,
		weight = 1,
		foodtype = FOODTYPE.VEGGIE,
		health = HP * 0,
		hunger = HU * 35,
		sanity = SAN * 0,
		perishtime = PER * 15,
		cooktime = CO * 10,
		oneatenfn = function(inst, eater)
			-- 如果 饥饿 小于等于 恢复值，直接加满饥饿度
			if
				eater.components.hunger ~= nil and
				eater.components.hunger.current <= inst.components.edible.hungervalue
			then
				eater.components.hunger:SetPercent(1)
			end
		end,
	},
	aip_food_plov = {
		test = function(cooker, names, tags)
			return tags.starch and tags.meat and (names.carrot or names.carrot_cooked)
		end,
		priority = 6,
		weight = 1,
		foodtype = FOODTYPE.MEAT,
		health = HP * 25,
		hunger = HU * (dev_mode and -9999 or 75),
		sanity = SAN * 5,
		perishtime = PER * 20,
		cooktime = CO * 40,
		buff = {
			duration = dev_mode and 30 or 60 * 3,
		},
	},
	aip_food_kozinaki = {
		test = function(cooker, names, tags)
			return tags.starch and tags.starch >= 2 and tags.sweetener
		end,
		priority = 6,
		weight = 1,
		foodtype = FOODTYPE.VEGGIE,
		health = HP * 10,
		hunger = HU * (dev_mode and -9999 or 20),
		sanity = SAN * 7,
		perishtime = PER * 30,
		cooktime = CO * 20,
		buff = {
			duration = (2 * 3) * 30,
			fn = function(source, eater, info)
				-- 持续恢复饥饿度
				if eater.components.hunger ~= nil and info.tickTime % (2 * 3) == 0 then
					eater.components.hunger:DoDelta(1)
				end
			end,
		},
	},
	aip_food_cherry_meat = {
		test = function(cooker, names, tags)
			return tags.meat and tags.meat >= 1.5 and tags.meat < 3 and (
				names.berries or names.berries_cooked or names.berries_juicy or names.berries_juicy_cooked or
				names.aip_veggie_grape or names.aip_veggie_grape_cooked
			)
		end,
		priority = 1,
		weight = 1,
		foodtype = FOODTYPE.MEAT,
		health = HP * 15,
		hunger = HU * 50,
		sanity = SAN * 15,
		perishtime = PER * 10,
		cooktime = CO * 15,
		buff = {
			duration = 60 * 2,
		},
	},
	aip_food_egg_tart = {
		test = function(cooker, names, tags)
			return tags.starch and tags.egg and not tags.meat and not tags.inedible
		end,
		priority = 6,
		weight = 1,
		foodtype = FOODTYPE.MEAT,
		health = HP * 10,
		hunger = HU * 30,
		sanity = SAN * 15,
		perishtime = PER * 10,
		cooktime = CO * 15,
		buff = {
			duration = 60,
		},
		oneatenfn = function(inst, eater)
			-- 如果吃第二个，效果变得更好了
			if aipBufferExist(eater, "aip_food_egg_tart") then
				if eater.components.health ~= nil then
					eater.components.health:DoDelta(inst.components.edible.healthvalue)
				end
				if eater.components.sanity ~= nil then
					eater.components.sanity:DoDelta(inst.components.edible.sanityvalue)
				end
			end
		end,
	},
	aip_food_grape_suger = {
		test = function(cooker, names, tags)
			return tags.sweetener and tags.inedible and tags.inedible == 1 and names.aip_veggie_grape
		end,
		priority = 10,
		weight = 1,
		foodtype = FOODTYPE.VEGGIE,
		health = -HP * 5,
		hunger = HU * 15,
		sanity = SAN * 15,
		perishtime = PER * 30,
		cooktime = CO * 15,
		tags = {"honeyed"},
		goldvalue = 0, -- 加一个数值，让其可以给若光交易
	},
	aip_food_cube_sugar = {
		test = function(cooker, names, tags)
			return tags.sweetener and tags.sweetener >= 3 and names.watermelon and not tags.inedible
		end,
		priority = 11,
		weight = 1,
		foodtype = FOODTYPE.VEGGIE,
		health = HP * 0,
		hunger = HU * 25,
		sanity = SAN * 15,
		perishtime = PER * 15,
		cooktime = CO * 40,
		tags = {"honeyed", "aip_nectar_material", "aip_exquisite"},
	},

	aip_food_nest_sausage = {	-- 大肠包小肠
		test = function(cooker, names, tags)
			return names.aip_cold_skin and tags.meat and tags.meat >= 1 and tags.starch and tags.starch > 1 and not tags.inedible
		end,
		priority = 20,
		weight = 1,
		foodtype = FOODTYPE.MEAT,
		health = HP * 5,
		hunger = HU * 65,
		sanity = SAN * 5,
		perishtime = PER * 15,
		cooktime = CO * 15,
		buff = {
			duration = 60 * 5,
		},
	},

	aip_food_vermicelli_roll = {	-- 肠粉
		test = function(cooker, names, tags)
			return names.aip_cold_skin and names.aip_cold_skin >= 2 and tags.egg and not tags.inedible
		end,
		priority = 20,
		weight = 1,
		foodtype = FOODTYPE.MEAT,
		health = HP * 5,
		hunger = HU * 25,
		sanity = SAN * 25,
		perishtime = PER * 10,
		cooktime = CO * 15,
		oneatenfn = function(inst, eater)
			-- 喂饱周围的人
			local players = aipFindNearPlayers(eater, 10)
			for i, player in ipairs(players) do
				if player.components.hunger ~= nil then
					aipSpawnPrefab(player, "farm_plant_happy")
					player.components.hunger:DoDelta(inst.components.edible.hungervalue)
				end
			end
		end,
	},

	aip_food_braised_intestine = {	-- 九转大肠
		test = function(cooker, names, tags)
			return names.aip_cold_skin and tags.meat and tags.monster and not tags.inedible
		end,
		priority = 15,
		weight = 1,
		foodtype = FOODTYPE.MEAT,
		health = HP * -10,
		hunger = HU * 75,
		sanity = SAN * -55,
		perishtime = PER * 15,
		cooktime = CO * 15,
		buff = {
			duration = 10.9,
			fn = function(source, eater, info)
				-- 恢复 理智
				if eater.components.sanity ~= nil and info.tickTime % 2 == 0 then
					eater.components.sanity:DoDelta(4)
				end
			end,
		},
	},

	aip_food_spring_ball = {	-- 咬春福袋
		test = function(cooker, names, tags)
			return names.aip_cold_skin and tags.egg and
				(names.carrot or names.carrot_cooked) and
				(names.corn or names.corn_cooked)
		end,
		priority = 99,
		weight = 1,
		foodtype = FOODTYPE.VEGGIE,
		health = dev_mode and 10 or HP * 35,
		hunger = HU * 15,
		sanity = dev_mode and 10 or SAN * 25,
		perishtime = PER * 20,
		cooktime = CO * 15,
		postFn = function(inst)
			inst.components.edible:SetGetHealthFn(getSpringBallHealth)
			inst.components.edible:SetGetSanityFn(getSpringBallSanity)
		end,
	},

	aip_food_maltose = {	-- 麦芽糖
		test = function(cooker, names, tags)
			return tags.starch and tags.starch == 2 and names.twigs and names.twigs == 2
		end,
		priority = 20,
		weight = 1,
		foodtype = FOODTYPE.GOODIES,
		health = - HP * 5,
		hunger = HU * 25,
		sanity = SAN * 55,
		perishtime = PER * 15,
		cooktime = CO * 40,
		oneatenfn = function(inst, eater)
			aipBufferPatch(inst, eater, "foodMaltose", dev_mode and 20 or 120)
		end,
		buff = {
			buffName = "foodMaltose",
			name = BUFF_LANG.foodMaltose,
			fn = function(source, eater, info)
				-- 恢复理智
				if eater.components.sanity ~= nil and info.tickTime % 2 == 0 then
					eater.components.sanity:DoDelta(1)
				end
			end,
		},
	},

	-- 古神低语
	aip_food_leather_jelly = { -- 皮质果冻，叶肉 + 粘衣
		test = function(cooker, names, tags)
			return (
				(names.plantmeat or 0) + (names.plantmeat_cooked or 0) >= 1 and
				tags.indescribable and tags.indescribable > 1 and
				tags.sweetener
			)
		end,
		priority = 99,
		weight = 1,
		foodtype = FOODTYPE.VEGGIE,
		health = HP * -10,
		hunger = HU * 25,
		sanity = SAN * -10,
		perishtime = PER * 5,
		cooktime = CO * 20,
		tags = {"honeyed"},
		oneatenfn = function(inst, eater)
			aipBufferPatch(inst, eater, "aip_see_eyes", dev_mode and 20 or 120)

			-- 如果是满月吃，一定能得到 羁绊之刃
			if TheWorld.state.isfullmoon and eater.components.aipc_player_show ~= nil then
				eater.components.aipc_player_show:CreateLivingFriendship()
			end
		end,
	},

	-- 量力而行
	aip_food_rice_balls = { -- 栗饭团，栗子 + 粮食
		test = function(cooker, names, tags)
			return (
				(names.acorn or names.acorn_cooked) and
				tags.starch and tags.starch >= 3
			)
		end,
		stacksize = 2,
		priority = 99,
		weight = 1,
		foodtype = FOODTYPE.VEGGIE,
		health = 5,
		hunger = HU * 50,
		sanity = 0,
		perishtime = PER * 30,
		cooktime = CO * 20,
		postFn = function(inst)
			inst:AddComponent("boatpatch")
			inst.components.boatpatch.patch_type = "treegrowth"

			inst:AddComponent("repairer")
			inst.components.repairer.repairmaterial = MATERIALS.WOOD
			inst.components.repairer.healthrepairvalue = TUNING.REPAIR_LOGS_HEALTH * 2
			inst.components.repairer.boatrepairsound = "turnoftides/common/together/boat/repair_with_wood"
		end,
	},
}

--------------------------------------------------
for name,data in pairs(food_recipes) do
	local atlas = "images/inventoryimages/"..name..".xml"
	local tex = name..".tex"

	-- 预处理
	data.name = name
	data.weight = data.weight or 1
	data.priority = data.priority or 0

	-- 食物属性
	data.health = data.health * effectPTG
	data.hunger = data.hunger * effectPTG
	data.sanity = data.sanity * effectPTG

	-- 烹饪时间
	data.cooktime = data.cooktime * (dev_mode and 0.1 or 1)

	-- 食物贴图
	data.cookbook_atlas = atlas
	data.cookbook_tex = tex

	-- 添加文字
	local upperCase = string.upper(name)
	local FOOD_LANG = LANG[upperCase] or LANG_ENG[upperCase]
	
	STRINGS.NAMES[upperCase] = FOOD_LANG.NAME
	STRINGS.CHARACTERS.GENERIC.DESCRIBE[upperCase] = FOOD_LANG.DESC

	-- 添加食物
	AddModPrefabCookerRecipe("cookpot", data)
	AddModPrefabCookerRecipe("portablecookpot", data)
	AddModPrefabCookerRecipe("archive_cookpot", data)

	-------------------- 添加 Buffer --------------------
	local buffInfo = data.buff

	if buffInfo then
		local buffName = buffInfo.buffName or name

		aipBufferRegister(buffName, {
			name = BUFF_LANG[buffName],
			fn = buffInfo.fn,
			startFn = buffInfo.startFn,
			endFn = buffInfo.endFn,
			showFX = buffInfo.showFX,
		})

		-- 代理一下 onEaten，添加 Buffer
		local oriOnEaten = data.oneatenfn
		data.oneatenfn = function(inst, eater)
			if oriOnEaten then
				oriOnEaten(inst, eater)
			end

			aipBufferPatch(inst, eater, buffName, buffInfo.duration)
		end
	end

	data.buff = nil

	-------------------- 创建食物实体 --------------------
	local assets = {
		Asset("ATLAS", atlas),
		Asset("IMAGE", "images/inventoryimages/"..tex),
		Asset("ANIM", "anim/"..data.name..".zip"),
	}

	function getFn(r, g, b, a)
		return function()
			local inst = CreateEntity()

			inst.entity:AddTransform()
			inst.entity:AddAnimState()
			inst.entity:AddNetwork()

			MakeInventoryPhysics(inst)

			inst.AnimState:SetBuild(data.name)
			inst.AnimState:SetBank(data.name)
			inst.AnimState:PlayAnimation("BUILD", false)

			inst.AnimState:SetMultColour(r, g, b, a)

			inst:AddTag("preparedfood")
			if data.tags then
				for i,v in pairs(data.tags) do
					inst:AddTag(v)
				end
			end

			if data.floater ~= nil then
				MakeInventoryFloatable(inst, data.floater[1], data.floater[2], data.floater[3])
			else
				MakeInventoryFloatable(inst)
			end

			inst.entity:SetPristine()

			if not TheWorld.ismastersim then
				return inst
			end

			-- 食物
			inst:AddComponent("edible")
			inst.components.edible.healthvalue = data.health
			inst.components.edible.hungervalue = data.hunger
			inst.components.edible.foodtype = data.foodtype or FOODTYPE.GENERIC
			inst.components.edible.sanityvalue = data.sanity or 0
			inst.components.edible.temperaturedelta = data.temperature or 0
			inst.components.edible.temperatureduration = data.temperatureduration or 0
			inst.components.edible:SetOnEatenFn(data.oneatenfn)

			inst:AddComponent("inspectable")
			inst.wet_prefix = data.wet_prefix

			-- 是否可以交易
			inst:AddComponent("tradable")
			if data.goldvalue ~= nil then
				inst.components.tradable.goldvalue = data.goldvalue
			end

			if data.postFn ~= nil then
				data.postFn(inst)
			end

			-- 物品栏
			inst:AddComponent("inventoryitem")
			inst.components.inventoryitem.atlasname = "images/inventoryimages/"..data.name..".xml"
			inst.components.inventoryitem.imagename = data.name

			inst:AddComponent("stackable")
			inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

			if data.perishtime ~= nil and data.perishtime > 0 then
				inst:AddComponent("perishable")
				inst.components.perishable:SetPerishTime(data.perishtime)
				inst.components.perishable:StartPerishing()
				inst.components.perishable.onperishreplacement = "spoiled_food"
			end

			MakeSmallBurnable(inst)
			MakeSmallPropagator(inst)
			MakeHauntableLaunchAndPerish(inst)
			AddHauntableCustomReaction(inst, function(inst, haunter)
				return false
			end, true, false, true)
			---------------------

			inst:AddComponent("bait")

			------------------------------------------------

			return inst
		end
	end

	local prefab = Prefab(name, getFn(1,1,1,1), assets, prefabs)
	table.insert(prefabList, prefab)

	-------------------- 添加香料支持 --------------------
	for spicenameupper, spicedata in pairs(SPICES) do
		local newdata = shallowcopy(data)
		local spicename = string.lower(spicenameupper)
		local newFoodName = name.."_"..spicename

		newdata.test = function(cooker, names, tags) return names[name] and names[spicename] end
		newdata.priority = 100

		newdata.cooktime = .12
		newdata.stacksize = nil
		newdata.spice = spicenameupper
		newdata.basename = name
		newdata.name = newFoodName
		newdata.floater = {"med", nil, {0.85, 0.7, 0.85}}
		-- spicedfoods[newdata.name] = newdata

		AddModPrefabCookerRecipe("portablespicer", newdata)

		if spicename == "spice_chili" then
			if newdata.temperature == nil then
				--Add permanent "heat" to regular food
				newdata.temperature = TUNING.HOT_FOOD_BONUS_TEMP
				newdata.temperatureduration = TUNING.FOOD_TEMP_LONG
				newdata.nochill = true
			elseif newdata.temperature > 0 then
				--Upgarde "hot" food to permanent heat
				newdata.temperatureduration = math.max(newdata.temperatureduration, TUNING.FOOD_TEMP_LONG)
				newdata.nochill = true
			end
		end

		if spicedata.prefabs ~= nil then
			--make a copy (via ArrayUnion) if there are dependencies from the original food
			newdata.prefabs = newdata.prefabs ~= nil and ArrayUnion(newdata.prefabs, spicedata.prefabs) or spicedata.prefabs
		end

		if spicedata.oneatenfn ~= nil then
			if newdata.oneatenfn ~= nil then
				local oneatenfn_old = newdata.oneatenfn
				newdata.oneatenfn = function(inst, eater)
					spicedata.oneatenfn(inst, eater)
					oneatenfn_old(inst, eater)
				end
			else
				newdata.oneatenfn = spicedata.oneatenfn
			end
		end

		-- 添加文字
		local newUpperCase = string.upper(newFoodName)
		local FOOD_LANG = LANG[newUpperCase] or LANG_ENG[newUpperCase]
		
		STRINGS.NAMES[newUpperCase] = FOOD_LANG.NAME
		STRINGS.CHARACTERS.GENERIC.DESCRIBE[newUpperCase] = FOOD_LANG.DESC

		----------- 添加香料 -----------
		local rgba = spicedata.rgba
		local spicePrefab = Prefab(newFoodName, getFn(rgba[1], rgba[2], rgba[3], rgba[4]), assets, prefabs)
		table.insert(prefabList, spicePrefab)
	end
end



return unpack(prefabList)
