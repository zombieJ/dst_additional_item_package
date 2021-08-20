-- 武器关闭
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
	less = TUNING.NIGHTSWORD_DAMAGE * 0.8,
	normal = TUNING.NIGHTSWORD_DAMAGE,
	large = TUNING.NIGHTSWORD_DAMAGE * 1.5,
}

local LANG_MAP = {
	english = {
		NAME = "Su Wu",
		DESC = "Hero",
	},
	chinese = {
		NAME = "苏武",
		DESC = "渴饮月窟冰，饥餐天上雪",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

TUNING.AIP_SUWU_USES = USES_MAP[weapon_uses]
TUNING.AIP_SUWU_DAMAGE =  DAMAGE_MAP[weapon_damage]

-- 资源
local assets = {
	Asset("ATLAS", "images/inventoryimages/aip_suwu.xml"),
	Asset("ANIM", "anim/aip_suwu.zip"),
	Asset("ANIM", "anim/aip_suwu_swap.zip"),
}

local prefabs = {}

-- 文字描述
STRINGS.NAMES.AIP_SUWU = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_SUWU = LANG.DESC

-----------------------------------------------------------
local function calcDamage(inst, attacker, target)
	local dmg = TUNING.AIP_SUWU_DAMAGE

	-- 游戏里没有其他玩家
	if #AllPlayers == 1 then
		return dmg * 3
	end

	-- 附近没有其他玩家
	if #aipFindNearPlayers(attacker, 20) == 1 then
		return dmg * 2
	end

	return dmg
end

local function onequip(inst, owner)
	owner.AnimState:OverrideSymbol("swap_object", "aip_suwu_swap", "aip_suwu_swap")
	owner.SoundEmitter:PlaySound("dontstarve/wilson/equip_item_gold")
	owner.AnimState:Show("ARM_carry")
	owner.AnimState:Hide("ARM_normal")
end

local function onunequip(inst, owner)
	owner.AnimState:ClearOverrideSymbol("swap_object")
	owner.AnimState:Hide("ARM_carry")
	owner.AnimState:Show("ARM_normal")
end

function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()
	
	MakeInventoryPhysics(inst)
	MakeInventoryFloatable(inst, "small", 0.05, {1.2, 0.75, 1.2})

	inst:AddTag("irreplaceable")
	inst:AddTag("nonpotatable") -- 苏武只有一把
	
	inst.AnimState:SetBank("aip_suwu")
	inst.AnimState:SetBuild("aip_suwu")
	inst.AnimState:PlayAnimation("idle")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("finiteuses")
	inst.components.finiteuses:SetMaxUses(TUNING.AIP_SUWU_USES)
	inst.components.finiteuses:SetUses(TUNING.AIP_SUWU_USES)
	inst.components.finiteuses:SetOnFinished(inst.Remove)

	inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(calcDamage)

	inst:AddComponent("inspectable")

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_suwu.xml"

	MakeHauntableLaunch(inst)

	inst:AddComponent("equippable")
	inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)

	return inst
end

return Prefab("aip_suwu", fn, assets)
