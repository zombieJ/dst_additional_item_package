local dev_mode = aipGetModConfig("dev_mode") == "enabled"

local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Steel Ball",
		DESC = "Transfer damage energy",
	},
	chinese = {
		NAME = "回旋铁球",
		DESC = "转移伤害能量",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_STEEL_BALL = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_STEEL_BALL = LANG.DESC

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_steel_ball.zip"),
	Asset("ATLAS", "images/inventoryimages/aip_steel_ball.xml"),
}

-------------------------------- 使用 --------------------------------
local CD = dev_mode and 10 or (TUNING.TOTAL_DAY_TIME * 3)

local function canActOnPoint(inst)
	return true
end

local function onHealthDelta(inst)
    aipPrint("Hit!", inst)
end

-- 投掷出去
local function onDoPointAction(inst, doer, targetPos)
    local owner = inst.components.inventoryitem:GetGrandOwner()
    if owner then
        if owner.components.inventory ~= nil then
            owner.components.inventory:DropItem(inst)
        elseif owner.components.container ~= nil then
            owner.components.container:DropItem(inst)
        end
    end

    local pos = Vector3(targetPos.x, 1, targetPos.z)

    inst.AnimState:PlayAnimation("loop", true)
    inst.components.aipc_float:MoveToPoint(pos)

    if doer.components.aipc_steel_ball == nil then
        doer:AddComponent("aipc_steel_ball")
    end
    doer.components.aipc_steel_ball:Register(inst)

    inst._aipDoer = doer
end

local function onPickUp(inst)
    if inst._aipDoer ~= nil and inst._aipDoer.components.aipc_steel_ball ~= nil then
        inst._aipDoer.components.aipc_steel_ball:Unregister(inst)
        inst.AnimState:PlayAnimation("idle")
    end

    inst.components.aipc_float:Stop()
    inst._aipDoer = nil
end

-------------------------------- 实例 --------------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("aip_steel_ball")
    inst.AnimState:SetBuild("aip_steel_ball")
    inst.AnimState:PlayAnimation("idle")

    MakeInventoryFloatable(inst, "med", 0.3, 1)

    inst:AddComponent("aipc_action_client")
	inst.components.aipc_action_client.canActOnPoint = canActOnPoint

    inst:AddTag("aip_charged")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("aipc_float")

    inst:AddComponent("aipc_action")
	inst.components.aipc_action.onDoPointAction = onDoPointAction

    inst:AddComponent("inspectable")
    
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_steel_ball.xml"

	inst:AddComponent("tradable")
	inst.components.tradable.goldvalue = 1

    MakeHauntableLaunch(inst)

    inst:ListenForEvent("onpickup", onPickUp)

    return inst
end

return Prefab("aip_steel_ball", fn, assets)
