local foldername = KnownModIndex:GetModActualName(TUNING.ZOMBIEJ_ADDTIONAL_PACKAGE)

------------------------------------ 配置 ------------------------------------
-- 食物
local additional_food = aipGetModConfig("additional_food")
if additional_food ~= "open" then
	return nil
end

local veggiesList = require("prefabs/aip_veggies_list")
local CUSTOM_VEGGIES = veggiesList.VEGGIES
local CUSTOM_PLANT_DEFS = veggiesList.VEGGIE_DEFS

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
for veggiename, veggiedata in pairs(CUSTOM_VEGGIES) do
	local wrapName = "aip_"..veggiename

	-- 属性
	VEGGIES[wrapName] = {
		health = HP * veggiedata.health,
		hunger = HU * veggiedata.hunger,
		sanity = SAN * veggiedata.sanity,
		perishtime = PER * veggiedata.perishtime,

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

	-- 《种瓜得瓜》兼容
	STRINGS.NAMES.["KNOWN_"..upperCase_seeds] = STRINGS.NAMES[upperCase_seeds]
end

------------------------------------ 通用 ------------------------------------
local OVERSIZED_PHYSICS_RADIUS = 0.1
local OVERSIZED_MAXWORK = 1
local OVERSIZED_PERISHTIME_MULT = 4

local assets_seeds =
{
    Asset("ANIM", "anim/seeds.zip"),
    Asset("ANIM", "anim/farm_plant_seeds.zip"),
}

local prefabs_seeds =
{
    "plant_normal_ground",
    "seeds_placer",
}

-- 是否可以种植
local function can_plant_seed(inst, pt, mouseover, deployer)
	local x, z = pt.x, pt.z
	return TheWorld.Map:CanTillSoilAtPoint(x, 0, z, true)
end

-- 沃姆伍德独有的部署植物能力
local function OnDeploy(inst, pt, deployer)
    local plant = SpawnPrefab(inst.components.farmplantable.plant)
    plant.Transform:SetPosition(pt.x, 0, pt.z)
	plant:PushEvent("on_planted", {in_soil = false, doer = deployer, seed = inst})
    TheWorld.Map:CollapseSoilAtPoint(pt.x, 0, pt.z)
    inst:Remove()

--[[
	看起来动效是不带泥土的，神奇
    local plant = SpawnPrefab("plant_normal_ground")
    plant.components.crop:StartGrowing(inst.components.plantable.product, inst.components.plantable.growtime)
    plant.Transform:SetPosition(pt.x, 0, pt.z)
    plant.SoundEmitter:PlaySound("dontstarve/wilson/plant_seeds")
    inst:Remove()
]]
end

-- 计算巨大化的重量
local function oversized_calcweightcoefficient(name)
    if CUSTOM_PLANT_DEFS[name].weight_data[3] ~= nil and math.random() < CUSTOM_PLANT_DEFS[name].weight_data[3] then
        return (math.random() + math.random()) / 2
    else
        return math.random()
    end
end

-- 背起巨大化
local function oversized_onequip(inst, owner)
    if CUSTOM_PLANT_DEFS[inst._base_name].build ~= nil then
        owner.AnimState:OverrideSymbol("swap_body", CUSTOM_PLANT_DEFS[inst._base_name].build, "swap_body")
    else
        owner.AnimState:OverrideSymbol("swap_body", "farm_plant_"..inst._base_name, "swap_body")
    end
end

-- 放下巨大化
local function oversized_onunequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_body")
end

-- 敲碎巨大化
local function oversized_onfinishwork(inst, chopper)
    inst.components.lootdropper:DropLoot()
    inst:Remove()
end

-- 点燃巨大化
local function oversized_onburnt(inst)
    inst.components.lootdropper:DropLoot()
    inst:Remove()
end

-- 掉落巨大化
local function oversized_makeloots(inst, name)
    local product = name
	local seeds = name.."_seeds"
    return {product, product, seeds, seeds, math.random() < 0.75 and product or seeds}
end

-- 巨大化腐败
local function oversized_onperish(inst)
    if inst.components.inventoryitem:GetGrandOwner() ~= nil then
        local loots = {}
        for i=1, #inst.components.lootdropper.loot do
            table.insert(loots, "spoiled_food")
        end
        inst.components.lootdropper:SetLoot(loots)
        inst.components.lootdropper:DropLoot()
    else
        SpawnPrefab(inst.prefab.."_rotten").Transform:SetPosition(inst.Transform:GetWorldPosition())
    end

    inst:Remove()
end

-- 获取种子名称
local function Seed_GetDisplayName(inst)
	local registry_key = inst.plant_def.product

	local plantregistryinfo = inst.plant_def.plantregistryinfo
	return (ThePlantRegistry:KnowsSeed(registry_key, plantregistryinfo) and ThePlantRegistry:KnowsPlantName(registry_key, plantregistryinfo)) and STRINGS.NAMES["KNOWN_"..string.upper(inst.prefab)] 
			or nil
end

-- 保存巨大化
local function Oversized_OnSave(inst, data)
	data.from_plant = inst.from_plant or false
    data.harvested_on_day = inst.harvested_on_day
end

-- 加载巨大化
local function Oversized_OnPreLoad(inst, data)
	inst.from_plant = (data and data.from_plant) ~= false
	if data ~= nil then
        inst.harvested_on_day = data.harvested_on_day
	end
end

-- 显示形容词（打过蜡）
local function displayadjectivefn(inst)
    return STRINGS.UI.HUD.WAXED
end

-- 用蜂蜡打蜡
local function dowaxfn(inst, doer, waxitem)
    local waxedveggie = SpawnPrefab(inst.prefab.."_waxed")
    if doer.components.inventory and doer.components.inventory:IsHeavyLifting() and doer.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY) == inst then
        doer.components.inventory:Unequip(EQUIPSLOTS.BODY)
        doer.components.inventory:Equip(waxedveggie)
    else       
        waxedveggie.Transform:SetPosition(inst.Transform:GetWorldPosition())
        waxedveggie.AnimState:PlayAnimation("wax_oversized", false)
        waxedveggie.AnimState:PushAnimation("idle_oversized")
    end
    inst:Remove()
    return true
