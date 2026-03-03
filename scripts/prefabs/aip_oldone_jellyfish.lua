local language = aipGetModConfig("language")
local dev_mode = aipGetModConfig("dev_mode") == "enabled"

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Stranded Jellyfish",
		DESC = "What is the food of it? Kelp?",
        NAME_STONE = "Thermostatic Jellyfish",
		DESC_STONE = "Reliable Thermostat Companion",
        DESC_STONE_HOT = "hot little jellyfish",
        DESC_STONE_COLD = "cool little jellyfish",
	},
	chinese = {
		NAME = "搁浅水母",
		DESC = "水母的食物是什么来着？海带么？",
        NAME_STONE = "恒温水母",
		DESC_STONE = "可靠的恒温伴侣",
        DESC_STONE_HOT = "热热的小水母",
        DESC_STONE_COLD = "凉凉的小水母",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_OLDONE_JELLYFISH = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_JELLYFISH = LANG.DESC
STRINGS.NAMES.AIP_OLDONE_JELLYFISH_STONE = LANG.NAME_STONE
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_JELLYFISH_STONE = LANG.DESC_STONE
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_JELLYFISH_STONE_HOT = LANG.DESC_STONE_HOT
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_JELLYFISH_STONE_COLD = LANG.DESC_STONE_COLD

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_oldone_jellyfish.zip"),
    Asset("ATLAS", "images/inventoryimages/aip_oldone_jellyfish_cold.xml"),
    Asset("ATLAS", "images/inventoryimages/aip_oldone_jellyfish_hot.xml"),
}

-- =======================================================================================
------------------------------ 事件 ------------------------------
local function validteFood(food)
    return food ~= nil and (
        food.prefab == "kelp" or food.prefab == "kelp_cooked" or food.prefab == "kelp_dried"
    )
end

local function ShouldAcceptItem(inst, item)
    return validteFood(item)
end

local function OnGetItemFromPlayer(inst, giver, item)
    if validteFood(item) then
        aipRemove(item)
        inst:RemoveComponent("trader")

        if giver ~= nil and giver.components.aipc_oldone ~= nil then
            giver.components.aipc_oldone:DoDelta(1)
        end

        inst.AnimState:PlayAnimation("turn")
        inst:ListenForEvent("animover", function()
            aipReplacePrefab(inst, "aip_oldone_jellyfish_stone")
        end)
    end
end

------------------------------ 谜团 ------------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("aip_oldone_jellyfish")
    inst.AnimState:SetBuild("aip_oldone_jellyfish")
    inst.AnimState:PlayAnimation("dry")

    inst:AddTag("aip_olden_flower")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("trader")
    inst.components.trader:SetAcceptTest(ShouldAcceptItem)
    inst.components.trader.onaccept = OnGetItemFromPlayer
    inst.components.trader.deleteitemonaccept = false

    MakeHauntableLaunch(inst)

    inst.persists = false

    return inst
end

-- =======================================================================================
------------------------------ 事件 ------------------------------
local function OnGetKelp(inst, giver, item)
    if validteFood(item) then
        aipRemove(item)

        inst.components.perishable:SetPercent(1)
    end
end

------------------------------ 暖石 ------------------------------
local function heatAndSync(inst)
    local worldTemp = TheWorld.state.temperature
    local myHeat = worldTemp
    local status = "hot"

    if worldTemp > 60 then
        myHeat = 10
        status = "cold"
    elseif worldTemp < 10 then
        myHeat = 60
        status = "hot"
    end

    -- 更新贴图
    if status ~= inst._aipStatus then
        if status == "hot" then
            inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_oldone_jellyfish_hot.xml"
            inst.components.inventoryitem:ChangeImageName("aip_oldone_jellyfish_hot")
            inst.AnimState:PlayAnimation("hot", true)
        else
            inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_oldone_jellyfish_cold.xml"
            inst.components.inventoryitem:ChangeImageName("aip_oldone_jellyfish_cold")
            inst.AnimState:PlayAnimation("cold", false)
        end
    end

    inst._aipStatus = status

    return myHeat
end

local function getDesc(inst)
    if inst._aipStatus == "hot" then
        return STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_JELLYFISH_STONE_HOT
    elseif inst._aipStatus == "cold" then
        return STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_JELLYFISH_STONE_COLD
    end

    return STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_JELLYFISH_STONE
end

local function stoneFn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst:AddTag("heatrock")
    inst:AddTag("show_spoilage")

    --HASHEATER (from heater component) added to pristine state for optimization
    inst:AddTag("HASHEATER")

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst, "small", 0.2)

    inst.AnimState:SetBank("aip_oldone_jellyfish")
    inst.AnimState:SetBuild("aip_oldone_jellyfish")
    inst.AnimState:PlayAnimation("hot", true)

    -- MakeFeedableSmallLivestockPristine(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst.components.inspectable.descriptionfn = getDesc

    inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_oldone_jellyfish_hot.xml"
    inst.components.inventoryitem.imagename = "aip_oldone_jellyfish_hot"

    inst:AddComponent("heater")
    inst.components.heater:SetThermics(true, true)
    inst.components.heater.heatfn = heatAndSync
    inst.components.heater.carriedheatfn = heatAndSync
    inst.components.heater.carriedheatmultiplier = TUNING.HEAT_ROCK_CARRIED_BONUS_HEAT_FACTOR

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.MOLE_HEALTH)

    MakeHauntableLaunch(inst)

    -- MakeFeedableSmallLivestock(inst, TUNING.TOTAL_DAY_TIME, nil, nil)

    inst:AddComponent("trader")
    inst.components.trader:SetAcceptTest(ShouldAcceptItem)
    inst.components.trader.onaccept = OnGetKelp
    inst.components.trader.deleteitemonaccept = false

    -- 一天后死亡
    inst:AddComponent("perishable")
    inst.components.perishable:StartPerishing()
    inst.components.perishable:SetPerishTime(dev_mode and 15 or TUNING.TOTAL_DAY_TIME)
    inst.components.perishable.onperishreplacement = "monstermeat"

    inst:AddComponent("lootdropper")
	inst.components.lootdropper:AddChanceLoot("monstermeat", 1)

    inst:DoTaskInTime(0.01, heatAndSync)

    return inst
end

return  Prefab("aip_oldone_jellyfish", fn, assets),
        Prefab("aip_oldone_jellyfish_stone", stoneFn, assets)
