local foldername = KnownModIndex:GetModActualName(TUNING.ZOMBIEJ_ADDTIONAL_PACKAGE)

------------------------------------ 配置 ------------------------------------
-- 体验关闭
local additional_experiment = GetModConfigData("additional_experiment", foldername)
if additional_experiment ~= "open" then
	return nil
end

-- 食物
local additional_food = GetModConfigData("additional_food", foldername)
if additional_food ~= "open" then
	return nil
end

local food_effect = GetModConfigData("food_effect", foldername)
local language = GetModConfigData("language", foldername)

-- 默认参数
local COMMON = 3
local UNCOMMON = 1
local RARE = .5

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
local LANG_MAP = {
	["english"] = {
	},
	["chinese"] = {
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

-- 资源
VEGGIES =
{
	wheat = {
		seed_weight = COMMON,
		health = HP * 1,
		hunger = HU * 12.5,
		sanity = SAN * 0,
		perishtime = PER * 30,
		cooked_health = HP * 5,
		cooked_hunger = hunger * 25,
		cooked_sanity = SAN * 0,
		cooked_perishtime = PER * 5,
	},
	--[[onion = {
		seed_weight = COMMON,
		health = HP * 5,
		hunger = HU * 12.5,
		sanity = SAN * 0,
		perishtime = PER * 30,
		cooked_health = HP * 5,
		cooked_hunger = hunger * 25,
		cooked_sanity = SAN * 5,
		cooked_perishtime = PER * 5,
	},]]
}

-- TODO: Use customize ANIM
-- image seed.xml
-- anim/seeds.zip
-- anim/aip_veggie_name.zip
-- anim/aip_veggie_name_cooked.zip
------------------------------------ 通用 ------------------------------------
local assets_seeds =
{
	Asset("ANIM", "anim/seeds.zip"),
}

local function MakeVeggie(name, has_seeds)

	local assets =
	{
		Asset("ANIM", "anim/aip_veggie_"..name..".zip"),
	}

	local assets_cooked =
	{
		Asset("ANIM", "anim/aip_veggie_"..name..".zip"),
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
		inst.components.inventoryitem.atlasname = "images/inventoryimages/"..name.."_seed.xml"

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

		return inst
	end

	local function fn_cooked()
		local inst = CreateEntity()

		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddNetwork()

		MakeInventoryPhysics(inst)

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
	local veg, cooked, seeds = MakeVeggie(veggiename, veggiename ~= "berries" and veggiename ~= "cave_banana" and veggiename ~= "cactus_meat" and veggiename ~= "berries_juicy")
	table.insert(prefs, veg)
	table.insert(prefs, cooked)
	if seeds then
		table.insert(prefs, seeds)
	end
end

return unpack(prefs)
