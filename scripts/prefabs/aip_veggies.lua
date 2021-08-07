------------------------------------ 配置 ------------------------------------
-- 食物
local additional_food = aipGetModConfig("additional_food")
if additional_food ~= "open" then
	return nil
end

local ORI_VEGGIES = require("prefabs/aip_veggies_list")

local food_effect = aipGetModConfig("food_effect")
local language = aipGetModConfig("language")

-- 默认参数
local HP = TUNING.HEALING_TINY -- 1 healing
local HU = TUNING.CALORIES_HUGE / 75 -- 1 hunger
local SAN = TUNING.SANITY_SUPERTINY -- 1 sanity
local PER = TUNING.PERISH_ONE_DAY -- 1 day
local CO = 1 / 20 -- 1 second

local EFFECT_MAP = {
	["less"] = 0.6,
	["normal"] = 1,
	["large"] = 1.5,
}
local effectPTG = EFFECT_MAP[food_effect]

-- 语言
local LANG_MAP = require("prefabs/aip_veggies_lang")
local LANG = LANG_MAP[language] or LANG_MAP.english
local LANG_ENG = LANG_MAP.english

-- 资源
local VEGGIES = {}
for veggiename, veggiedata in pairs(ORI_VEGGIES) do
	local wrapName = "aip_veggie_"..veggiename

	-- 属性
	VEGGIES[wrapName] = {
		health = HP * veggiedata.health,
		hunger = HU * veggiedata.hunger,
		sanity = SAN * veggiedata.sanity,
		perishtime = PER * veggiedata.perishtime,

		post = veggiedata.post,

		cooked_health = HP * veggiedata.cooked_health,
		cooked_hunger = HU * veggiedata.cooked_hunger,
		cooked_sanity = SAN * veggiedata.cooked_sanity,
		cooked_perishtime = PER * veggiedata.cooked_perishtime,
	}

	-- 文字描述
	local upperCase = string.upper(wrapName)
	local upperCase_cooked = upperCase.."_COOKED"
	local upperCase_seeds = upperCase.."_SEEDS"

	STRINGS.NAMES[upperCase] = LANG[veggiename].NAME or LANG_ENG[veggiename].NAME
	STRINGS.CHARACTERS.GENERIC.DESCRIBE[upperCase] = LANG[veggiename].DESC or LANG_ENG[veggiename].DESC

	STRINGS.NAMES[upperCase_cooked] = LANG[veggiename.."_cooked"].NAME or LANG_ENG[veggiename.."_cooked"].NAME
	STRINGS.CHARACTERS.GENERIC.DESCRIBE[upperCase_cooked] = LANG[veggiename.."_cooked"].DESC or LANG_ENG[veggiename.."_cooked"].DESC

	STRINGS.NAMES[upperCase_seeds] = LANG[veggiename.."_seeds"].NAME or LANG_ENG[veggiename.."_seeds"].NAME
	STRINGS.CHARACTERS.GENERIC.DESCRIBE[upperCase_seeds] = LANG[veggiename.."_seeds"].DESC or LANG_ENG[veggiename.."_seeds"].DESC
end

------------------------------------ 通用 ------------------------------------

