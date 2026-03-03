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
	normal = 150,
	much = 300,
}
local DAMAGE_MAP = {
	less = TUNING.NIGHTSWORD_DAMAGE / 68 * 30,
	normal = TUNING.NIGHTSWORD_DAMAGE / 68 * 60,
	large = TUNING.NIGHTSWORD_DAMAGE / 68 * 90,
}

local LANG_MAP = {
	english = {
		NAME = "Section of gills",
		DESC = "You can still feel its greed",
	},
	chinese = {
		NAME = "一节鳃骨",
		DESC = "仍然可以感受到它的贪婪",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

TUNING.AIP_BLACK_XUELONG_USES = USES_MAP[weapon_uses]
TUNING.AIP_BLACK_XUELONG_DAMAGE = DAMAGE_MAP[weapon_damage]

-- 资源
local assets =
{
	Asset("ATLAS", "images/inventoryimages/aip_black_xuelong.xml"),
	Asset("ANIM", "anim/aip_black_xuelong.zip"),
	Asset("ANIM", "anim/aip_black_xuelong_swap.zip"),
}

local prefabs = {}

-- 文字描述
STRINGS.NAMES.AIP_BLACK_XUELONG = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_BLACK_XUELONG = LANG.DESC

-----------------------------------------------------------

local function calcDamage(inst, attacker, target)
	if attacker ~= nil and aipBufferExist(attacker, "aip_see_eyes") then
		return TUNING.AIP_BLACK_XUELONG_DAMAGE * 2
	end

	return TUNING.AIP_BLACK_XUELONG_DAMAGE
end

local function onequip(inst, owner)
	owner.AnimState:OverrideSymbol("swap_object", "aip_black_xuelong_swap", "aip_black_xuelong_swap")
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
	
	inst.AnimState:SetBank("aip_black_xuelong")
	inst.AnimState:SetBuild("aip_black_xuelong")
	inst.AnimState:PlayAnimation("idle")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("finiteuses")
	inst.components.finiteuses:SetMaxUses(TUNING.AIP_BLACK_XUELONG_USES)
    inst.components.finiteuses:SetUses(TUNING.AIP_BLACK_XUELONG_USES)
	inst.components.finiteuses:SetOnFinished(inst.Remove)

	inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(calcDamage)

	inst:AddComponent("inspectable")

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_black_xuelong.xml"

	MakeHauntableLaunch(inst)

	inst:AddComponent("equippable")
	inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)

	return inst
end

return Prefab("aip_black_xuelong", fn, assets)
