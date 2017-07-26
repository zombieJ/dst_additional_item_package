local foldername = KnownModIndex:GetModActualName(TUNING.ZOMBIEJ_ADDTIONAL_PACKAGE)

-- 配置
local additional_survival = GetModConfigData("additional_survival", foldername)
if additional_survival ~= "open" then
	return nil
end

local language = GetModConfigData("language", foldername)

-- 语言
local LANG_MAP = {
	["english"] = {
		["NAME"] = "Blood Package",
		["DESC"] = "A quick heal package",
		["DESCRIBE"] = "I get more time with Boss",
	},
	["chinese"] = {
		["NAME"] = "血袋",
		["DESC"] = "快速治疗包",
		["DESCRIBE"] = "我和Boss有更多的相处时间了",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

-- 资源
local assets =
{
	Asset("ANIM", "anim/aip_blood_package.zip"),
	Asset("ATLAS", "images/inventoryimages/aip_blood_package.xml"),
	Asset("IMAGE", "images/inventoryimages/aip_blood_package.tex"),
}

local prefabs =
{
	"impact",
}

-- 文字描述
STRINGS.NAMES.AIP_BLOOD_PACKAGE = LANG.NAME
STRINGS.RECIPE_DESC.AIP_BLOOD_PACKAGE = LANG.DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_BLOOD_PACKAGE = LANG.DESCRIBE

-- 配方
local aip_blood_package = Recipe("aip_blood_package", {Ingredient("mosquitosack", 1), Ingredient("spidergland", 3), Ingredient("ash", 2)}, RECIPETABS.SURVIVAL, TECH.SCIENCE_TWO)
aip_blood_package.atlas = "images/inventoryimages/aip_blood_package.xml"

-----------------------------------------------------------

function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)

	inst.AnimState:SetBank("aip_blood_package")
	inst.AnimState:SetBuild("aip_blood_package")
	inst.AnimState:PlayAnimation("BUILD")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("stackable")
	inst.components.stackable.maxsize = TUNING.STACK_SIZE_MEDITEM

	inst:AddComponent("inspectable")

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_blood_package.xml"

	inst:AddComponent("healer")
	inst.components.healer:SetHealthAmount(TUNING.HEALING_LARGE)

	MakeHauntableLaunch(inst)

	return inst
end

return Prefab("aip_blood_package", fn, assets) 
