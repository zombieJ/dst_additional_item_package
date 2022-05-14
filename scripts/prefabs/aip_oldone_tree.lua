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
local function onWork(inst)
end

local function onFinish(inst)
end

------------------------------------ 实体 ------------------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("aip_oldone_tree")
    inst.AnimState:SetBuild("aip_oldone_tree")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("aip_olden_flower")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.CHOP)
    inst.components.workable:SetWorkLeft(1)
    inst.components.workable:SetOnWorkCallback(onWork)
    inst.components.workable:SetOnFinishCallback(onFinish)

    inst:AddComponent("hauntable")
    MakeLargeBurnable(inst, TUNING.TREE_BURN_TIME)
    MakeMediumPropagator(inst)

    inst.persists = false

    return inst
end

return Prefab("aip_oldone_tree", fn, assets)
