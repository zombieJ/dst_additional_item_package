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
	less = 100,
	normal = 200,
	much = 500,
}

local DAMAGE_MAP = {
	less = TUNING.NIGHTSWORD_DAMAGE / 68 * 22,
	normal = TUNING.NIGHTSWORD_DAMAGE / 68 * 33,
	large = TUNING.NIGHTSWORD_DAMAGE / 68 * 44,
}

local LANG_MAP = {
	english = {
		NAME = "Hatred Blade",
		DESC = "It gains strength through slaughter",
	},
	chinese = {
		NAME = "憎恨之刃",
		DESC = "它通过屠戮获得强化",
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

-------------------------- 方法 --------------------------
local function calcDamage(inst, attacker, target)
	local DAMAGE = TUNING.AIP_OLDONE_HAND_DAMAGE
	local tgtDmg = DAMAGE + (inst._aipKillerCount or 0)
	tgtDmg = math.min(tgtDmg, DAMAGE * 3)

	return tgtDmg
end

local function OnKilledOther(owner)
	if owner.components.inventory ~= nil then
		local handitem = owner.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)

		if handitem ~= nil and handitem._aipKillerCount ~= nil then
			handitem._aipKillerCount = handitem._aipKillerCount + 1
		end
	end
end

local function onequip(inst, owner)
	owner.AnimState:OverrideSymbol("swap_object", "aip_oldone_hand_swap", "aip_oldone_hand_swap")
	owner.SoundEmitter:PlaySound("dontstarve/wilson/equip_item_gold")
	owner.AnimState:Show("ARM_carry")
	owner.AnimState:Hide("ARM_normal")

	owner:ListenForEvent("killed", OnKilledOther)
end

local function onunequip(inst, owner)
	owner.AnimState:ClearOverrideSymbol("swap_object")
	owner.AnimState:Hide("ARM_carry")
	owner.AnimState:Show("ARM_normal")

	owner:RemoveEventCallback("killed", OnKilledOther)
end

-------------------------- 存取 --------------------------
local function onSave(inst, data)
	data.killCount = inst._aipKillerCount
end

local function onLoad(inst, data)
	if data ~= nil then
		inst._aipKillerCount = data.killCount
	end
end

-------------------------- 实例 --------------------------
local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()
	
	MakeInventoryPhysics(inst)

	inst:AddTag("irreplaceable")
	inst:AddTag("aip_DivineRapier_bad")
	
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
	inst.components.finiteuses:SetOnFinished(function()
		if aipUnique() ~= nil then
			aipUnique():OldoneKillCount(inst._aipKillerCount)
		end

		inst:Remove()
	end)

	inst:AddComponent("inspectable")

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_oldone_hand.xml"

	MakeHauntableLaunch(inst)

	inst:AddComponent("equippable")
	inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)

	inst._aipKillerCount = 0

	inst.OnLoad = onLoad
	inst.OnSave = onSave

	return inst
end

return Prefab("aip_oldone_hand", fn, assets)
