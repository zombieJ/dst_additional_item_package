local language = aipGetModConfig("language")

local LANG_MAP = {
	english = {
		NAME = "Phoenix Feather",
		DESC = "Protects from heat damage",
	},
	chinese = {
		NAME = "凤凰羽毛",
		DESC = "可以抵挡高温伤害",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_PHOENIX_FEATHER = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_PHOENIX_FEATHER = LANG.DESC

local assets = {
	Asset("ANIM", "anim/aip_phoenix_feather.zip"),
	Asset("ATLAS", "images/inventoryimages/aip_phoenix_feather.xml"),
}

local function onHealthDelta(owner, data)
	if data ~= nil and data.cause == "hot" then
		data.amount = 0
	end
end

local function onPickup(inst, data)
	local owner = data.owner
	inst._owner = owner
	owner:ListenForEvent("aip_healthdelta", onHealthDelta)
end

local function onDrop(inst)
	local owner = inst._owner
	if owner then
		owner:RemoveEventCallback("aip_healthdelta", onHealthDelta)
		inst._owner = nil
	end
end

local function onRemove(inst)
	local owner = inst._owner
	if owner then
		owner:RemoveEventCallback("aip_healthdelta", onHealthDelta)
	end
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)

	inst.AnimState:SetBank("feather_crow")
	inst.AnimState:SetBuild("feather_crow")
	inst.AnimState:PlayAnimation("idle")

	inst:AddTag("cattoy")
	inst:AddTag("birdfeather")

	MakeInventoryFloatable(inst, "small", 0.05, 0.95)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("inspectable")

	MakeHauntableLaunchAndIgnite(inst)

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_phoenix_feather.xml"
	inst.components.inventoryitem.nobounce = true

	inst:ListenForEvent("onpickup", onPickup)
	inst:ListenForEvent("ondropped", onDrop)

	inst.OnRemoveEntity = onRemove

	return inst
end

return Prefab("aip_phoenix_feather", fn, assets)
