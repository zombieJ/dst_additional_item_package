local dev_mode = aipGetModConfig("dev_mode") == "enabled"
local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Particle Limiter",
        CHARGED = "Particle Limiter (Active)",
		DESC = "Save the particle for a long time",
	},
	chinese = {
		NAME = "粒子限制器",
        CHARGED = "粒子限制器（激活）",
		DESC = "将粒子可以长久保存",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_PARTICLES_BOTTLE = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_PARTICLES_BOTTLE = LANG.DESC

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_particles_bottle.zip"),
	Asset("ATLAS", "images/inventoryimages/aip_particles_bottle.xml"),
    Asset("ATLAS", "images/inventoryimages/aip_particles_bottle_charged.xml"),
}

----------------------------------- 方法 -----------------------------------
-- 更新充能状态
local function refreshStatus(inst)
	-- 更新贴图
	if inst._aipCharged then
        inst.components.named:SetName(LANG.CHARGED)
		inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_particles_bottle_charged.xml"
		inst.components.inventoryitem:ChangeImageName("aip_particles_bottle_charged")
		inst.AnimState:PlayAnimation("charged", true)
        inst.Light:Enable(true)
	else
        inst.components.named:SetName(LANG.NAME)
		inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_particles_bottle.xml"
		inst.components.inventoryitem:ChangeImageName("aip_particles_bottle")
		inst.AnimState:PlayAnimation("idle", false)
        inst.Light:Enable(false)

        -- 移除过期组件
        inst:RemoveComponent("perishable")
	end
end

local function syncPerishable(inst)
    if inst.components.perishable == nil and inst._aipCharged then
        inst:AddComponent("perishable")
        inst.components.perishable:SetPerishTime(dev_mode and 10 or TUNING.PERISH_FAST)
        inst.components.perishable:StartPerishing()
        inst.components.perishable.onperishreplacement = "aip_particles_bottle"
    end
end

local function canActOn(inst, doer, target)
	return target.prefab == "aip_particles"
end

local function onDoTargetAction(inst, doer, target)
	if target.prefab == "aip_particles" then
        aipRemove(target)
        inst._aipCharged = true
        syncPerishable(inst)
        refreshStatus(inst)
    end
end

-- 存取
local function onSave(inst, data)
	data._aipCharged = inst.charged
end

local function onLoad(inst, data)
	if data ~= nil then
		inst.charged = data._aipCharged
        syncPerishable(inst)
		refreshStatus(inst)
	end
end

----------------------------------- 实例 -----------------------------------
local function fn()
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

    inst:AddComponent("aipc_action_client")
	inst.components.aipc_action_client.canActOn = canActOn

	inst:AddTag("_named")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:RemoveTag("_named")
    inst:AddComponent("named")

    inst:AddComponent("aipc_action")
	inst.components.aipc_action.onDoTargetAction = onDoTargetAction

    inst:AddComponent("inspectable")

	inst:AddComponent("inventoryitem")
    refreshStatus(inst)


    MakeHauntableLaunch(inst)

    inst.OnLoad = onLoad
    inst.OnSave = onSave

    return inst
end

return Prefab("aip_particles_bottle", fn, assets)
