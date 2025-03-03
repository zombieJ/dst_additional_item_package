local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Magic Duck",
		DESC = "Empower your weapon",
	},
	chinese = {
		NAME = "小黄鸭",
		DESC = "让武器熠熠生辉",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_SNAKEOIL = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_SNAKEOIL = LANG.DESC

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_snakeoil.zip"),
	Asset("ATLAS", "images/inventoryimages/aip_snakeoil.xml"),
}

-----------------------------------------------------------
local function canActOn(inst, doer, target)
	-- return target and target.components.weapon ~= nil and target.components.aipc_snakeoil ~= nil
    return target and target:HasTag("aip_snakeoil_target")
end

local function onDoTargetAction(inst, doer, target)
	if target and target.components.aipc_snakeoil then
        local ability = target.components.aipc_snakeoil:RandomAbility()
    end
	aipRemove(inst)
end

-----------------------------------------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("aip_snakeoil")
    inst.AnimState:SetBuild("aip_snakeoil")
    inst.AnimState:PlayAnimation("idle")

    MakeInventoryFloatable(inst, "med", nil, 0.68)

    inst.entity:SetPristine()

    inst:AddComponent("aipc_action_client")
	inst.components.aipc_action_client.canActOn = canActOn

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("aipc_action")
	inst.components.aipc_action.onDoTargetAction = onDoTargetAction

    inst:AddComponent("inspectable")
    
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_snakeoil.xml"

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_MEDITEM

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("aip_snakeoil", fn, assets)
