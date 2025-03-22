local dev_mode = aipGetModConfig("dev_mode") == "enabled"

local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Travel Boots",
		DESC = "A little cost for going far",
        TELEPORT_NAME = "Teleport Scroll",
        TELEPORT_DESC = "What a hero really needs",
        TELEPORT_REC_DESC = "Teleport to a specified location",
	},
	chinese = {
		NAME = "远行鞋",
		DESC = "一点点代价的旅行",
        TELEPORT_NAME = "传送卷轴",
        TELEPORT_DESC = "英雄真正需要的东西",
        TELEPORT_REC_DESC = "传送到指定位置",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_TRAVEL_BOOTS = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_TRAVEL_BOOTS = LANG.DESC

STRINGS.NAMES.AIP_TELEPORT_SCROLL = LANG.TELEPORT_NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_TELEPORT_SCROLL = LANG.TELEPORT_DESC
STRINGS.RECIPE_DESC.AIP_TELEPORT_SCROLL = LANG.TELEPORT_REC_DESC

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_travel_boots.zip"),
	Asset("ATLAS", "images/inventoryimages/aip_travel_boots.xml"),
    Asset("ANIM", "anim/aip_​teleport_scroll​.zip"),
	Asset("ATLAS", "images/inventoryimages/aip_​teleport_scroll​.xml"),
}

-------------------------------- 使用 --------------------------------
local CD = dev_mode and 2 or (TUNING.TOTAL_DAY_TIME * 1)
local HEALTH_TARGET = 1

local function canBeActOn(inst, doer)
	return inst ~= nil and inst:HasTag("aip_charged")
end

local function onDoCommonAction(inst, doer, data, callback)
    if not inst.components.rechargeable:IsCharged() then
		return
	end

    -- 有坐标就传送
    if data and data.pos then
        aipSpawnPrefab(doer, "aip_shadow_wrapper").DoShow()

        local x, y, z = data.pos:Get()
        doer.Physics:Teleport(x, 0, z)
        doer:Hide()

        inst.components.rechargeable:Discharge(CD)

        if callback then
            callback()
        end

        doer:DoTaskInTime(0.6, function()
            doer:Show()
            aipSpawnPrefab(doer, "aip_shadow_wrapper").DoShow()
        end)
    end
end

local function onDoTravelAction(inst, doer, data)
    onDoCommonAction(inst, doer, data, function()
        -- 设置当前生命值
        if doer.components.health then
            doer.components.health:SetVal(HEALTH_TARGET)
            doer.components.health:DoDelta(0)
        end
    end)
end

local function onDoTeleportAction(inst, doer, data)
    onDoCommonAction(inst, doer, data, function()
        -- 消耗一份卷轴
        aipRemove(inst)
    end)
end

-------------------------------- 充能 --------------------------------
local function onDischarged(inst)
	inst:RemoveTag("aip_charged")
end

local function onCharged(inst)
	inst:AddTag("aip_charged")
end

-------------------------------- 实例 --------------------------------
local function commonFn(anim, onDoAction)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank(anim)
    inst.AnimState:SetBuild(anim)
    inst.AnimState:PlayAnimation("idle")

    MakeInventoryFloatable(inst, "med", 0.3, 1)

    inst:AddComponent("aipc_action_client")
	inst.components.aipc_action_client.canBeActOn = canBeActOn

    inst:AddTag("aip_charged")
    inst:AddTag("aip_map_action") -- Make the non-map action pull up the map instead.

    -- inst.valid_map_actions = {
    --     [ACTIONS.AIPC_BE_ACTION] = true,
    -- }

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
    inst.components.inventoryitem.atlasname = "images/inventoryimages/"..anim..".xml"

    MakeHauntableLaunch(inst)

    return inst
end

-------------------------------- 飞鞋 --------------------------------
local function travel_boots_fn()
    return commonFn("aip_travel_boots", onDoTravelAction)
end

-------------------------------- 传送 --------------------------------
local function teleport_scroll​_fn()
    local inst commonFn("aip_​teleport_scroll​", onDoTeleportAction)

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_MEDITEM

    return inst
end

return Prefab("aip_travel_boots", travel_boots_fn, assets),
    Prefab("aip_​teleport_scroll​", teleport_scroll​_fn, assets)
