local foldername = KnownModIndex:GetModActualName(TUNING.ZOMBIEJ_ADDTIONAL_PACKAGE)

-- 配置
local additional_weapon = GetModConfigData("additional_weapon", foldername)
if additional_weapon ~= "open" then
	return nil
end

local weapon_uses = GetModConfigData("weapon_uses", foldername)
local weapon_damage = GetModConfigData("weapon_damage", foldername)
local language = GetModConfigData("language", foldername)

-- 默认参数
local PERISH_MAP = {
	["less"] = 5,
	["normal"] = 9,
	["much"] = 15,
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
		["DESC"] = "Too hunger to eat it",
	},
	["chinese"] = {
		["NAME"] = "鱼刀",
		["REC_DESC"] = "鱼是最好的朋友！",
		["DESC"] = "即便很饿也不能吃掉它",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

TUNING.API_FISH_SWORD_PERISH = PERISH_MAP[weapon_uses]
TUNING.API_FISH_SWORD_DAMAGE = DAMAGE_MAP[weapon_damage]

-- 资源
local assets =
{
	Asset("ANIM", "anim/api_fish_sword.zip"),
	-- Asset("ANIM", "anim/swap_api_fish_sword.zip"),
}

local prefabs =
{
}

-- 文字描述
STRINGS.NAMES.API_FISH_SWORD = LANG.NAME
STRINGS.RECIPE_DESC.API_FISH_SWORD = LANG.REC_DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.API_FISH_SWORD = LANG.DESC

-- 配方
local api_fish_sword = Recipe("api_fish_sword", {Ingredient("fish", 1),Ingredient("nightmarefuel", 2),Ingredient("pigskin", 1)}, RECIPETABS.WAR, TECH.SCIENCE_TWO)
api_fish_sword.atlas = "images/inventoryimages/api_fish_sword.xml"

-----------------------------------------------------------

local function UpdateDamage(inst)
	if inst.components.perishable and inst.components.weapon then
		local dmg = TUNING.API_FISH_SWORD_DAMAGE * inst.components.perishable:GetPercent()
		dmg = Remap(dmg, 0, TUNING.API_FISH_SWORD_DAMAGE, TUNING.HAMBAT_MIN_DAMAGE_MODIFIER*TUNING.API_FISH_SWORD_DAMAGE, TUNING.API_FISH_SWORD_DAMAGE)
		inst.components.weapon:SetDamage(dmg)
	end
end

local function OnLoad(inst, data)
	UpdateDamage(inst)
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
	
	inst.AnimState:SetBank("api_fish_sword")
	inst.AnimState:SetBuild("api_fish_sword")
	inst.AnimState:PlayAnimation("idle")

	inst:AddTag("show_spoilage")
	inst:AddTag("icebox_valid")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("perishable")
	inst.components.perishable:SetPerishTime(TUNING.API_FISH_SWORD_PERISH)
	inst.components.perishable:StartPerishing()
	inst.components.perishable.onperishreplacement = "spoiled_food"

	inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(TUNING.API_FISH_SWORD_DAMAGE)
	inst.components.weapon:SetOnAttack(UpdateDamage)

	inst.OnLoad = OnLoad

	inst:AddComponent("inspectable")

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/api_fish_sword.xml"

	MakeHauntableLaunchAndPerish(inst)

	inst:AddComponent("equippable")
	inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)

	return inst
end

return Prefab( "popcorngun", fn, assets) 
