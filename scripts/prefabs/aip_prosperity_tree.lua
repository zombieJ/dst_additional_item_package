local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Prosperity Tree",
		DESC = "Offer Is Take",
	},
	chinese = {
		NAME = "繁荣之树",
		DESC = "供奉即索取",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_PROSPERITY_TREE = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_PROSPERITY_TREE = LANG.DESC

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_prosperity_tree.zip"),
}

------------------------------------ 事件 ------------------------------------
local PLANT_DEFS = require("prefabs/farm_plant_defs").PLANT_DEFS

-- 给予（只接受可以种植的）
local function canBeGiveOn(inst, doer, item)
    return PLANT_DEFS[item.prefab] ~= nil
end

local function onDoGiveAction(inst, doer, item)
    local clone = aipSpawnPrefab(inst, item.prefab)
    aipRemove(item)

    if clone.Follower == nil then
        clone.entity:AddFollower()
    end

    local scale = 0.65
    clone.Transform:SetScale(scale, scale, scale)

    clone:AddTag("fx")
    clone:AddTag("NOCLICK")
    clone.persists = false
    clone.Follower:FollowSymbol(inst.GUID, "item_one", 0, 0, 0.1)
end

------------------------------------ 实体 ------------------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, .2)

    inst.AnimState:SetBank("aip_prosperity_tree")
    inst.AnimState:SetBuild("aip_prosperity_tree")
    inst.AnimState:PlayAnimation("idle", true)

    inst:AddComponent("aipc_action_client")
    inst.components.aipc_action_client.canBeGiveOn = canBeGiveOn

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    -- 可以接受物品
    inst:AddComponent("aipc_action")
    inst.components.aipc_action.onDoGiveAction = onDoGiveAction

    -- inst:AddComponent("workable")
    -- inst.components.workable:SetWorkAction(ACTIONS.CHOP)
    -- inst.components.workable:SetWorkLeft(1)
    -- inst.components.workable:SetOnFinishCallback(onFinish)

    inst:AddComponent("hauntable")
    MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
    MakeMediumPropagator(inst)

    return inst
end

return Prefab("aip_prosperity_tree", fn, assets)
