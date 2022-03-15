local language = aipGetModConfig("language")
local dev_mode = aipGetModConfig("dev_mode") == "enabled"

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Durian Star",
		DESC = "It's so heavy",
        REC_DESC = "Much more times~",
	},
	chinese = {
		NAME = "“榴”星",
		DESC = "这可真沉呐",
        REC_DESC = "比原版更耐用",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_OLDONE_DURIAN = LANG.NAME
STRINGS.RECIPE_DESC.AIP_OLDONE_DURIAN = LANG.REC_DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_DURIAN = LANG.DESC

TUNING.OLDONE_DURIAN_USES = dev_mode and 3 or 10

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_oldone_durian.zip"),
	Asset("ATLAS", "images/inventoryimages/aip_oldone_durian.xml"),
}

----------------------------------- 事件 -----------------------------------
local function onHit(inst, attacker, target)
    aipSpawnPrefab(inst, "aip_aura_poison")

    inst.AnimState:PlayAnimation("jump")
    inst.AnimState:PushAnimation("idle")

    inst.components.finiteuses:Use(1)
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

    inst.AnimState:SetBank("aip_oldone_durian")
    inst.AnimState:SetBuild("aip_oldone_durian")
    inst.AnimState:PlayAnimation("idle")

    MakeInventoryFloatable(inst, "med", 0.3, 1)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("complexprojectile")
    inst.components.complexprojectile:SetHorizontalSpeed(15)
    inst.components.complexprojectile:SetGravity(-25)
    inst.components.complexprojectile:SetLaunchOffset(Vector3(0, 2.5, 0))
    inst.components.complexprojectile:SetOnHit(onHit)

    inst:AddComponent("inspectable")
    
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_oldone_durian.xml"

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetOnFinished(inst.Remove)
    inst.components.finiteuses:SetMaxUses(TUNING.OLDONE_DURIAN_USES)
    inst.components.finiteuses:SetUses(TUNING.OLDONE_DURIAN_USES)

    MakeSmallBurnable(inst)
    MakeSmallPropagator(inst)

    MakeHauntableLaunchAndPerish(inst)

    return inst
end

return Prefab("aip_oldone_durian", fn, assets)
