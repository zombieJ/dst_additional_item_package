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
	less = TUNING.NIGHTSWORD_DAMAGE / 68 * 10,
	normal = TUNING.NIGHTSWORD_DAMAGE / 68 * 20,
	large = TUNING.NIGHTSWORD_DAMAGE / 68 * 40,
}

local LANG_MAP = {
	english = {
		NAME = "Bonding Blade",
		DESC = "The great friendship",
	},
	chinese = {
		NAME = "羁绊之刃",
		DESC = "赞美伟大的友谊",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

TUNING.AIP_LIVING_FRIENDSHIP_USES = USES_MAP[weapon_uses]
TUNING.AIP_LIVING_FRIENDSHIP_DAMAGE = DAMAGE_MAP[weapon_damage]

-- 资源
local assets = {
	Asset("ATLAS", "images/inventoryimages/aip_living_friendship.xml"),
	Asset("ANIM", "anim/aip_living_friendship.zip"),
	Asset("ANIM", "anim/aip_living_friendship_swap.zip"),
}

local prefabs = {}

-- 文字描述
STRINGS.NAMES.AIP_LIVING_FRIENDSHIP = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_LIVING_FRIENDSHIP = LANG.DESC

-------------------------- 方法 --------------------------
local function calcDamage(inst, attacker, target)
	local DAMAGE = TUNING.AIP_LIVING_FRIENDSHIP_DAMAGE

	-- 统计玩家数量，包括小动物
	local nearPlayerCount = math.max(0, #aipFindNearPlayers(attacker, 20) - 1)

	if
		attacker ~= nil and
		attacker.components.aipc_pet_owner ~= nil and
		attacker.components.aipc_pet_owner.showPet ~= nil
	then
		nearPlayerCount = nearPlayerCount + 1
	end

	-- 每个玩家或者小动物提供倍数加成
	local tgtDmg = DAMAGE + DAMAGE * nearPlayerCount

	return math.min(tgtDmg, DAMAGE * 5)
end

local function onequip(inst, owner)
	owner.AnimState:OverrideSymbol("swap_object", "aip_living_friendship_swap", "aip_living_friendship_swap")
	owner.SoundEmitter:PlaySound("dontstarve/wilson/equip_item_gold")
	owner.AnimState:Show("ARM_carry")
	owner.AnimState:Hide("ARM_normal")
end

local function onunequip(inst, owner)
	owner.AnimState:ClearOverrideSymbol("swap_object")
	owner.AnimState:Hide("ARM_carry")
	owner.AnimState:Show("ARM_normal")
end

-------------------------- 实例 --------------------------
local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()
	
	MakeInventoryPhysics(inst)

	inst:AddTag("irreplaceable")
	inst:AddTag("aip_DivineRapier_good")
	
	inst.AnimState:SetBank("aip_living_friendship")
	inst.AnimState:SetBuild("aip_living_friendship")
	inst.AnimState:PlayAnimation("idle")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(calcDamage)

	inst:AddComponent("finiteuses")
	inst.components.finiteuses:SetMaxUses(TUNING.AIP_LIVING_FRIENDSHIP_USES)
	inst.components.finiteuses:SetUses(TUNING.AIP_LIVING_FRIENDSHIP_USES)

	inst:AddComponent("inspectable")

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_living_friendship.xml"

	MakeHauntableLaunch(inst)

	inst:AddComponent("equippable")
	inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)

	return inst
end

return Prefab("aip_living_friendship", fn, assets)
