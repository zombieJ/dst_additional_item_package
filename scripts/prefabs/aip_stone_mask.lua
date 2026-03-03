local dev_mode = aipGetModConfig("dev_mode") == "enabled"

local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Broken Stone Mask",
		DESC = "Broken but still seems scary",
	},
	chinese = {
		NAME = "碎裂石鬼面",
		DESC = "损坏了，但是似乎仍然让人恐惧",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_STONE_MASK = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_STONE_MASK = LANG.DESC

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_stone_mask.zip"),
	Asset("ATLAS", "images/inventoryimages/aip_stone_mask.xml"),
}


-------------------------------- 方法 --------------------------------
local function onDischarged(inst)
	inst:RemoveTag("aip_readable")
end

local function onCharged(inst)
	inst:AddTag("aip_readable")
end

local function canBeActOn(inst, doer)
	return inst:HasTag("aip_readable")
end

local function onDoAction(inst, doer)
    inst.SoundEmitter:PlaySound("dontstarve/creatures/together/klaus/taunt")
    aipSpawnPrefab(doer, "aip_aura_scared")

    inst.components.rechargeable:Discharge(
        dev_mode and 3 or TUNING.SEG_TIME * 10
    ) -- 30s * 10 = 5m

    inst.components.epicscare:Scare(5)
end

-------------------------------- 实例 --------------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("aip_stone_mask")
    inst.AnimState:SetBuild("aip_stone_mask")
    inst.AnimState:PlayAnimation("idle")

    MakeInventoryFloatable(inst, "med", 0.3, 1)

    inst:AddTag("aip_readable")

    inst.entity:SetPristine()

    inst:AddComponent("aipc_action_client")
	inst.components.aipc_action_client.canBeActOn = canBeActOn

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("epicscare")
    inst.components.epicscare:SetRange(TUNING.BEEQUEEN_EPICSCARE_RANGE)

    inst:AddComponent("rechargeable")
	inst.components.rechargeable:SetOnDischargedFn(onDischarged)
	inst.components.rechargeable:SetOnChargedFn(onCharged)

    inst:AddComponent("aipc_action")
	inst.components.aipc_action.onDoAction = onDoAction

    inst:AddComponent("inspectable")
    
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_stone_mask.xml"

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("aip_stone_mask", fn, assets)
