local dev_mode = aipGetModConfig("dev_mode") == "enabled"

local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Hearthstone",
		DESC = "Return to the safe harbor",
	},
	chinese = {
		NAME = "炉石",
		DESC = "回到安全港",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_HEARTHSTONE = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_HEARTHSTONE = LANG.DESC

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_hearthstone.zip"),
	Asset("ATLAS", "images/inventoryimages/aip_hearthstone.xml"),
}

-------------------------------- 使用 --------------------------------
local CD = dev_mode and 2 or (TUNING.TOTAL_DAY_TIME * 3)

local function canBeActOn(inst, doer)
	return inst ~= nil and inst:HasTag("aip_charged")
end

local function onDoAction(inst, doer)
    if not inst.components.rechargeable:IsCharged() then
		return
	end

    inst.components.rechargeable:Discharge(CD)

    -- 传送走
    aipBufferPatch(inst, doer, "aip_black_portal", 0.001)
end


-------------------------------- 充能 --------------------------------
local function onDischarged(inst)
	inst:RemoveTag("aip_charged")
end

local function onCharged(inst)
	inst:AddTag("aip_charged")
end

-------------------------------- 实例 --------------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("aip_hearthstone")
    inst.AnimState:SetBuild("aip_hearthstone")
    inst.AnimState:PlayAnimation("idle")

    MakeInventoryFloatable(inst, "med", 0.3, 1)

    inst:AddComponent("aipc_action_client")
	inst.components.aipc_action_client.canBeActOn = canBeActOn

    inst:AddTag("aip_charged")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("rechargeable")
	inst.components.rechargeable:SetOnDischargedFn(onDischarged)
	inst.components.rechargeable:SetOnChargedFn(onCharged)

    inst:AddComponent("aipc_action")
	inst.components.aipc_action.onDoAction = onDoAction

    inst:AddComponent("inspectable")
    
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_hearthstone.xml"

	inst:AddComponent("tradable")
	inst.components.tradable.goldvalue = 1

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("aip_hearthstone", fn, assets)
