-- 武器 标准 模板，武器模板
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
	less = TUNING.NIGHTSWORD_DAMAGE / 68 * 30,
	normal = TUNING.NIGHTSWORD_DAMAGE / 68 * 60,
	large = TUNING.NIGHTSWORD_DAMAGE / 68 * 90,
}

local LANG_MAP = {
	english = {
		NAME = "Radish Match",
		REC_DESC = "Take away the flame of the bonfire",
		DESC = "Take away the flame of the bonfire",
	},
	chinese = {
		NAME = "大根火柴",
		REC_DESC = "可以带走篝火的火焰",
		DESC = "带走篝火的火焰",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

TUNING.AIP_TORCH_DAMAGE = DAMAGE_MAP[weapon_damage]

-- 资源
local assets = {
	Asset("ATLAS", "images/inventoryimages/aip_torch.xml"),
	Asset("ANIM", "anim/aip_torch_swap.zip"),
}

local prefabs = {}

-- 文字描述
STRINGS.NAMES.AIP_TORCH = LANG.NAME
STRINGS.RECIPE_DESC.AIP_TORCH = LANG.REC_DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_TORCH = LANG.DESC

-----------------------------------------------------------

-----------------------------------------------------------
local function onequip(inst, owner)
	owner.AnimState:OverrideSymbol("swap_object", "aip_torch_swap", "aip_torch_swap")
	owner.SoundEmitter:PlaySound("dontstarve/wilson/equip_item_gold")
	owner.AnimState:Show("ARM_carry")
	owner.AnimState:Hide("ARM_normal")
end

local function onunequip(inst, owner)
	owner.AnimState:ClearOverrideSymbol("swap_object")
	owner.AnimState:Hide("ARM_carry")
	owner.AnimState:Show("ARM_normal")
end

-----------------------------------------------------------
local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()
	
	MakeInventoryPhysics(inst)
	
	inst.AnimState:SetBank("aip_torch_swap")
	inst.AnimState:SetBuild("aip_torch_swap")
	inst.AnimState:PlayAnimation("idle")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("finiteuses")
	inst.components.finiteuses:SetMaxUses(1)
	inst.components.finiteuses:SetUses(1)
	inst.components.finiteuses:SetOnFinished(inst.Remove)

	inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(TUNING.AIP_TORCH_DAMAGE)

	inst:AddComponent("inspectable")

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_torch.xml"

	MakeHauntable(inst)

	inst:AddComponent("equippable")
	inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)

	return inst
end

return Prefab("aip_torch", fn, assets)
