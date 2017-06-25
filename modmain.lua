-- 全局资源
local STRINGS = GLOBAL.STRINGS
local RECIPETABS = GLOBAL.RECIPETABS
local Recipe = GLOBAL.Recipe
local Ingredient = GLOBAL.Ingredient
local TECH = GLOBAL.TECH

-- 配置
local popcorn_uses = GetModConfigData("popcorn_uses")
local popcorn_damage = GetModConfigData("popcorn_damage")
local language = GetModConfigData("language")

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

Assets =
{
	Asset("ATLAS", "images/inventoryimages/popcorngun.xml"),
}

PrefabFiles =
{
	"popcorngun"
}

STRINGS.NAMES.POPCORNGUN = LANG.NAME
STRINGS.RECIPE_DESC.POPCORNGUN = LANG.DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.POPCORNGUN = LANG.DESCRIBE

local popcorngun = GLOBAL.Recipe("popcorngun", {Ingredient("corn", 2),Ingredient("twigs", 2),Ingredient("silk", 1)}, RECIPETABS.WAR, TECH.SCIENCE_TWO)
popcorngun.atlas = "images/inventoryimages/popcorngun.xml"

--[[
PrefabFiles =
{
	"popcorngun"
}

local PECIPETABS = GLOBAL.PECIPETABS
local TECH = GLOBAL.TECH

local popcorngun = GLOBAL.Recipe("popcorngun", {Ingredient("corn", 2),Ingredient("twigs", 1),Ingredient("rope", 1),Ingredient("silk", 1)}, RECIPETABS.WAR,  TECH.SCIENCE_TWO)
popcorngun.atlas = "images/inventoryimages/popcorngun.xml"
]]--