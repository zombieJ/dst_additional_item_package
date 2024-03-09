local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Heal Bulb",
        REC_DESC = "Heal creatures in the area",
		DESC = "Efficient and powerful",
	},
	chinese = {
		NAME = "治愈球茎",
        REC_DESC = "不分敌我的强力治愈范围内的生物",
		DESC = "高效而又强力",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_OLDONE_HEAL = LANG.NAME
STRINGS.RECIPE_DESC.AIP_OLDONE_HEAL = LANG.REC_DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_HEAL = LANG.DESC

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_oldone_heal.zip"),
	Asset("ATLAS", "images/inventoryimages/aip_oldone_heal.xml"),
}

----------------------------------- 方法 -----------------------------------
local function canActOn()
    return true, true
end

local function onDoTargetAction(inst, doer, target)
    if target ~= nil then
        aipRemove(inst)

        local clone = aipSpawnPrefab(doer, "aip_oldone_heal")
        clone.components.complexprojectile:Launch(target:GetPosition(), doer)
    end
end

local function onLaunch(inst)
    inst.AnimState:PlayAnimation("loop", true)
end

-- 范围治疗
local function onHit(inst, attacker, target)
    local effect = aipReplacePrefab(inst, "spider_heal_fx")

    local scale = 1.35
    effect.Transform:SetScale(scale, scale, scale)

    local x, y, z = inst.Transform:GetWorldPosition()
	local ents = TheSim:FindEntities(x, y, z, 3, { "_health" }, { "INLIMBO", "NOCLICK", "ghost" })

    for _, ent in pairs(ents) do
        if ent.components.health ~= nil then
            local ptgHealth = ent.components.health.maxhealth * 0.1
            ent.components.health:DoDelta(ptgHealth + 66, nil, "aip_oldone_heal")
        end
    end

    aipRemove(inst)
end

----------------------------------- 实例 -----------------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("aip_oldone_heal")
    inst.AnimState:SetBuild("aip_oldone_heal")
    inst.AnimState:PlayAnimation("idle")

    MakeInventoryFloatable(inst, "med", 0.3, 1)

    inst:AddComponent("aipc_action_client")
	inst.components.aipc_action_client.canActOn = canActOn

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("aipc_action")
	inst.components.aipc_action.onDoTargetAction = onDoTargetAction

    inst:AddComponent("stackable")
	inst.components.stackable.maxsize = TUNING.STACK_SIZE_MEDITEM

    inst:AddComponent("complexprojectile")
    inst.components.complexprojectile:SetHorizontalSpeed(15)
    inst.components.complexprojectile:SetGravity(-25)
    inst.components.complexprojectile:SetLaunchOffset(Vector3(0, 2.5, 0))
    inst.components.complexprojectile:SetOnLaunch(onLaunch)
    inst.components.complexprojectile:SetOnHit(onHit)

    inst:AddComponent("inspectable")
    
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_oldone_heal.xml"

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("aip_oldone_heal", fn, assets)
