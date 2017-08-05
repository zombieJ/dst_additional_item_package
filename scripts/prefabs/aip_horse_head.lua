local foldername = KnownModIndex:GetModActualName(TUNING.ZOMBIEJ_ADDTIONAL_PACKAGE)

-- 配置
local additional_dress = GetModConfigData("additional_dress", foldername)
if additional_dress ~= "open" then
	return nil
end

local weapon_uses = GetModConfigData("weapon_uses", foldername)
local weapon_damage = GetModConfigData("weapon_damage", foldername)
local language = GetModConfigData("language", foldername)

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
		["NAME"] = "Horse Head",
		["REC_DESC"] = "It makes you faster",
		["DESC"] = "I have 4 legs",
	},
	["chinese"] = {
		["NAME"] = "马头",
		["REC_DESC"] = "让你跑的更快",
		["DESC"] = "我感觉长了4条腿",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

TUNING.AIP_FISH_SWORD_PERISH = PERISH_MAP[weapon_uses]
TUNING.AIP_FISH_SWORD_DAMAGE = DAMAGE_MAP[weapon_damage]

-- 资源
local assets =
{
	Asset("ATLAS", "images/inventoryimages/aip_horse_head.xml"),
	Asset("ANIM", "anim/aip_horse_head.zip"),
}

local prefabs =
{
}

-- 文字描述
STRINGS.NAMES.AIP_HORSE_HEAD = LANG.NAME
STRINGS.RECIPE_DESC.AIP_HORSE_HEAD = LANG.REC_DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_HORSE_HEAD = LANG.DESC

-- 配方
local aip_horse_head = Recipe("aip_horse_head", {Ingredient("beefalowool", 5),Ingredient("boneshard", 3),Ingredient("beardhair", 3)}, RECIPETABS.DRESS, TECH.SCIENCE_TWO)
aip_horse_head.atlas = "images/inventoryimages/aip_horse_head.xml"

-----------------------------------------------------------
local function onequip(inst, owner)
	owner.AnimState:OverrideSymbol("swap_hat", "aip_horse_head", "swap_hat")
	owner.AnimState:Show("HAT")
	owner.AnimState:Show("HAIR_HAT")
	owner.AnimState:Hide("HAIR_NOHAT")
	owner.AnimState:Hide("HAIR")

	if owner:HasTag("player") then
		owner.AnimState:Hide("HEAD")
		-- owner.AnimState:Show("HEAD_HAT")
	end

	if inst.components.fueled ~= nil then
		inst.components.fueled:StartConsuming()
	end
end

local function onunequip(inst, owner)
	owner.AnimState:ClearOverrideSymbol("swap_hat")
	owner.AnimState:Hide("HAT")
	owner.AnimState:Hide("HAIR_HAT")
	owner.AnimState:Show("HAIR_NOHAT")
	owner.AnimState:Show("HAIR")

	if owner:HasTag("player") then
		owner.AnimState:Show("HEAD")
		-- owner.AnimState:Hide("HEAD_HAT")
	end

	if inst.components.fueled ~= nil then
		inst.components.fueled:StopConsuming()
	end
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)

	inst.AnimState:SetBank("aip_horse_head")
	inst.AnimState:SetBuild("aip_horse_head")
	inst.AnimState:PlayAnimation("anim")

	inst:AddTag("hat")
	inst:AddTag("waterproofer")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_horse_head.xml"

	inst:AddComponent("inspectable")

	inst:AddComponent("tradable")

	inst:AddComponent("equippable")
	inst.components.equippable.equipslot = EQUIPSLOTS.HEAD
	inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)
	inst.components.equippable.walkspeedmult = TUNING.CANE_SPEED_MULT

	inst:AddComponent("fueled")
	inst.components.fueled.fueltype = FUELTYPE.USAGE
	inst.components.fueled:InitializeFuelLevel(TUNING.YELLOWAMULET_FUEL)
	inst.components.fueled:SetDepletedFn(inst.Remove)

	MakeHauntableLaunch(inst)

	inst:AddComponent("waterproofer")
	inst.components.waterproofer:SetEffectiveness(TUNING.WATERPROOFNESS_SMALL)

	return inst
end

return Prefab("aip_horse_head", fn, assets, prefabs)