end

-- 一连串打蜡的特效
local PlayWaxAnimation

local function CancelWaxTask(inst)
	if inst._waxtask ~= nil then
		inst._waxtask:Cancel()
		inst._waxtask = nil
	end
end

local function StartWaxTask(inst)
	if not inst.inlimbo and inst._waxtask == nil then
		inst._waxtask = inst:DoTaskInTime(GetRandomMinMax(20, 40), PlayWaxAnimation)
	end
end

PlayWaxAnimation = function(inst)
    inst.AnimState:PlayAnimation("wax_oversized", false)
    inst.AnimState:PushAnimation("idle_oversized")
end

-- 蔬菜本命函数！！！
local function MakeVeggie(name)
    local assets =
    {
        Asset("ANIM", "anim/"..name..".zip"),
        Asset("INV_IMAGE", name),
    }

	table.insert(assets, Asset("ANIM", "anim/oceanfishing_lure_mis.zip"))


    local assets_cooked =
    {
        Asset("ANIM", "anim/"..name..".zip"),
        Asset("INV_IMAGE", name.."_cooked"),
    }

    local prefabs =
    {
        name .."_cooked",
        "spoiled_food",
    }
	local dryable = VEGGIES[name].dryable

	table.insert(prefabs, name.."_seeds")

	local assets_dried = {}
	if dryable ~= nil then
        table.insert(prefabs, name.."_dried")
        table.insert(assets_dried, Asset("ANIM", "anim/"..dryable.build..".zip"))
	end

	local seeds_prefabs = { "farm_plant_"..name }

    local assets_oversized = {}
	table.insert(prefabs, name.."_oversized")
	table.insert(prefabs, name.."_oversized_waxed")
	table.insert(prefabs, name.."_oversized_rotten")
	table.insert(prefabs, "splash_green")
	
	table.insert(assets_oversized, Asset("ANIM", "anim/"..CUSTOM_PLANT_DEFS[name].build..".zip"))


    local function fn_seeds()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)

        inst.AnimState:SetBank("farm_plant_seeds")
        inst.AnimState:SetBuild("farm_plant_seeds")
        inst.AnimState:PlayAnimation(name)
        inst.AnimState:SetRayTestOnBB(true)

        --cookable (from cookable component) added to pristine state for optimization
        inst:AddTag("cookable")
        inst:AddTag("deployedplant")
        inst:AddTag("deployedfarmplant")
		inst:AddTag("oceanfishing_lure")

        inst.overridedeployplacername = "seeds_placer"

		inst.plant_def = CUSTOM_PLANT_DEFS[name]
		inst.displaynamefn = Seed_GetDisplayName

		inst._custom_candeploy_fn = can_plant_seed -- for DEPLOYMODE.CUSTOM

        MakeInventoryFloatable(inst)

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

        inst.components.edible.healthvalue = TUNING.HEALING_TINY / 2
        inst.components.edible.hungervalue = TUNING.CALORIES_TINY

        inst:AddComponent("perishable")
        inst.components.perishable:SetPerishTime(TUNING.PERISH_SUPERSLOW)
        inst.components.perishable:StartPerishing()
        inst.components.perishable.onperishreplacement = "spoiled_food"

        inst:AddComponent("cookable")
        inst.components.cookable.product = "seeds_cooked"

        inst:AddComponent("bait")

	    inst:AddComponent("farmplantable")
	    inst.components.farmplantable.plant = "farm_plant_"..name

         -- deprecated (used for crafted farm structures)
        inst:AddComponent("plantable")
        inst.components.plantable.growtime = TUNING.SEEDS_GROW_TIME
        inst.components.plantable.product = name

         -- deprecated (used for wormwood)
        inst:AddComponent("deployable")
        inst.components.deployable:SetDeployMode(DEPLOYMODE.CUSTOM) -- use inst._custom_candeploy_fn
        inst.components.deployable.restrictedtag = "plantkin"
        inst.components.deployable.ondeploy = OnDeploy

		inst:AddComponent("oceanfishingtackle")
        inst.components.oceanfishingtackle:SetupLure({build = "oceanfishing_lure_mis", symbol = "hook_seeds", single_use = true, lure_data = TUNING.OCEANFISHING_LURE.SEED})
        
        MakeSmallBurnable(inst)
        MakeSmallPropagator(inst)

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

		if dryable ~= nil then
			--dryable (from dryable component) added to pristine state for optimization
			inst:AddTag("dryable")
        end

        MakeInventoryFloatable(inst)

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("edible")
        inst.components.edible.healthvalue = VEGGIES[name].health
        inst.components.edible.hungervalue = VEGGIES[name].hunger
        inst.components.edible.sanityvalue = VEGGIES[name].sanity or 0
        inst.components.edible.foodtype = FOODTYPE.VEGGIE
        inst.components.edible.secondaryfoodtype = VEGGIES[name].secondary_foodtype

        inst:AddComponent("perishable")
        inst.components.perishable:SetPerishTime(VEGGIES[name].perishtime)
        inst.components.perishable:StartPerishing()
        inst.components.perishable.onperishreplacement = "spoiled_food"

        inst:AddComponent("stackable")
		inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

		if dryable ~= nil then
			inst:AddComponent("dryable")
			inst.components.dryable:SetProduct(name.."_dried")
			inst.components.dryable:SetBuildFile(dryable.build)
			inst.components.dryable:SetDryTime(dryable.time)
		end

        inst:AddComponent("inspectable")
        inst:AddComponent("inventoryitem")

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

		MakeInventoryFloatable(inst)

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
        inst.components.edible.secondaryfoodtype = VEGGIES[name].secondary_foodtype

        inst:AddComponent("stackable")
        inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

        inst:AddComponent("inspectable")
        inst:AddComponent("inventoryitem")

        MakeSmallBurnable(inst)
        MakeSmallPropagator(inst)
        ---------------------        

        inst:AddComponent("bait")

        ------------------------------------------------
        inst:AddComponent("tradable")

        MakeHauntableLaunchAndPerish(inst)

        return inst
    end

	local function fn_dried()
		local inst = CreateEntity()

		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddNetwork()

		MakeInventoryPhysics(inst)

		inst.AnimState:SetBank(dryable.build)
		inst.AnimState:SetBuild(dryable.build)
		inst.AnimState:PlayAnimation("dried_"..name)

		MakeInventoryFloatable(inst)

		inst.entity:SetPristine()

		if not TheWorld.ismastersim then
			return inst
		end

		inst:AddComponent("perishable")
		inst.components.perishable:SetPerishTime(dryable.perish)
		inst.components.perishable:StartPerishing()
		inst.components.perishable.onperishreplacement = "spoiled_food"

		inst:AddComponent("edible")
		inst.components.edible.healthvalue = dryable.health or 0
		inst.components.edible.hungervalue = dryable.hunger or 0
		inst.components.edible.sanityvalue = dryable.sanity or 0
		inst.components.edible.foodtype = FOODTYPE.VEGGIE

		inst:AddComponent("stackable")
		inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

		inst:AddComponent("inspectable")
		inst:AddComponent("inventoryitem")

		MakeSmallBurnable(inst)
		MakeSmallPropagator(inst)

		inst:AddComponent("bait")

		inst:AddComponent("tradable")

		MakeHauntableLaunchAndPerish(inst)

		return inst
    end

    local function fn_oversized()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        local plant_def = CUSTOM_PLANT_DEFS[name]

        inst.AnimState:SetBank(plant_def.bank)
        inst.AnimState:SetBuild(plant_def.build)
        inst.AnimState:PlayAnimation("idle_oversized")

        inst:AddTag("heavy")
        inst:AddTag("waxable")
	    inst:AddTag("show_spoilage")

        MakeHeavyObstaclePhysics(inst, OVERSIZED_PHYSICS_RADIUS)
        inst:SetPhysicsRadiusOverride(OVERSIZED_PHYSICS_RADIUS)

        inst._base_name = name

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst.harvested_on_day = inst.harvested_on_day or (TheWorld.state.cycles + 1)

        inst:AddComponent("heavyobstaclephysics")
        inst.components.heavyobstaclephysics:SetRadius(OVERSIZED_PHYSICS_RADIUS)
        inst.components.heavyobstaclephysics:MakeSmallObstacle()

        inst:AddComponent("perishable")
        inst.components.perishable:SetPerishTime(VEGGIES[name].perishtime * OVERSIZED_PERISHTIME_MULT)
        inst.components.perishable:StartPerishing()
        inst.components.perishable.onperishreplacement = nil
        inst.components.perishable:SetOnPerishFn(oversized_onperish)

        inst:AddComponent("inspectable")
        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem.cangoincontainer = false
        inst.components.inventoryitem:SetSinks(true)

        inst:AddComponent("equippable")
        inst.components.equippable.equipslot = EQUIPSLOTS.BODY
        inst.components.equippable:SetOnEquip(oversized_onequip)
        inst.components.equippable:SetOnUnequip(oversized_onunequip)
        inst.components.equippable.walkspeedmult = TUNING.HEAVY_SPEED_MULT

        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
        inst.components.workable:SetOnFinishCallback(oversized_onfinishwork)
        inst.components.workable:SetWorkLeft(OVERSIZED_MAXWORK)

        inst:AddComponent("waxable")
        inst.components.waxable:SetWaxfn(dowaxfn)

        inst:AddComponent("submersible")
        inst:AddComponent("symbolswapdata")
        inst.components.symbolswapdata:SetData(plant_def.build, "swap_body")

        local weight_data = plant_def.weight_data
        inst:AddComponent("weighable")
        inst.components.weighable.type = TROPHYSCALE_TYPES.OVERSIZEDVEGGIES
        inst.components.weighable:Initialize(weight_data.min, weight_data.max)
        local coefficient = oversized_calcweightcoefficient(name)
        inst.components.weighable:SetWeight(Lerp(weight_data[1], weight_data[2], coefficient))

        inst:AddComponent("lootdropper")
        inst.components.lootdropper:SetLoot(oversized_makeloots(inst, name))

        MakeMediumBurnable(inst)
        inst.components.burnable:SetOnBurntFn(oversized_onburnt)
        MakeMediumPropagator(inst)

        MakeHauntableWork(inst)

        inst.from_plant = false

		inst.OnSave = Oversized_OnSave
		inst.OnPreLoad = Oversized_OnPreLoad

        return inst
    end

    local function fn_oversized_waxed()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        local plant_def = CUSTOM_PLANT_DEFS[name]

        inst.AnimState:SetBank(plant_def.bank)
        inst.AnimState:SetBuild(plant_def.build)
        inst.AnimState:PlayAnimation("idle_oversized")

        inst:AddTag("heavy")

        inst.displayadjectivefn = displayadjectivefn
        inst:SetPrefabNameOverride(name.."_oversized")

        MakeHeavyObstaclePhysics(inst, OVERSIZED_PHYSICS_RADIUS)
        inst:SetPhysicsRadiusOverride(OVERSIZED_PHYSICS_RADIUS)

        inst._base_name = name

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("heavyobstaclephysics")
        inst.components.heavyobstaclephysics:SetRadius(OVERSIZED_PHYSICS_RADIUS)
        inst.components.heavyobstaclephysics:MakeSmallObstacle()

        inst:AddComponent("inspectable")
        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem.cangoincontainer = false
        inst.components.inventoryitem:SetSinks(true)

        inst:AddComponent("equippable")
        inst.components.equippable.equipslot = EQUIPSLOTS.BODY
        inst.components.equippable:SetOnEquip(oversized_onequip)
        inst.components.equippable:SetOnUnequip(oversized_onunequip)
        inst.components.equippable.walkspeedmult = TUNING.HEAVY_SPEED_MULT

        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
        inst.components.workable:SetOnFinishCallback(oversized_onfinishwork)
        inst.components.workable:SetWorkLeft(OVERSIZED_MAXWORK)

        inst:AddComponent("submersible")
        inst:AddComponent("symbolswapdata")
        inst.components.symbolswapdata:SetData(plant_def.build, "swap_body")

        inst:AddComponent("lootdropper")
        inst.components.lootdropper:SetLoot({"spoiled_food"})

        MakeMediumBurnable(inst)
        inst.components.burnable:SetOnBurntFn(oversized_onburnt)
        MakeMediumPropagator(inst)

        MakeHauntableWork(inst)

        inst:ListenForEvent("onputininventory", CancelWaxTask)
        inst:ListenForEvent("ondropped", StartWaxTask)
    
        inst.OnEntitySleep = CancelWaxTask
        inst.OnEntityWake = StartWaxTask

        StartWaxTask(inst)

        return inst
    end

    local function fn_oversized_rotten()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        MakeObstaclePhysics(inst, OVERSIZED_PHYSICS_RADIUS)

        local plant_def = CUSTOM_PLANT_DEFS[name]

        inst.AnimState:SetBank(plant_def.bank)
        inst.AnimState:SetBuild(plant_def.build)
        inst.AnimState:PlayAnimation("idle_rot_oversized")

        inst:AddTag("farm_plant_killjoy")
        inst:AddTag("pickable_harvest_str")
		inst:AddTag("pickable")

		inst._base_name = name

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("inspectable")
		inst.components.inspectable.nameoverride = "VEGGIE_OVERSIZED_ROTTEN"

        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
        inst.components.workable:SetOnFinishCallback(oversized_onfinishwork)
        inst.components.workable:SetWorkLeft(OVERSIZED_MAXWORK)

        inst:AddComponent("pickable")
        inst.components.pickable.onpickedfn = inst.Remove
	    inst.components.pickable:SetUp(nil)
		inst.components.pickable.use_lootdropper_for_product = true
	    inst.components.pickable.picksound = "dontstarve/wilson/harvest_berries"

        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem.cangoincontainer = false
		inst.components.inventoryitem.canbepickedup = false
        inst.components.inventoryitem:SetSinks(true)

        inst:AddComponent("lootdropper")
        inst.components.lootdropper:SetLoot(plant_def.loot_oversized_rot)

        MakeMediumBurnable(inst)
        inst.components.burnable:SetOnBurntFn(oversized_onburnt)
        MakeMediumPropagator(inst)

        MakeHauntableWork(inst)

        return inst
    end

    local exported_prefabs = {}

	if has_seeds then
		table.insert(exported_prefabs, Prefab(name.."_seeds", fn_seeds, assets_seeds, seeds_prefabs))
        table.insert(exported_prefabs, Prefab(name.."_oversized", fn_oversized, assets_oversized))
        table.insert(exported_prefabs, Prefab(name.."_oversized_waxed", fn_oversized_waxed, assets_oversized))
        table.insert(exported_prefabs, Prefab(name.."_oversized_rotten", fn_oversized_rotten, assets_oversized))
	end
	if dryable ~= nil then
		table.insert(exported_prefabs, Prefab(name.."_dried", fn_dried, assets_dried))
    end

    table.insert(exported_prefabs, Prefab(name, fn, assets, prefabs))
    table.insert(exported_prefabs, Prefab(name.."_cooked", fn_cooked, assets_cooked))

    return exported_prefabs
end

local prefs = {}
for veggiename,veggiedata in pairs(VEGGIES) do
    local veggies = MakeVeggie(veggiename)
	for _, v in ipairs(veggies) do
		table.insert(prefs, v)
	end
end

return unpack(prefs)
