local foldername = KnownModIndex:GetModActualName(TUNING.ZOMBIEJ_ADDTIONAL_PACKAGE)

-- 配置
local additional_food = GetModConfigData("additional_food", foldername)
local language = GetModConfigData("language", foldername)

if additional_food ~= "open" then
	return nil
end

local LANG_MAP = {
	["english"] = {
		["EGG_PANCAKE"] = {
			["NAME"] = "Egg Pancake",
			["DESC"] = "Too many eggs!",
		},
	},
	["chinese"] = {
		["EGG_PANCAKE"] = {
			["NAME"] = "鸡蛋灌饼",
			["DESC"] = "天呐，满满都是蛋！",
		},
	},
}

local LANG = LANG_MAP[language]

-- 资源
local prefabList = {}
local prefabs =
{
	"spoiled_food",
}

-- 配方
local food_recipes = {
	egg_pancake = {
		test = function(cooker, names, tags) return tags.egg and tags.egg >= 3 and not tags.inedible end,
		priority = 1,
		weight = 1,
		foodtype = FOODTYPE.MEAT,
		health = TUNING.HEALING_MED,
		hunger = TUNING.CALORIES_HUGE,
		sanity = TUNING.SANITY_SMALL,
		perishtime = TUNING.PERISH_FAST,
		cooktime = 2 / 20,
	},
}

cookerrecipes = {
	cookpot = food_recipes,
}

--------------------------------------------------
for name,data in pairs(food_recipes) do
	-- 预处理
	data.name = name
	data.weight = data.weight or 1
	data.priority = data.priority or 0

	-- 添加文字
	local upperCase = string.upper(name)
	STRINGS.NAMES[upperCase] = LANG[upperCase].NAME
	STRINGS.CHARACTERS.GENERIC.DESCRIBE[upperCase] = LANG[upperCase].DESC

	-- 添加食物
	AddModPrefabCookerRecipe("cookpot", data)

	-------------------- 创建食物实体 --------------------
	local assets = {
		Asset("ATLAS", "images/inventoryimages/"..data.name..".xml"),
		Asset("IMAGE", "images/inventoryimages/"..data.name..".tex"),
		Asset("ANIM", "anim/"..data.name..".zip"),
	}

	function fn()
		local inst = CreateEntity()

		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddNetwork()

		MakeInventoryPhysics(inst)

		inst.AnimState:SetBuild(data.name)
		inst.AnimState:SetBank(data.name)
		inst.AnimState:PlayAnimation("BUILD", false)

		inst:AddTag("preparedfood")
		if data.tags then
			for i,v in pairs(data.tags) do
				inst:AddTag(v)
			end
		end

		inst.entity:SetPristine()

		if not TheWorld.ismastersim then
			return inst
		end

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

		-- 物品栏
		inst:AddComponent("inventoryitem")
		inst.components.inventoryitem.atlasname = "images/inventoryimages/"..data.name..".xml"

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
		inst:AddComponent("tradable")

		------------------------------------------------  

		return inst
	end

	local prefab = Prefab(name, fn, assets, prefabs)
	table.insert(prefabList, prefab)
end



return unpack(prefabList)