local language = aipGetModConfig("language")

local LANG_MAP = {
	english = {
		NAME = "Ocean Tear",
		DESC = "It still remembers the tide",
		DRY_NAME = "Dry Ocean Tear",
		DRY_DESC = "It is thirsty for the tide",
	},
	chinese = {
		NAME = "海洋之泪",
		DESC = "它仍记得潮汐",
		DRY_NAME = "干枯的海洋之泪",
		DRY_DESC = "它渴望回到潮汐里",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_OCEAN_TEAR = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OCEAN_TEAR = LANG.DESC
STRINGS.NAMES.AIP_OCEAN_TEAR_DRY = LANG.DRY_NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OCEAN_TEAR_DRY = LANG.DRY_DESC

local assets = {
	Asset("ANIM", "anim/aip_ocean_tear.zip"),
	Asset("ATLAS", "images/inventoryimages/aip_ocean_tear.xml"),
	Asset("ATLAS", "images/inventoryimages/aip_ocean_tear_dry.xml"),
}

local function canBeActOn(inst, doer)
	return inst ~= nil
end

local function onDoAction(inst, doer)
	if inst._aipNextPrefab ~= nil then
		aipReplacePrefab(inst, inst._aipNextPrefab)
	end
end

local function removeMoistureRate(inst)
	if inst._aipMoistureOwner ~= nil and inst._aipMoistureOwner.components.moisture ~= nil then
		inst._aipMoistureOwner.components.moisture:RemoveRateBonus(inst)
	end

	inst._aipMoistureOwner = nil
end

local function getMoistureOwner(inst)
	local owner = inst.components.inventoryitem ~= nil and inst.components.inventoryitem:GetGrandOwner() or nil
	if owner ~= nil and owner:HasTag("player") and owner.components.moisture ~= nil then
		return owner
	end
end

local function updateMoistureRate(inst)
	local owner = getMoistureOwner(inst)

	if owner == inst._aipMoistureOwner then
		return
	end

	removeMoistureRate(inst)

	if owner ~= nil then
		owner.components.moisture:AddRateBonus(inst, inst._aipMoistureDelta or 0)
		inst._aipMoistureOwner = owner
	end
end

local function onPutInInventory(inst)
	inst:DoTaskInTime(0, updateMoistureRate)
end

local function makeFn(anim, image, delta, nextPrefab)
	return function()
		local inst = CreateEntity()

		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddNetwork()

		MakeInventoryPhysics(inst)

		inst.AnimState:SetBank("aip_ocean_tear")
		inst.AnimState:SetBuild("aip_ocean_tear")
		inst.AnimState:PlayAnimation(anim)

		MakeInventoryFloatable(inst, "med", 0.3, 1)

		inst:AddComponent("aipc_action_client")
		inst.components.aipc_action_client.canBeActOn = canBeActOn

		inst.entity:SetPristine()

		if not TheWorld.ismastersim then
			return inst
		end

		inst._aipMoistureDelta = delta
		inst._aipNextPrefab = nextPrefab

		inst:AddComponent("aipc_action")
		inst.components.aipc_action.onDoAction = onDoAction

		inst:AddComponent("inspectable")

		inst:AddComponent("inventoryitem")
		inst.components.inventoryitem.atlasname = "images/inventoryimages/"..image..".xml"
		inst.components.inventoryitem.imagename = image

		inst:AddComponent("tradable")
		inst.components.tradable.goldvalue = 1

		inst:ListenForEvent("onputininventory", onPutInInventory)
		inst:ListenForEvent("ondropped", removeMoistureRate)
		inst:DoPeriodicTask(1, updateMoistureRate)

		inst.OnRemoveEntity = removeMoistureRate

		MakeHauntableLaunch(inst)

		return inst
	end
end

return Prefab(
	"aip_ocean_tear",
	makeFn("idle", "aip_ocean_tear", 3, "aip_ocean_tear_dry"),
	assets
), Prefab(
	"aip_ocean_tear_dry",
	makeFn("dry", "aip_ocean_tear_dry", -3, "aip_ocean_tear"),
	assets
)
