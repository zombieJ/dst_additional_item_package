local dev_mode = aipGetModConfig("dev_mode") == "enabled"

-- 配置
local additional_weapon = aipGetModConfig("additional_weapon")
if additional_weapon ~= "open" then
	return nil
end

local weapon_uses = aipGetModConfig("weapon_uses")
local weapon_damage = aipGetModConfig("weapon_damage")
local language = aipGetModConfig("language")

-- 默认参数
local DAMAGE_MAP = {
	less = TUNING.NIGHTSWORD_DAMAGE / 68 * 22,
	normal = TUNING.NIGHTSWORD_DAMAGE / 68 * 33,
	large = TUNING.NIGHTSWORD_DAMAGE / 68 * 88,
}

local LANG_MAP = {
	english = {
		NAME = "Gholdengo",
		DESC = "Make It Rain",
	},
	chinese = {
		NAME = "赛富豪",
		DESC = "淘金潮",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

TUNING.AIP_GHOLDENGO_DAMAGE = dev_mode and 100 or DAMAGE_MAP[weapon_damage]

-- 资源
local assets = {
	Asset("ATLAS", "images/inventoryimages/aip_gholdengo.xml"),
	Asset("ANIM", "anim/aip_gholdengo.zip"),
	Asset("ANIM", "anim/aip_gholdengo_swap.zip"),
}

local prefabs = {}

-- 文字描述
STRINGS.NAMES.AIP_GHOLDENGO = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_GHOLDENGO = LANG.DESC

-----------------------------------------------------------
local INIT_HEALTH_LIMIT = 100

local function onKill(owner, data)
	local inst = owner._aipGholdengo

	if data and data.victim and data.victim.components.health then
		local totalHealth = data.victim.components.health.maxhealth
		inst._aipTotalDelta = inst._aipTotalDelta + totalHealth

		aipTypePrint("TTL", inst._aipTotalDelta)
		aipTypePrint("STK", inst._aipStackTotal)

		if inst._aipTotalDelta >= inst._aipStackTotal then
			inst._aipTotalDelta = 0
			inst._aipStackTotal = inst._aipStackTotal + 1

			aipFlingItem(aipSpawnPrefab(data.victim, "goldnugget"))
		end
	end
end

local function onequip(inst, owner)
	owner.AnimState:OverrideSymbol("swap_object", "aip_gholdengo_swap", "aip_gholdengo_swap")
	owner.SoundEmitter:PlaySound("dontstarve/wilson/equip_item_gold")
	owner.AnimState:Show("ARM_carry")
	owner.AnimState:Hide("ARM_normal")

	owner:ListenForEvent("killed", onKill)
	owner._aipGholdengo = inst
end

local function onunequip(inst, owner)
	owner.AnimState:ClearOverrideSymbol("swap_object")
	owner.AnimState:Hide("ARM_carry")
	owner.AnimState:Show("ARM_normal")

	owner:RemoveEventCallback("killed", onKill)
	owner._aipGholdengo = nil
end

-----------------------------------------------------------
local function getDesc(inst)
    return STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_GHOLDENGO.."("..inst._aipStackTotal..")"
end

local function onSave(inst, data)
	data._aipTotalDelta = inst._aipTotalDelta
	data._aipStackTotal = inst._aipStackTotal
end

local function onLoad(inst, data)
	if data ~= nil then
		inst._aipTotalDelta = data._aipTotalDelta or 0
		inst._aipStackTotal = data._aipStackTotal or INIT_HEALTH_LIMIT
	end
end

-----------------------------------------------------------
local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()
	
	MakeInventoryPhysics(inst)
	
	inst.AnimState:SetBank("aip_gholdengo")
	inst.AnimState:SetBuild("aip_gholdengo")
	inst.AnimState:PlayAnimation("idle")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(TUNING.AIP_GHOLDENGO_DAMAGE)

	inst:AddComponent("inspectable")
	inst.components.inspectable.descriptionfn = getDesc

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_gholdengo.xml"

	MakeHauntableLaunch(inst)

	inst:AddComponent("equippable")
	inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)

	inst._aipStackTotal = INIT_HEALTH_LIMIT
	inst._aipTotalDelta = 0

	inst.OnSave = onSave
	inst.OnLoad = onLoad

	return inst
end

return Prefab("aip_gholdengo", fn, assets)
