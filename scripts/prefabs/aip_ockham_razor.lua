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
local PERISH_MAP = {
	less = 0.5,
	normal = 1,
	much = 2,
}

local DAMAGE_MAP = {
	less = 0.5,
	normal = 1,
	large = 2,
}

local MIN_DMG = TUNING.NIGHTSWORD_DAMAGE / 68 * 10
local MAX_DMG = TUNING.NIGHTSWORD_DAMAGE / 68 * 70
local USES = dev_mode and 10 or (MAX_DMG - MIN_DMG)

-- 计算数值
MIN_DMG = MIN_DMG * DAMAGE_MAP[weapon_damage]
MAX_DMG = MAX_DMG * DAMAGE_MAP[weapon_damage]
USES = USES * PERISH_MAP[weapon_uses]


local LANG_MAP = {
	english = {
		NAME = "Ockham's Razor",
		DESC = "Simple is the best.",
	},
	chinese = {
		NAME = "奥卡姆剃刀",
		DESC = "抹除不必要的麻烦",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

-- 资源
local assets = {
	Asset("ATLAS", "images/inventoryimages/aip_ockham_razor.xml"),
	Asset("ANIM", "anim/aip_ockham_razor.zip"),
	Asset("ANIM", "anim/aip_ockham_razor_swap.zip"),
}

-- 文字描述
STRINGS.NAMES.AIP_OCKHAM_RAZOR = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OCKHAM_RAZOR = LANG.DESC

--------------------------------- 方法 ---------------------------------
local function calcDamage(inst, attacker, target)
	local ptg = inst.components.finiteuses:GetPercent()
	return MIN_DMG + (MAX_DMG - MIN_DMG) * ptg
end

local function onequip(inst, owner)
	owner.AnimState:OverrideSymbol("swap_object", "aip_ockham_razor_swap", "aip_ockham_razor_swap")
	owner.SoundEmitter:PlaySound("dontstarve/wilson/equip_item_gold")
	owner.AnimState:Show("ARM_carry")
	owner.AnimState:Hide("ARM_normal")
end

local function onunequip(inst, owner)
	owner.AnimState:ClearOverrideSymbol("swap_object")
	owner.AnimState:Hide("ARM_carry")
	owner.AnimState:Show("ARM_normal")
end

local function onFueled(inst, item, doer)
	if inst.components.finiteuses ~= nil then
		inst.components.finiteuses:SetPercent(
			Math.min(1,(1 + inst.components.finiteuses:GetPercent()) / 2 + 0.1)
		)
	end
end

--------------------------------- 实例 ---------------------------------
local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()
	
	MakeInventoryPhysics(inst)
	
	inst.AnimState:SetBank("aip_ockham_razor")
	inst.AnimState:SetBuild("aip_ockham_razor")
	inst.AnimState:PlayAnimation("idle")

	inst:AddTag("show_spoilage")
	inst:AddTag("icebox_valid")

	-- 双端通用的匹配
	inst:AddComponent("aipc_fueled")
	inst.components.aipc_fueled.prefab = "aip_particles_bottle_charged"
	inst.components.aipc_fueled.onFueled = onFueled

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("finiteuses")
	inst.components.finiteuses:SetMaxUses(USES)
	inst.components.finiteuses:SetUses(USES)
	inst.components.finiteuses:SetOnFinished(inst.Remove)

	inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(calcDamage)

	inst:AddComponent("inspectable")

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_ockham_razor.xml"

	inst:AddComponent("shaver")

	MakeHauntableLaunchAndPerish(inst)

	inst:AddComponent("equippable")
	inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)

	return inst
end

return Prefab("aip_ockham_razor", fn, assets)
