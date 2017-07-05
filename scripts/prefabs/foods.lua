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
		["MONSTER_SALAD"] = {
			["NAME"] = "Monster Salad",
			["DESC"] = "At least something I can eat",
		},
		["SKUNK_SMOOTHIES"] = {
			["NAME"] = "Skunk Smoothies",
			["DESC"] = "What Is The SMELLLL!",
		},
	},
	["chinese"] = {
		["EGG_PANCAKE"] = {
			["NAME"] = "鸡蛋灌饼",
			["DESC"] = "天呐，满满都是蛋！",
		},
		["MONSTER_SALAD"] = {
			["NAME"] = "怪物沙拉",
			["DESC"] = "至少这东西可以充饥",
		},
		["SKUNK_SMOOTHIES"] = {
			["NAME"] = "臭鼬果昔",
			["DESC"] = "这到底是什么味道！",
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

local HP = TUNING.HEALING_TINY -- 1 healing
local HU = TUNING.CALORIES_HUGE / 75 -- 1 hunger
local SAN = TUNING.SANITY_SUPERTINY -- 1 sanity
local PER = TUNING.PERISH_ONE_DAY -- 1 day
local CO = 1 / 20 -- 1 second

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
			print(">>>"..tostring(names.durian).."-"..tostring(names.durian_cooked).."-"..tostring(tags.frozen).."-"..tostring(tags.fruit))
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