-- 配置
local additional_weapon = aipGetModConfig("additional_weapon")
if additional_weapon ~= "open" then
	return nil
end

local weapon_damage = aipGetModConfig("weapon_damage")
local language = aipGetModConfig("language")

-- 默认参数
local DAMAGE_MAP = {
	["less"] = 0.5,
	["normal"] = 1,
	["large"] = 2,
}

local basicDamage = TUNING.NIGHTSWORD_DAMAGE / 68

TUNING.AIP_WOODEAD_DAMANGE_MIN = basicDamage * 8 * DAMAGE_MAP[weapon_damage]
TUNING.AIP_WOODEAD_DAMANGE_MAX = basicDamage * 128 * DAMAGE_MAP[weapon_damage]
TUNING.AIP_WOODEAD_DAMANGE_STEP = basicDamage * 8 * DAMAGE_MAP[weapon_damage]

local LANG_MAP = {
	["english"] = {
		["NAME"] = "Woodead",
		["REC_DESC"] = "He can remember you",
		["DESC"] = "Will harm more with same target",
	},
	["chinese"] = {
		["NAME"] = "木枝歌",
		["REC_DESC"] = "他会记住你的",
		["DESC"] = "打人要专注，效果会更好",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

-- 资源
local assets =
{
	Asset("ATLAS", "images/inventoryimages/aip_fish_sword.xml"),
	Asset("ANIM", "anim/aip_fish_sword.zip"),
	Asset("ANIM", "anim/aip_fish_sword_swap.zip"),
}

local prefabs =
{
}

-- 文字描述
STRINGS.NAMES.AIP_WOODEAD = LANG.NAME
STRINGS.RECIPE_DESC.AIP_WOODEAD = LANG.REC_DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_WOODEAD = LANG.DESC

-----------------------------------------------------------

local function OnAttack(inst, owner, target)
	if target.components.combat ~= nil and inst._aip_target_times > 0 then
		local dmg = math.min(inst._aip_target_times * TUNING.AIP_WOODEAD_DAMANGE_STEP, TUNING.AIP_WOODEAD_DAMANGE_MAX - TUNING.AIP_WOODEAD_DAMANGE_MIN)
		target.components.combat:GetAttacked(owner, dmg, inst)
	end

	-- 重置计数器
	if target ~= inst._aip_target then
		inst._aip_target_times = 1
	else
		inst._aip_target_times = inst._aip_target_times + 1
	end

	-- 设置目标
	inst._aip_target = target
end

local function onequip(inst, owner)
	owner.AnimState:OverrideSymbol("swap_object", "aip_fish_sword_swap", "aip_fish_sword_swap")
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
	
	inst.AnimState:SetBank("aip_fish_sword")
	inst.AnimState:SetBuild("aip_fish_sword")
	inst.AnimState:PlayAnimation("idle")

	inst:AddTag("weapon")

	MakeInventoryFloatable(inst, "med", 0.1)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(TUNING.AIP_WOODEAD_DAMANGE_MIN)
	inst.components.weapon:SetOnAttack(OnAttack)
	inst._aip_target = nil
	inst._aip_target_times = 0

	inst:AddComponent("inspectable")

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_fish_sword.xml"
	inst.components.inventoryitem.imagename = "aip_fish_sword"

	MakeHauntableLaunchAndPerish(inst)

	inst:AddComponent("equippable")
	inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)

	return inst
end

return Prefab( "aip_woodead", fn, assets) 
