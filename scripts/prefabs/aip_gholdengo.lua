-- 武器模板
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

TUNING.AIP_GHOLDENGO_DAMAGE = DAMAGE_MAP[weapon_damage]

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
local function onKill(inst, data)
	-- TODO: 累加生命值后给予黄金，至少 1000 点
	if data and data.victim then
		aipFlingItem(aipSpawnPrefab(data.victim, "goldnugget"))
	end
end

local function onequip(inst, owner)
	owner.AnimState:OverrideSymbol("swap_object", "aip_gholdengo_swap", "aip_gholdengo_swap")
	owner.SoundEmitter:PlaySound("dontstarve/wilson/equip_item_gold")
	owner.AnimState:Show("ARM_carry")
	owner.AnimState:Hide("ARM_normal")

	owner:ListenForEvent("killed", onKill)
end

local function onunequip(inst, owner)
	owner.AnimState:ClearOverrideSymbol("swap_object")
	owner.AnimState:Hide("ARM_carry")
	owner.AnimState:Show("ARM_normal")

	owner:RemoveEventCallback("killed", onKill)
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

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_gholdengo.xml"

	MakeHauntableLaunch(inst)

	inst:AddComponent("equippable")
	inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)

	return inst
end

return Prefab("aip_gholdengo", fn, assets)
