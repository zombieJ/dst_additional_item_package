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
local USES_MAP = {
	["less"] = 10,
	["normal"] = 20,
	["much"] = 50,
}
local DAMAGE_MAP = {
	["less"] = TUNING.NIGHTSWORD_DAMAGE / 68 * 17,
	["normal"] = TUNING.NIGHTSWORD_DAMAGE / 68 * 28,
	["large"] = TUNING.NIGHTSWORD_DAMAGE / 68 * 60,
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
	["spanish"] = {
		["NAME"] = "Pistola de Palomitas de Maíz",
		["DESC"] = "No te la comas!",
		["DESCRIBE"] = "Solía ser deliciosa",
	},
	["russian"] = {
		["NAME"] = "Кукурузная пушка",
		["DESC"] = "Не ешь это!",
		["DESCRIBE"] = "Накормим попкорном всех!",
	},
	["portuguese"] = {
		["NAME"] = "Arma de pipoca",
		["DESC"] = "Não coma ela!",
		["DESCRIBE"] = "Era deliciosa",
	},
	["korean"] = {
		["NAME"] = "팝콘총",
		["DESC"] = "먹으면 안돼!",
		["DESCRIBE"] = "이거 예전엔 맛있었는데,,,",
	},
	["chinese"] = {
		["NAME"] = "玉米枪",
		["DESC"] = "儿童请勿食用！",
		["DESCRIBE"] = "它以前应该很好吃~",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

TUNING.POPCORNGUN_USES = USES_MAP[weapon_uses]
TUNING.POPCORNGUN_DAMAGE = DAMAGE_MAP[weapon_damage]

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
local popcorngun = Recipe("popcorngun", {Ingredient("corn", 2),Ingredient("houndstooth", 4),Ingredient("silk", 3)}, RECIPETABS.WAR, TECH.SCIENCE_TWO)
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
