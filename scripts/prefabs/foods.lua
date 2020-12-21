local foldername = KnownModIndex:GetModActualName(TUNING.ZOMBIEJ_ADDTIONAL_PACKAGE)

-- 配置
local additional_food = aipGetModConfig("additional_food")
if additional_food ~= "open" then
	return nil
end

local food_effect = aipGetModConfig("food_effect")
local language = aipGetModConfig("language")

-- 默认参数
local EFFECT_MAP = {
	["less"] = 0.6,
	["normal"] = 1,
	["large"] = 1.5,
}
local effectPTG = EFFECT_MAP[food_effect]

-- 语言
local LANG_MAP = require("prefabs/foods_lang")
local LANG = LANG_MAP[language] or LANG_MAP.english
local LANG_ENG = LANG_MAP.english

-- 资源
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

local SPICES =
{
    SPICE_GARLIC = { rgba = { 0.6, 0.6, 1.0, 0.9 }, oneatenfn = oneaten_garlic, prefabs = { "buff_playerabsorption" } },
    SPICE_SUGAR  = { rgba = { 1.0, 1.0, 0.3, 1.0 }, oneatenfn = oneaten_sugar, prefabs = { "buff_workeffectiveness" } },
    SPICE_CHILI  = { rgba = { 1.0, 0.5, 0.5, 1.0 }, oneatenfn = oneaten_chili, prefabs = { "buff_attack" } },
}

-- 配方
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
	},
	vegetaballs = {
		test = function(cooker, names, tags)
			return tags.meat and tags.meat == 2 and tags.veggie and not tags.inedible and not tags.frozen and not tags.fruit
		end,
		priority = 0,
		weight = 1,
		foodtype = FOODTYPE.MEAT,
		health = HP * 5,
		hunger = HU * 60,
		sanity = SAN * 10,
		perishtime = PER * 10,
		cooktime = CO * 15,
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
	},
	stinky_mandarin_fish = {
		test = function(cooker, names, tags)
			return tags.fish and tags.monster and not tags.inedible
		end,
		priority = 0,
		weight = 1,
		foodtype = FOODTYPE.MEAT,
		health = HP * 10,
		hunger = HU * 65,
		sanity = SAN * 5,
		perishtime = PER * 10,
		cooktime = CO * 30,
	},
	watermelon_juice = {
		test = function(cooker, names, tags)
			return names.watermelon and tags.fruit and tags.fruit > 1 and tags.frozen
		end,
		priority = 1,
		weight = 1,
		foodtype = FOODTYPE.VEGGIE,
		health = HP * 5,
		hunger = HU * 40,
		sanity = SAN * 5,
		perishtime = PER * 6,
		cooktime = CO * 20,
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
		priority = -1,
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
		hunger = HU * 75,
		sanity = SAN * 0,
		perishtime = PER * 15,
		cooktime = CO * 10,
	},
	aip_food_plov = {
		test = function(cooker, names, tags)
			return tags.starch and tags.meat and (names.carrot or names.carrot_cooked)
		end,
		priority = 6,
		weight = 1,
		foodtype = FOODTYPE.MEAT,
		health = HP * 25,
		hunger = HU * 75,
		sanity = SAN * 5,
		perishtime = PER * 20,
		cooktime = CO * 40,
	},
	aip_food_kozinaki = {
		test = function(cooker, names, tags)
			return tags.starch and tags.starch >= 2 and tags.sweetener
		end,
		priority = 6,
		weight = 1,
		foodtype = FOODTYPE.VEGGIE,
		health = HP * 10,
		hunger = HU * 65,
		sanity = SAN * 7,
		perishtime = PER * 30,
		cooktime = CO * 20,
	},
	aip_food_cherry_meat = {
		test = function(cooker, names, tags)
			return tags.meat and tags.meat >= 1.5 and tags.meat < 3 and (
				names.berries or names.berries_cooked or names.berries_juicy or names.berries_juicy_cooked or
				names.aip_grape or names.aip_grape_cooked
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
	},
	aip_food_grape_suger = {
		test = function(cooker, names, tags)
			return tags.sweetener and tags.inedible and tags.inedible == 1 and names.aip_grape
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
}

--------------------------------------------------
for name,data in pairs(food_recipes) do
	-- 预处理
	data.name = name
	data.weight = data.weight or 1
	data.priority = data.priority or 0

	-- 食物属性
	data.health = data.health * effectPTG
	data.hunger = data.hunger * effectPTG
	data.sanity = data.sanity * effectPTG

	-- 添加文字
	local upperCase = string.upper(name)
	local FOOD_LANG = LANG[upperCase] or LANG_ENG[upperCase]
	
	STRINGS.NAMES[upperCase] = FOOD_LANG.NAME
	STRINGS.CHARACTERS.GENERIC.DESCRIBE[upperCase] = FOOD_LANG.DESC

	-- 添加食物
	AddModPrefabCookerRecipe("cookpot", data)
	AddModPrefabCookerRecipe("portablecookpot", data)

	-------------------- 创建食物实体 --------------------
	local assets = {
		Asset("ATLAS", "images/inventoryimages/"..data.name..".xml"),
		Asset("IMAGE", "images/inventoryimages/"..data.name..".tex"),
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
			if data.goldvalue then
				inst:AddComponent("tradable")
				inst.components.tradable.goldvalue = data.goldvalue
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
