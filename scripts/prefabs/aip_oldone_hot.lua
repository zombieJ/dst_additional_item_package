local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Fate Statue",
		DESC = "He seems to hot",
	},
	chinese = {
		NAME = "化缘石像",
		DESC = "他看起来很热",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_OLDONE_HOT = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_HOT = LANG.DESC

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_oldone_hot.zip"),
}

------------------------------ 事件 ------------------------------
local function onWorldState(inst, season)
    if season ~= "summer" then
        aipReplacePrefab(inst, "aip_shadow_wrapper").DoShow()
    end
end

local function validteFood(food)
    return food ~= nil and food.components.edible ~= nil and food.components.edible.temperaturedelta < 0
end

local function ShouldAcceptItem(inst, item)
    return validteFood(item)
end

local function OnGetItemFromPlayer(inst, giver, item)
    if validteFood(item) then
        aipRemove(item)
        inst:RemoveComponent("trader")

        if giver ~= nil and giver.components.aipc_oldone ~= nil then
            giver.components.aipc_oldone:DoDelta(item.prefab == "ice" and 1 or 2)
        end

        inst.AnimState:PlayAnimation("smile")
        inst:ListenForEvent("animover", function()
            aipReplacePrefab(inst, "aip_shadow_wrapper").DoShow()
        end)
    end
end

------------------------------ 实例 ------------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 0.2, 0.5)

    inst.AnimState:SetBank("aip_oldone_hot")
    inst.AnimState:SetBuild("aip_oldone_hot")
    inst.AnimState:PlayAnimation("idle")

    local scale = 0.6
    inst.Transform:SetScale(scale, scale, scale)

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

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

    inst:WatchWorldState("season", onWorldState)

    inst.persists = false

    return inst
end

return Prefab("aip_oldone_hot", fn, assets)
