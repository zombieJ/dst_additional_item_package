local foldername = KnownModIndex:GetModActualName(TUNING.ZOMBIEJ_ADDTIONAL_PACKAGE)

-- 配置
local dress_uses = GetModConfigData("dress_uses", foldername)
local language = GetModConfigData("language", foldername)

-- 默认参数
local PERISH_MAP = {
	["less"] = 0.5,
	["normal"] = 1,
	["much"] = 2,
}

local LANG_MAP = {
	["english"] = {
		["NAME"] = "Blue Glasses",
		["REC_DESC"] = "Simple and beauti",
		["DESC"] = "I feel knowledge",
	},
	["chinese"] = {
		["NAME"] = "岚色眼镜",
		["REC_DESC"] = "简单而精美",
		["DESC"] = "我有文化我自豪",
	},
	["english"] = {
		["NAME"] = "Очки",
		["REC_DESC"] = "Простые и прекрасные!",
		["DESC"] = "Я чувствую прилив знаний!",
}

local LANG = LANG_MAP[language] or LANG_MAP.english

-- 文字描述
STRINGS.NAMES.AIP_BLUE_GLASSES = LANG.NAME
STRINGS.RECIPE_DESC.AIP_BLUE_GLASSES = LANG.REC_DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_BLUE_GLASSES = LANG.DESC

-- 配方
local aip_blue_glasses = Recipe("aip_blue_glasses", {Ingredient("steelwool", 1), Ingredient("ice", 2)}, RECIPETABS.DRESS, TECH.SCIENCE_TWO)
aip_blue_glasses.atlas = "images/inventoryimages/aip_blue_glasses.xml"

local tempalte = require("prefabs/aip_dress_template")
return tempalte("aip_blue_glasses", {
	keepHead = true,
	armor = {
		amount = 500 * PERISH_MAP[dress_uses],
		absorb_percent = 1,
		tag = "shadowcreature",
	},
})
