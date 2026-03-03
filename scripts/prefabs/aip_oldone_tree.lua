local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Dense Tree",
		DESC = "Seems like a lightning needle",
	},
	chinese = {
		NAME = "旺盛的树",
		DESC = "它的枝干好像避雷针",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_OLDONE_TREE = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_TREE = LANG.DESC

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_oldone_tree.zip"),
}

------------------------------------ 事件 ------------------------------------
local function doRemove(inst)
    inst:RemoveTag("lightningrod")

    inst.AnimState:PlayAnimation("dead")
    inst:DoTaskInTime(2, function()
        ErodeAway(inst, 0.5)
    end)

    inst:RemoveComponent("workable")
    inst:RemoveComponent("burnable")

    inst.SoundEmitter:PlaySound("dontstarve/forest/treeCrumble")
end

local function onFinish(inst, doer)
    doRemove(inst)

    -- 增加一点谜团因子
    if doer ~= nil and doer.components.aipc_oldone ~= nil then
        doer.components.aipc_oldone:DoDelta(1)
    end
end

-- 雷击
local function onlightning(inst)
    doRemove(inst)

    -- 增加模因因子
    local players = aipFindNearPlayers(inst, 8)
    for i, player in ipairs(players) do
        if player ~= nil and player.components.aipc_oldone ~= nil then
            player.components.aipc_oldone:DoDelta(2)
        end
    end
end

------------------------------------ 实体 ------------------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, .2)

    inst.AnimState:SetBank("aip_oldone_tree")
    inst.AnimState:SetBuild("aip_oldone_tree")
    inst.AnimState:PlayAnimation("idle", true)
    
    local scale = 1.5
    inst.Transform:SetScale(scale, scale, scale)

    inst:AddTag("aip_olden_flower")
    inst:AddTag("lightningrod")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:ListenForEvent("lightningstrike", onlightning)

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.CHOP)
    inst.components.workable:SetWorkLeft(1)
    inst.components.workable:SetOnFinishCallback(onFinish)

    inst:AddComponent("hauntable")
    MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
    MakeMediumPropagator(inst)

    inst.persists = false

    return inst
end

return Prefab("aip_oldone_tree", fn, assets)
