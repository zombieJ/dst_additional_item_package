local foldername = KnownModIndex:GetModActualName(TUNING.ZOMBIEJ_ADDTIONAL_PACKAGE)

-- 配置
local additional_weapon = aipGetModConfig("additional_weapon")
if additional_weapon ~= "open" then
	return nil
end

local weapon_uses = aipGetModConfig("weapon_uses")
local weapon_damage = aipGetModConfig("weapon_damage")
local language = aipGetModConfig("language")

-- 默认参数
local USES_MAP = {
	less = 50,
	normal = 100,
	much = 150,
}

local DAMAGE_MAP = {
	less = TUNING.NIGHTSWORD_DAMAGE / 68 * 35,
	normal = TUNING.NIGHTSWORD_DAMAGE / 68 * 77,
	large = TUNING.NIGHTSWORD_DAMAGE / 68 * 111,
}

local LANG_MAP = {
	english = {
		NAME = "Indescribable Hand",
		DESC = "Crazy hand!",
	},
	chinese = {
		NAME = "不可名状之爪",
		DESC = "模因的趁手之物",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

TUNING.AIP_OLDONE_HAND_USES = USES_MAP[weapon_uses]
TUNING.AIP_OLDONE_HAND_DAMAGE = DAMAGE_MAP[weapon_damage]

-- 资源
local assets = {
	Asset("ATLAS", "images/inventoryimages/aip_oldone_hand.xml"),
	Asset("ANIM", "anim/aip_oldone_hand.zip"),
	Asset("ANIM", "anim/aip_oldone_hand_swap.zip"),
}

local prefabs = {}

-- 文字描述
STRINGS.NAMES.AIP_OLDONE_HAND = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_HAND = LANG.DESC

-----------------------------------------------------------

local function calcDamage(inst, attacker, target)
	local DAMAGE = TUNING.AIP_OLDONE_HAND_DAMAGE

	if attacker ~= nil and aipBufferExist(attacker, "aip_see_eyes") then
		DAMAGE = DAMAGE * 2
	end

	return DAMAGE
end

local function onequip(inst, owner)
	owner.AnimState:OverrideSymbol("swap_object", "aip_oldone_hand_swap", "aip_oldone_hand_swap")
	owner.SoundEmitter:PlaySound("dontstarve/wilson/equip_item_gold")
	owner.AnimState:Show("ARM_carry")
	owner.AnimState:Hide("ARM_normal")
end

local function onunequip(inst, owner)
	owner.AnimState:ClearOverrideSymbol("swap_object")
	owner.AnimState:Hide("ARM_carry")
	owner.AnimState:Show("ARM_normal")
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()
	
	MakeInventoryPhysics(inst)
	
	inst.AnimState:SetBank("aip_oldone_hand")
	inst.AnimState:SetBuild("aip_oldone_hand")
	inst.AnimState:PlayAnimation("idle")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(calcDamage)

	inst:AddComponent("finiteuses")
	inst.components.finiteuses:SetMaxUses(TUNING.AIP_OLDONE_HAND_USES)
	inst.components.finiteuses:SetUses(TUNING.AIP_OLDONE_HAND_USES)
	inst.components.finiteuses:SetOnFinished(inst.Remove)

	inst:AddComponent("inspectable")

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_oldone_hand.xml"

	MakeHauntableLaunchAndPerish(inst)

	inst:AddComponent("equippable")
	inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)

	return inst
end

return Prefab("aip_oldone_hand", fn, assets)
