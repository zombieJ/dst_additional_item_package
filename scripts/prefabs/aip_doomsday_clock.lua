local language = aipGetModConfig("language")
local dev_mode = aipGetModConfig("dev_mode") == "enabled"

local LANG_MAP = {
	english = {
		NAME = "Doomsday Clock",
		DESC = "Rewind to a previous state",
	},
	chinese = {
		NAME = "末日时钟",
		DESC = "让我回到过去的状态",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_DOOMSDAY_CLOCK = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_DOOMSDAY_CLOCK = LANG.DESC

local assets = {
	Asset("ANIM", "anim/aip_doomsday_clock.zip"),
	Asset("ATLAS", "images/inventoryimages/aip_doomsday_clock.xml"),
	Asset("IMAGE", "images/inventoryimages/aip_doomsday_clock.tex"),
}


--------------------------------- 方法 -----------------------------------
local RECORD_INTERVAL = 1
local MAX_RECORD_TIME = 5
local COOLDOWN_TIME = dev_mode and 5 or 60

local function recordPlayerState(inst)
	local owner = inst.components.inventoryitem:GetGrandOwner()
	if owner == nil or not owner:HasTag("player") then
		return
	end

	local x, y, z = owner.Transform:GetWorldPosition()

	local state = {
		health = owner.components.health ~= nil and owner.components.health:GetPercent() or nil,
		sanity = owner.components.sanity ~= nil and owner.components.sanity:GetPercent() or nil,
		hunger = owner.components.hunger ~= nil and owner.components.hunger:GetPercent() or nil,
		moisture = owner.components.moisture ~= nil and owner.components.moisture:GetMoisturePercent() or nil,
		x = x,
		z = z,
	}

	inst._aipStateHistory = inst._aipStateHistory or {}
	table.insert(inst._aipStateHistory, state)

	if #inst._aipStateHistory > MAX_RECORD_TIME then
		table.remove(inst._aipStateHistory, 1)
	end
end

local function startRecord(inst)
	if inst._aipRecordTimer ~= nil then
		return
	end

	inst._aipStateHistory = {}
	inst.components.aipc_timer:NamedInterval("record", RECORD_INTERVAL, function()
		recordPlayerState(inst)
	end)
end

local function stopRecord(inst)
	inst.components.aipc_timer:KillName("record")
end

local function onDischarged(inst)
	inst:RemoveTag("aip_charged")
end

local function onCharged(inst)
	inst:AddTag("aip_charged")
end

local function canBeActOn(inst, doer)
	return inst ~= nil and inst:HasTag("aip_charged")
end

local function onUse(inst, doer)
	if not inst.components.rechargeable:IsCharged() then
		return false
	end

	if inst._aipStateHistory == nil or #inst._aipStateHistory == 0 then
		return false
	end

	local oldState = inst._aipStateHistory[1]

	if oldState.health ~= nil and doer.components.health ~= nil then
		doer.components.health:SetPercent(oldState.health)
	end

	if oldState.sanity ~= nil and doer.components.sanity ~= nil then
		doer.components.sanity:SetPercent(oldState.sanity)
	end

	if oldState.hunger ~= nil and doer.components.hunger ~= nil then
		doer.components.hunger:SetPercent(oldState.hunger)
	end

	if oldState.moisture ~= nil and doer.components.moisture ~= nil then
		doer.components.moisture:SetPercent(oldState.moisture)
	end

	if oldState.x ~= nil and oldState.z ~= nil then
		aipSpawnPrefab(doer, "aip_shadow_wrapper").DoShow()

		doer.Transform:SetPosition(oldState.x, 0, oldState.z)

		aipSpawnPrefab(doer, "aip_shadow_wrapper").DoShow()
	end

	inst.components.rechargeable:Discharge(COOLDOWN_TIME)

	return true
end

--------------------------------- 实例 -----------------------------------
local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)

	inst.AnimState:SetBank("aip_doomsday_clock")
	inst.AnimState:SetBuild("aip_doomsday_clock")
	inst.AnimState:PlayAnimation("idle")

	MakeInventoryFloatable(inst, "med", 0.3, 1)

	inst:AddComponent("aipc_action_client")
	inst.components.aipc_action_client.canBeActOn = canBeActOn

	inst:AddTag("aip_charged")

	inst._aipStateHistory = {}

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("inspectable")

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_doomsday_clock.xml"

	inst:AddComponent("aipc_timer")

	inst:AddComponent("rechargeable")
	inst.components.rechargeable:SetOnDischargedFn(onDischarged)
	inst.components.rechargeable:SetOnChargedFn(onCharged)

	inst:AddComponent("aipc_action")
	inst.components.aipc_action.onDoAction = onUse

	inst:ListenForEvent("onputininventory", function(inst, owner)
		startRecord(inst)
	end)

	inst:ListenForEvent("ondropped", function(inst)
		stopRecord(inst)
	end)

	MakeHauntableLaunch(inst)

	inst.OnRemoveEntity = function(inst)
		stopRecord(inst)
	end

	return inst
end

return Prefab("aip_doomsday_clock", fn, assets)
