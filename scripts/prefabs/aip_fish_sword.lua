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
local PERISH_MAP = {
	["less"] = TUNING.PERISH_FAST,
	["normal"] = TUNING.PERISH_MED,
	["much"] = TUNING.PERISH_PRESERVED,
}
local DAMAGE_MAP = {
	["less"] = TUNING.NIGHTSWORD_DAMAGE / 68 * 30,
	["normal"] = TUNING.NIGHTSWORD_DAMAGE / 68 * 60,
	["large"] = TUNING.NIGHTSWORD_DAMAGE / 68 * 90,
}

local LANG_MAP = {
	["english"] = {
		["NAME"] = "Fish Sword",
		["REC_DESC"] = "Fish is best friend!",
		["DESC"] = "Strong in the ocean",
	},
	["russian"] = {
		["NAME"] = "Рыбный меч",
		["REC_DESC"] = "Рыба - лучший друг!",
		["DESC"] = "Я еле сдерживаюсь, чтобы не съесть это!",
	},
	["portuguese"] = {
		["NAME"] = "Espada peixe",
		["REC_DESC"] = "Peixe é melhor amigo!",
		["DESC"] = "Muita fome pra come-lo",
	},
	["korean"] = {
		["NAME"] = "물고기 소드",
		["REC_DESC"] = "물고기는 최고의 친구야!",
		["DESC"] = "먹고싶은데 아쉬워",
	},
	["chinese"] = {
		["NAME"] = "鱼刀",
		["REC_DESC"] = "鱼是最好的朋友！",
		["DESC"] = "在海上始终强力",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

TUNING.AIP_FISH_SWORD_PERISH = PERISH_MAP[weapon_uses]
TUNING.AIP_FISH_SWORD_DAMAGE = DAMAGE_MAP[weapon_damage]

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
STRINGS.NAMES.AIP_FISH_SWORD = LANG.NAME
STRINGS.RECIPE_DESC.AIP_FISH_SWORD = LANG.REC_DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_FISH_SWORD = LANG.DESC

-- 配方
local aip_fish_sword = Recipe("aip_fish_sword", {Ingredient("pondfish", 1),Ingredient("nightmarefuel", 2),Ingredient("rope", 1)}, RECIPETABS.WAR, TECH.SCIENCE_TWO)
aip_fish_sword.atlas = "images/inventoryimages/aip_fish_sword.xml"

-----------------------------------------------------------

local function calcDamage(inst, attacker, target)
	local MAX_DAMAGE = TUNING.AIP_FISH_SWORD_DAMAGE
	local MIN_DAMAGE = TUNING.HAMBAT_MIN_DAMAGE_MODIFIER * MAX_DAMAGE

	if attacker ~= nil and attacker:IsOnOcean(true) then
		return MAX_DAMAGE
	elseif inst.components.perishable and inst.components.weapon then
		local dmg = MAX_DAMAGE * inst.components.perishable:GetPercent()
		dmg = Remap(dmg, 0, MAX_DAMAGE, MIN_DAMAGE, MAX_DAMAGE)
		return dmg
	end

	return MIN_DAMAGE
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

	inst:AddTag("show_spoilage")
	inst:AddTag("icebox_valid")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("perishable")
	inst.components.perishable:SetPerishTime(TUNING.AIP_FISH_SWORD_PERISH)
	inst.components.perishable:StartPerishing()
	inst.components.perishable.onperishreplacement = "spoiled_food"

	inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(calcDamage)

	inst:AddComponent("inspectable")

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_fish_sword.xml"

	MakeHauntableLaunchAndPerish(inst)

	inst:AddComponent("equippable")
	inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)

	return inst
end

return Prefab( "aip_fish_sword", fn, assets) 
