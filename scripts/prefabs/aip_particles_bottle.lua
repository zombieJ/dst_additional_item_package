local dev_mode = aipGetModConfig("dev_mode") == "enabled"
local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Particle Limiter",
        CHARGED = "Particle Limiter (Changed)",
		DESC = "Save the particle for a long time",
        DESC_CHARGED = "There is a turbulent energy in it",
	},
	chinese = {
		NAME = "粒子限制器",
        CHARGED = "粒子限制器（充能）",
		DESC = "将粒子可以长久保存",
        DESC_CHARGED = "里面蕴藏着一份躁动的能量",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_PARTICLES_BOTTLE = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_PARTICLES_BOTTLE = LANG.DESC
STRINGS.NAMES.AIP_PARTICLES_BOTTLE_CHARGED = LANG.CHARGED
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_PARTICLES_BOTTLE_CHARGED = LANG.DESC_CHARGED

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_particles_bottle.zip"),
	Asset("ATLAS", "images/inventoryimages/aip_particles_bottle.xml"),
    Asset("ATLAS", "images/inventoryimages/aip_particles_bottle_charged.xml"),
}

----------------------------------- 方法 -----------------------------------
local function canActOn(inst, doer, target)
	return target.prefab == "aip_particles"
end

local function onDoTargetAction(inst, doer, target)
	if target.prefab == "aip_particles" then
        aipRemove(target)
        aipReplacePrefab(inst, "aip_particles_bottle_charged")
    end
end

----------------------------------- 通用 -----------------------------------
local function common()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("aip_particles_bottle")
    inst.AnimState:SetBuild("aip_particles_bottle")
    inst.AnimState:PlayAnimation("idle")

    inst.Light:SetFalloff(0.7)
    inst.Light:SetIntensity(.5)
    inst.Light:SetRadius(0.5)
    inst.Light:SetColour(237/255, 237/255, 209/255)
    inst.Light:Enable(false)

    MakeInventoryFloatable(inst, "med", 0.3, 1)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

	inst:AddComponent("inventoryitem")

    MakeHauntableLaunch(inst)

    return inst
end

----------------------------------- 置空 -----------------------------------
local function emptyFn()
    local inst = common()

    inst:AddComponent("aipc_action_client")
	inst.components.aipc_action_client.canActOn = canActOn

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_particles_bottle.xml"

    inst:AddComponent("aipc_action")
	inst.components.aipc_action.onDoTargetAction = onDoTargetAction

    return inst
end

----------------------------------- 充能 -----------------------------------
local function fullFn()
    local inst = common()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_particles_bottle_charged.xml"

    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(dev_mode and 10 or TUNING.PERISH_FAST)
    inst.components.perishable:StartPerishing()
    inst.components.perishable.onperishreplacement = "aip_particles_bottle"

    return inst
end



return  Prefab("aip_particles_bottle", emptyFn, assets),
        Prefab("aip_particles_bottle_charged", fullFn, assets)
