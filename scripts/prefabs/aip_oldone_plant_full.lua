local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "'Fully' Bulb",
		DESC = "Filled with spider silk neurons",
        NO_UPGRADE = "This Spider Den is too strong",
	},
	chinese = {
		NAME = "“完整”的球茎",
		DESC = "其中充满蜘蛛丝状神经元",
        NO_UPGRADE = "这个蜘蛛巢太过强壮了",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_OLDONE_PLANT_FULL = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_PLANT_FULL = LANG.DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_PLANT_NO_UPGRADE = LANG.NO_UPGRADE

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_oldone_plant_full.zip"),
	Asset("ATLAS", "images/inventoryimages/aip_oldone_plant_full.xml"),
}

----------------------------------- 事件 -----------------------------------
-- 附身蜘蛛巢
local function canActOn(inst, doer, target)
	return target.prefab == "spiderden"
end

local function onDoTargetAction(inst, doer, target)
	if target.components.upgradeable ~= nil and target.components.upgradeable.stage == 1 then
        aipReplacePrefab(target, "aip_oldone_spiderden")
        inst.components.stackable:Get():Remove()
        return
    end

    if doer.components.talker ~= nil then
        doer.components.talker:Say(
            STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_PLANT_NO_UPGRADE
        )
    end
end

local function onHit(inst, attacker, target)
    aipReplacePrefab(inst, "aip_aura_poison")
end

----------------------------------- 实体 -----------------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    --projectile (from complexprojectile component) added to pristine state for optimization
    inst:AddTag("projectile")

    inst.AnimState:SetBank("aip_oldone_plant_full")
    inst.AnimState:SetBuild("aip_oldone_plant_full")
    inst.AnimState:PlayAnimation("idle")

    MakeInventoryFloatable(inst, "med", 0.3, 1)

    inst.entity:SetPristine()

    inst:AddComponent("aipc_action_client")
	inst.components.aipc_action_client.canActOn = canActOn

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("aipc_action")
	inst.components.aipc_action.onDoTargetAction = onDoTargetAction

    inst:AddComponent("complexprojectile")
    inst.components.complexprojectile:SetHorizontalSpeed(15)
    inst.components.complexprojectile:SetGravity(-25)
    inst.components.complexprojectile:SetLaunchOffset(Vector3(0, 2.5, 0))
    inst.components.complexprojectile:SetOnHit(onHit)

    inst:AddComponent("inspectable")
    
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_oldone_plant_full.xml"

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_LARGEITEM

    MakeSmallBurnable(inst)
    MakeSmallPropagator(inst)

    MakeHauntableLaunchAndPerish(inst)

    return inst
end

return Prefab("aip_oldone_plant_full", fn, assets)
