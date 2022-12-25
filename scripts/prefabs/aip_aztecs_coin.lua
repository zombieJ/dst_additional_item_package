local dev_mode = aipGetModConfig("dev_mode") == "enabled"

local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Aztecs Coin",
		DESC = "Cursed gold coin",
	},
	chinese = {
		NAME = "阿兹特克金币",
		DESC = "受到诅咒的金币",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_AZTECS_COIN = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_AZTECS_COIN = LANG.DESC

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_aztecs_coin.zip"),
	Asset("ATLAS", "images/inventoryimages/aip_aztecs_coin.xml"),
}

-------------------------------- 使用 --------------------------------
local CD = dev_mode and 10 or (TUNING.TOTAL_DAY_TIME * 3)

local function canBeActOn(inst, doer)
	return inst ~= nil and inst:HasTag("aip_charged")
end

local function onDoAction(inst, doer)
    if not inst.components.rechargeable:IsCharged() then
		return
	end

    aipFlingItem(aipSpawnPrefab(doer, "goldnugget"))
    inst.components.rechargeable:Discharge(CD)

    -- 损失生命上限就是代价
    if doer.components.health ~= nil then
        doer.components.health:DeltaPenalty(0.01)
    end
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

    inst.AnimState:SetBank("aip_aztecs_coin")
    inst.AnimState:SetBuild("aip_aztecs_coin")
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
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_aztecs_coin.xml"

	inst:AddComponent("tradable")
	inst.components.tradable.goldvalue = 1

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("aip_aztecs_coin", fn, assets)