local function MakeVeggie(name, has_seeds)

	local assets =
	{
		Asset("ATLAS", "images/inventoryimages/"..name..".xml"),
		Asset("ANIM", "anim/"..name..".zip"),
	}

	local assets_cooked =
	{
		Asset("ATLAS", "images/inventoryimages/"..name.."_cooked.xml"),
		Asset("ANIM", "anim/"..name..".zip"),
	}

	local assets_seeds =
	{
		Asset("ANIM", "anim/seeds.zip"),
		Asset("ATLAS", "images/inventoryimages/"..name.."_seeds.xml"),
	}

	local prefabs =
	{
		name.."_cooked",
		"spoiled_food",
	}
	
	if has_seeds then
		table.insert(prefabs, name.."_seeds")
	end

	local function fn_seeds()
		local inst = CreateEntity()

		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddNetwork()

		MakeInventoryPhysics(inst)
		MakeInventoryFloatable(inst, "small", 0.15, 0.9)

		inst.AnimState:SetBank("seeds")
		inst.AnimState:SetBuild("seeds")
		inst.AnimState:SetRayTestOnBB(true)

		--cookable (from cookable component) added to pristine state for optimization
		inst:AddTag("cookable")

		inst.entity:SetPristine()

		if not TheWorld.ismastersim then
			return inst
		end

		inst:AddComponent("edible")
		inst.components.edible.foodtype = FOODTYPE.SEEDS

		inst:AddComponent("stackable")
		inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

		inst:AddComponent("tradable")
		inst:AddComponent("inspectable")
		inst:AddComponent("inventoryitem")
		inst.components.inventoryitem.atlasname = "images/inventoryimages/"..name.."_seeds.xml"

		inst.AnimState:PlayAnimation("idle")
		inst.components.edible.healthvalue = TUNING.HEALING_TINY/2
		inst.components.edible.hungervalue = TUNING.CALORIES_TINY

		inst:AddComponent("perishable")
		inst.components.perishable:SetPerishTime(TUNING.PERISH_SUPERSLOW)
		inst.components.perishable:StartPerishing()
		inst.components.perishable.onperishreplacement = "spoiled_food"

		inst:AddComponent("cookable")
		inst.components.cookable.product = "seeds_cooked"

		inst:AddComponent("bait")
		inst:AddComponent("plantable")
		inst.components.plantable.growtime = TUNING.SEEDS_GROW_TIME
		inst.components.plantable.product = name

		MakeHauntableLaunchAndPerish(inst)

		return inst
	end

	local function fn()
		local inst = CreateEntity()

		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddNetwork()

		MakeInventoryPhysics(inst)
		MakeInventoryFloatable(inst, "small", 0.15, 0.9)

		inst.AnimState:SetBank(name)
		inst.AnimState:SetBuild(name)
		inst.AnimState:PlayAnimation("idle")

		--cookable (from cookable component) added to pristine state for optimization
		inst:AddTag("cookable")

		inst.entity:SetPristine()

		if not TheWorld.ismastersim then
			return inst
		end

		inst:AddComponent("edible")
		inst.components.edible.healthvalue = VEGGIES[name].health
		inst.components.edible.hungervalue = VEGGIES[name].hunger
		inst.components.edible.sanityvalue = VEGGIES[name].sanity or 0
		inst.components.edible.foodtype = FOODTYPE.VEGGIE

		inst:AddComponent("perishable")
		inst.components.perishable:SetPerishTime(VEGGIES[name].perishtime)
		inst.components.perishable:StartPerishing()
		inst.components.perishable.onperishreplacement = "spoiled_food"

		inst:AddComponent("stackable")
		if name ~= "pumpkin" and
			name ~= "eggplant" and
			name ~= "durian" and 
			name ~= "watermelon" then
			inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM
		end

		if name == "watermelon" then
			inst.components.edible.temperaturedelta = TUNING.COLD_FOOD_BONUS_TEMP
			inst.components.edible.temperatureduration = TUNING.FOOD_TEMP_BRIEF
		end

		inst:AddComponent("inspectable")
		inst:AddComponent("inventoryitem")
		inst.components.inventoryitem.atlasname = "images/inventoryimages/"..name..".xml"

		MakeSmallBurnable(inst)
		MakeSmallPropagator(inst)
		---------------------

		inst:AddComponent("bait")

		------------------------------------------------
		inst:AddComponent("tradable")

		------------------------------------------------  

		inst:AddComponent("cookable")
		inst.components.cookable.product = name.."_cooked"

		MakeHauntableLaunchAndPerish(inst)

		if VEGGIES[name].post ~= nil then
			VEGGIES[name].post(inst)
		end

		return inst
	end

	local function fn_cooked()
		local inst = CreateEntity()

		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddNetwork()

		MakeInventoryPhysics(inst)
		MakeInventoryFloatable(inst, "small", 0.15, 0.9)

		inst.AnimState:SetBank(name)
		inst.AnimState:SetBuild(name)
		inst.AnimState:PlayAnimation("cooked")

		inst.entity:SetPristine()

		if not TheWorld.ismastersim then
			return inst
		end

		inst:AddComponent("perishable")
		inst.components.perishable:SetPerishTime(VEGGIES[name].cooked_perishtime)
		inst.components.perishable:StartPerishing()
		inst.components.perishable.onperishreplacement = "spoiled_food"

		inst:AddComponent("edible")
		inst.components.edible.healthvalue = VEGGIES[name].cooked_health
		inst.components.edible.hungervalue = VEGGIES[name].cooked_hunger
		inst.components.edible.sanityvalue = VEGGIES[name].cooked_sanity or 0
		inst.components.edible.foodtype = FOODTYPE.VEGGIE

		inst:AddComponent("stackable")
		inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

		inst:AddComponent("inspectable")
		inst:AddComponent("inventoryitem")
		inst.components.inventoryitem.atlasname = "images/inventoryimages/"..name.."_cooked.xml"

		MakeSmallBurnable(inst)
		MakeSmallPropagator(inst)
		---------------------

		inst:AddComponent("bait")

		------------------------------------------------
		inst:AddComponent("tradable")

		MakeHauntableLaunchAndPerish(inst)

		return inst
	end

	local base = Prefab(name, fn, assets, prefabs)
	local cooked = Prefab(name.."_cooked", fn_cooked, assets_cooked)
	local seeds = has_seeds and Prefab(name.."_seeds", fn_seeds, assets_seeds) or nil

	return base, cooked, seeds
end

local prefs = {}
for veggiename,veggiedata in pairs(VEGGIES) do
	local veg, cooked, seeds = MakeVeggie(veggiename, veggiedata.hasSeed)
	table.insert(prefs, veg)
	table.insert(prefs, cooked)
	if seeds then
		table.insert(prefs, seeds)
	end
end

return unpack(prefs)
