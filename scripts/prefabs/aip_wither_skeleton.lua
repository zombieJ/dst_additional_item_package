local dev_mode = aipGetModConfig("dev_mode") == "enabled"
local language = aipGetModConfig("language")

local LANG_MAP = {
	english = {
		NAME = "Wither Skeleton",
		DESC = "Endless Coal from AI",
	},
	chinese = {
		NAME = "凋灵骷髅",
		DESC = "AI 提供的无尽煤炭",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_WITHER_SKELETON = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_WITHER_SKELETON = LANG.DESC

local assets = {
    Asset("ANIM", "anim/scorched_skeletons.zip"),
}

local prefabs = {
    "boneshard",
    "collapse_small",
    "ash",
}

local animstates = { 1, 2, 3, 4, 5, 6 }

SetSharedLootTable("aip_wither_skeleton", {
    {"aip_coal", 1.00},
    {"aip_coal", 0.40},
    {"aip_coal", 0.10},
})

local function onhammered(inst)
    inst.components.lootdropper:DropLoot()
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("rock")
    inst:Remove()
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:AddSoundEmitter()

    MakeSmallObstaclePhysics(inst, 0.25)

    inst.AnimState:SetBank("skeleton")
    inst.AnimState:SetBuild("scorched_skeletons")

    inst.animnum = animstates[math.random(#animstates)]
    inst.AnimState:PlayAnimation("idle"..inst.animnum)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    local lootdropper = inst:AddComponent("lootdropper")
    lootdropper:SetChanceLootTable("aip_wither_skeleton")

    local workable = inst:AddComponent("workable")
    workable:SetWorkAction(ACTIONS.HAMMER)
    workable:SetWorkLeft(3)
    workable:SetOnFinishCallback(onhammered)

    inst.persists = false

    return inst
end

return Prefab("aip_wither_skeleton", fn, assets, prefabs)