-- 配置
local dress_uses = aipGetModConfig("dress_uses")
local language = aipGetModConfig("language")

-- 默认参数
local PERISH_MAP = {
	less = 0.5,
	normal = 1,
	much = 2,
}

local LANG_MAP = {
	english = {
		NAME = "Joker Face",
		REC_DESC = "Neurotic awards",
		DESC = "Something seems to surround it",
	},
	chinese = {
		NAME = "诙谐面具",
		REC_DESC = "神经质的嘉奖",
		DESC = "似乎有什么环绕着它",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

TUNING.AIP_JOKER_FACE_FUEL = TUNING.SPIDERHAT_PERISHTIME * PERISH_MAP[dress_uses]

-- 文字描述
STRINGS.NAMES.AIP_JOKER_FACE = LANG.NAME
STRINGS.RECIPE_DESC.AIP_JOKER_FACE = LANG.REC_DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_JOKER_FACE = LANG.DESC

-- 配方
local aip_joker_face = Recipe("aip_joker_face", {Ingredient("livinglog", 3), Ingredient("spidereggsack", 1), Ingredient("razor", 1)}, RECIPETABS.DRESS, TECH.SCIENCE_TWO)
aip_joker_face.atlas = "images/inventoryimages/aip_joker_face.xml"

local tempalte = require("prefabs/aip_dress_template")

return tempalte("aip_joker_face", {
	fueled = {
		level = TUNING.AIP_JOKER_FACE_FUEL,
	},
	onEquip = function()
	end,
	onUnequip = function()
	end,
})