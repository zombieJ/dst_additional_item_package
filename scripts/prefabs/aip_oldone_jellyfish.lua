local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Hunger Jellyfish",
		DESC = "What is the food of it? Kelp?",
        WARN_NAME = "Thermostatic Jellyfish",
		WARN_DESC = "Reliable Thermostat Companion",
	},
	chinese = {
		NAME = "饥饿水母",
		DESC = "水母的食物是什么来着？海带么？",
        WARN_NAME = "恒温水母",
		WARN_DESC = "可靠的恒温伴侣",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_OLDONE_JELLYFISH = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_JELLYFISH = LANG.DESC
STRINGS.NAMES.AIP_OLDONE_JELLYFISH_STONE = LANG.WARN_NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_JELLYFISH_STONE = LANG.WARN_DESC

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_oldone_jellyfish.zip"),
    Asset("ATLAS", "images/inventoryimages/aip_oldone_jellyfish_cold.xml"),
    Asset("ATLAS", "images/inventoryimages/aip_oldone_jellyfish_hot.xml"),
}

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

------------------------------ 暖石 ------------------------------
local function HeatFn(inst, observer)
    local worldTemp = TheWorld.state.temperature
    local myHeat = worldTemp

    if worldTemp > 60 then
        myHeat = 10
    elseif worldTemp < 10 then
        myHeat = 60
    end

    return myHeat
end

local function stoneFn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst:AddTag("heatrock")

    --HASHEATER (from heater component) added to pristine state for optimization
    inst:AddTag("HASHEATER")

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst, "small", 0.2)

    inst.AnimState:SetBank("aip_oldone_jellyfish")
    inst.AnimState:SetBuild("aip_oldone_jellyfish")
    inst.AnimState:PlayAnimation("open", true)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_oldone_jellyfish.xml"
    inst.components.inventoryitem.imagename = "aip_oldone_jellyfish"

    inst:AddComponent("heater")
    inst.components.heater.heatfn = HeatFn
    inst.components.heater.carriedheatfn = HeatFn
    inst.components.heater.carriedheatmultiplier = TUNING.HEAT_ROCK_CARRIED_BONUS_HEAT_FACTOR

    MakeHauntableLaunch(inst)

    return inst
end

return  Prefab("aip_oldone_jellyfish", fn, assets),
        Prefab("aip_oldone_jellyfish_stone", stoneFn, assets)
