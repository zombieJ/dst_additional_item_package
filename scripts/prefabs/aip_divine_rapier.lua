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
	less = 200,
	normal = 400,
	much = 1000,
}

local DAMAGE_MAP = {
	less = TUNING.NIGHTSWORD_DAMAGE / 68 * 22,
	normal = TUNING.NIGHTSWORD_DAMAGE / 68 * 33,
	large = TUNING.NIGHTSWORD_DAMAGE / 68 * 44,
}

local DAMAGE_FRIEND_MAP = {
	less = 22,
	normal = 33,
	large = 44,
}

local LANG_MAP = {
	english = {
		NAME = "Divine Rapier",
		DESC = "The combination of light and dark",
		REC_DESC = "Fusing the power of both, it is powerful with slaughter and full of power because of companions",
	},
	chinese = {
		NAME = "圣剑",
		DESC = "光与暗的结合",
		REC_DESC = "融合两者的力量，即随着杀戮而强大，又因为同伴而充满力量",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

TUNING.AIP_DIVINE_RAPIER_USES = USES_MAP[weapon_uses]
TUNING.AIP_DIVINE_RAPIER_DAMAGE = DAMAGE_MAP[weapon_damage]
TUNING.AIP_DIVINE_RAPIER_DAMAGE_FIREND = DAMAGE_FRIEND_MAP[weapon_damage]

-- 资源
local assets = {
	Asset("ATLAS", "images/inventoryimages/aip_divine_rapier.xml"),
	Asset("ANIM", "anim/aip_divine_rapier.zip"),
	Asset("ANIM", "anim/aip_divine_rapier_swap.zip"),
}

local prefabs = {}

-- 文字描述
STRINGS.NAMES.AIP_DIVINE_RAPIER = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_DIVINE_RAPIER = LANG.DESC
STRINGS.RECIPE_DESC.AIP_DIVINE_RAPIER = LANG.REC_DESC

-------------------------- 方法 --------------------------
local function calcDamage(inst, attacker, target)
	local DAMAGE = TUNING.AIP_DIVINE_RAPIER_DAMAGE

	-- 杀生伤害累加，最多 200% 基础伤害
	local killDmg = math.min(DAMAGE * 2, inst._aipKillerCount or 0)

	-- 友伤伤害累加，最多 4 倍叠加伤害
	local nearPlayerCount = math.max(0, #aipFindNearPlayers(attacker, 20) - 1)
	if
		attacker ~= nil and
		attacker.components.aipc_pet_owner ~= nil and
		attacker.components.aipc_pet_owner.showPet ~= nil
	then
		nearPlayerCount = nearPlayerCount + 1
	end
	local friendDmg = math.min(nearPlayerCount, 4) * TUNING.AIP_DIVINE_RAPIER_DAMAGE_FIREND

	return DAMAGE + killDmg + friendDmg
end

local function OnKilledOther(owner)
	if owner.components.inventory ~= nil then
		local handitem = owner.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)

		if handitem ~= nil and handitem._aipKillerCount ~= nil then
			handitem._aipKillerCount = handitem._aipKillerCount + 1
		end
	end
end

-- 合成的圣剑会继承耐久度
local function OnPreBuilt(inst, builder, materials, recipe)
	local aip_oldone_hand = materials.aip_oldone_hand
	local aip_living_friendship = materials.aip_living_friendship

	local count = 0
	local totalPtg = 0

	for prefabName, ents in pairs(materials) do
		for prefab, needCount in pairs(ents) do
			local badUses = aipGet(prefab, "components|finiteuses")
			if badUses ~= nil then
				count = count + 1
				totalPtg = totalPtg + badUses:GetPercent()
			end
		end
	end

	aipTypePrint(">>>", totalPtg, count)

	if inst.components.finiteuses ~= nil and count > 0 then
		inst.components.finiteuses:SetPercent((totalPtg) / count)
	end
end

local function onequip(inst, owner)
	owner.AnimState:OverrideSymbol("swap_object", "aip_divine_rapier_swap", "aip_divine_rapier_swap")
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
	inst:AddTag("aip_DivineRapier_good")
	
	inst.AnimState:SetBank("aip_divine_rapier")
	inst.AnimState:SetBuild("aip_divine_rapier")
	inst.AnimState:PlayAnimation("idle")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(calcDamage)

	inst:AddComponent("finiteuses")
	inst.components.finiteuses:SetMaxUses(TUNING.AIP_DIVINE_RAPIER_USES)
	inst.components.finiteuses:SetUses(TUNING.AIP_DIVINE_RAPIER_USES)

	inst:AddComponent("inspectable")

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_divine_rapier.xml"

	MakeHauntableLaunch(inst)

	inst:AddComponent("equippable")
	inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)

	inst._aipKillerCount = 0

	inst.onPreBuilt = OnPreBuilt

	inst.OnLoad = onLoad
	inst.OnSave = onSave

	return inst
end

return Prefab("aip_divine_rapier", fn, assets)
