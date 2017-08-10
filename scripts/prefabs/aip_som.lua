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
		["NAME"] = "SOM",
		["REC_DESC"] = "Hello Everyone!",
		["DESC"] = "New come? Good bye~",
	},
	["chinese"] = {
		["NAME"] = "谜之声",
		["REC_DESC"] = "诶！大家好！",
		["DESC"] = "有人刚来吗？晚安晚安~",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

TUNING.AIP_SOM = TUNING.YELLOWAMULET_FUEL * PERISH_MAP[dress_uses]

-- 文字描述
STRINGS.NAMES.AIP_SOM = LANG.NAME
STRINGS.RECIPE_DESC.AIP_SOM = LANG.REC_DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_SOM = LANG.DESC

-- 配方
-- local aip_horse_head = Recipe("aip_horse_head", {Ingredient("beefalowool", 5),Ingredient("boneshard", 3),Ingredient("beardhair", 3)}, RECIPETABS.DRESS, TECH.SCIENCE_TWO)
-- aip_horse_head.atlas = "images/inventoryimages/aip_horse_head.xml"

local tempalte = require("prefabs/aip_dress_template")
return tempalte("aip_som", {
	hideHead = true,
	fueled = {
		level = TUNING.AIP_SOM,
	},
	dapperness = TUNING.DAPPERNESS_LARGE,
})