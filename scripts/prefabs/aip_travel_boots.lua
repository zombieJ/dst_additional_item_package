local dev_mode = aipGetModConfig("dev_mode") == "enabled"

local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Travel Boots",
		DESC = "A little cost for going far",
	},
	chinese = {
		NAME = "远行鞋",
		DESC = "一点点代价的旅行",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_TRAVEL_BOOTS = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_TRAVEL_BOOTS = LANG.DESC

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_travel_boots.zip"),
	Asset("ATLAS", "images/inventoryimages/aip_travel_boots.xml"),
}

-------------------------------- 使用 --------------------------------
local CD = dev_mode and 2 or (TUNING.TOTAL_DAY_TIME * 3)
local HEALTH_DMG = dev_mode and 0.3 or 0.01
local HEALTH_DELTA = 5

local function canBeActOn(inst, doer)
	return inst ~= nil and inst:HasTag("aip_charged")
end

local function onDoAction(inst, doer)
    if not inst.components.rechargeable:IsCharged() then
		return
	end

    aipPrint("Do Server Action")
    -- aipFlingItem(aipSpawnPrefab(doer, "goldnugget"))
    -- inst.components.rechargeable:Discharge(CD)

    -- -- 损失生命上限就是代价
    -- if doer.components.health ~= nil then
    --     doer.components.health:DoDelta(-HEALTH_DELTA)
    --     doer.components.health:DeltaPenalty(HEALTH_DMG)
    -- end
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

    inst.AnimState:SetBank("aip_travel_boots")
    inst.AnimState:SetBuild("aip_travel_boots")
    inst.AnimState:PlayAnimation("idle")

    MakeInventoryFloatable(inst, "med", 0.3, 1)

    inst:AddComponent("aipc_action_client")
	inst.components.aipc_action_client.canBeActOn = canBeActOn

    inst:AddTag("aip_charged")
    inst:AddTag("aip_map_action") -- Make the non-map action pull up the map instead.

    inst.valid_map_actions = {
        [ACTIONS.AIPC_BE_ACTION] = true,
    }

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
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_travel_boots.xml"

	inst:AddComponent("tradable")
	inst.components.tradable.goldvalue = 1

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("aip_travel_boots", fn, assets)
