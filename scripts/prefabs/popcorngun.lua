local foldername = KnownModIndex:GetModActualName(TUNING.ZOMBIEJ_ADDTIONAL_PACKAGE)

-- 配置
local additional_weapon = GetModConfigData("additional_weapon", foldername)
if additional_weapon ~= "open" then
	return nil
end

local popcorn_uses = GetModConfigData("popcorn_uses", foldername)
local popcorn_damage = GetModConfigData("popcorn_damage", foldername)
local language = GetModConfigData("language", foldername)

-- 默认参数
local USES_MAP = {
	["less"] = 10,
	["normal"] = 20,
	["much"] = 50,
}
local DAMAGE_MAP = {
	["less"] = 17,
	["normal"] = 28,
	["large"] = 60,
}

local RECIPE_MAP = {
	["less"] = {Ingredient("corn", 1),Ingredient("twigs", 1),Ingredient("rope", 1)},
	["normal"] = {Ingredient("corn", 2),Ingredient("twigs", 2),Ingredient("silk", 1)},
	["much"] = {Ingredient("corn", 3),Ingredient("twigs", 2),Ingredient("silk", 3)},
}

local LANG_MAP = {
	["english"] = {
		["NAME"] = "Popcorn Gun",
		["DESC"] = "Don't eat it!",
		["DESCRIBE"] = "It used to be delicious",
	},
	["chinese"] = {
		["NAME"] = "玉米枪",
		["DESC"] = "儿童请勿食用！",
		["DESCRIBE"] = "它以前应该很好吃~",
	},
}

local LANG = LANG_MAP[language]

TUNING.POPCORNGUN_USES = USES_MAP[popcorn_uses]
TUNING.POPCORNGUN_DAMAGE = DAMAGE_MAP[popcorn_damage]

-- 资源
local assets =
{
	Asset("ANIM", "anim/popcorn_gun.zip"),
	Asset("ANIM", "anim/swap_popcorn_gun.zip"),
}

local prefabs =
{
	"impact",
}

-- 文字描述
STRINGS.NAMES.POPCORNGUN = LANG.NAME
STRINGS.RECIPE_DESC.POPCORNGUN = LANG.DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.POPCORNGUN = LANG.DESCRIBE

-- 配方
local popcorngun = Recipe("popcorngun", RECIPE_MAP[popcorn_uses], RECIPETABS.WAR, TECH.SCIENCE_TWO)
popcorngun.atlas = "images/inventoryimages/popcorngun.xml"

-----------------------------------------------------------

local function onequip(inst, owner)
	owner.AnimState:OverrideSymbol("swap_object", "swap_popcorn_gun", "swap_popcorn_gun")
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
	
	inst.AnimState:SetBank("popcorn_gun")
	inst.AnimState:SetBuild("popcorn_gun")
	inst.AnimState:PlayAnimation("idle")

	inst:AddTag("popcorngun")
	inst:AddTag("sharp")
	inst:AddTag("projectile")
	
	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	-- 武器
	inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(TUNING.POPCORNGUN_DAMAGE)
	inst.components.weapon:SetRange(8, 10)
	inst.components.weapon:SetProjectile("fire_projectile")

	-- 可检查
	inst:AddComponent("inspectable")
	
	-- 物品栏
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/popcorngun.xml"
	
	-- 使用次数
	inst:AddComponent("finiteuses")
	inst.components.finiteuses:SetMaxUses(TUNING.POPCORNGUN_USES)
	inst.components.finiteuses:SetUses(TUNING.POPCORNGUN_USES)
	
	inst.components.finiteuses:SetOnFinished(inst.Remove)
	
	-- 装备
	inst:AddComponent("equippable")
	inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)
	
	-- 可以造成伤害
	MakeHauntableLaunch(inst)

	return inst
end

return Prefab( "popcorngun", fn, assets) 
