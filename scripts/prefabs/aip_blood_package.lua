local foldername = KnownModIndex:GetModActualName(TUNING.ZOMBIEJ_ADDTIONAL_PACKAGE)

-- 配置
local additional_survival = aipGetModConfig("additional_survival")
if additional_survival ~= "open" then
	return nil
end

local survival_effect = aipGetModConfig("survival_effect")
local language = aipGetModConfig("language")

-- 默认参数
local HEAL_MAP = {
	["less"] = TUNING.HEALING_MEDLARGE,
	["normal"] = TUNING.HEALING_LARGE,
	["large"] = TUNING.HEALING_HUGE,
}

-- 语言
local LANG_MAP = {
	["english"] = {
		["NAME"] = "Blood Package",
		["DESC"] = "A quick heal package",
		["DESCRIBE"] = "I get more time with Boss",
	},
	["russian"] = {
		["NAME"] = "Мешочек с кровью",
		["DESC"] = "Мешочек для быстрого лечения",
		["DESCRIBE"] = "Теперь я могу провести больше времени с боссом.",
	},
	["portuguese"] = {
		["NAME"] = "Bolsa de sangue",
		["DESC"] = "Um pacote de vida rapida",
		["DESCRIBE"] = "Eu pego mais tempo com o chefe",
	},
	["korean"] = {
		["NAME"] = "혈액 주머니",
		["DESC"] = "빠른 회복을 위한 팩",
		["DESCRIBE"] = "보스들과 더 오래 싸울 수 있겠어",
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
	inst.components.healer:SetHealthAmount(HEAL_MAP[survival_effect])

	MakeHauntableLaunch(inst)

	return inst
end

return Prefab("aip_blood_package", fn, assets) 
