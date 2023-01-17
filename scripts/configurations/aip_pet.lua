local language = aipGetModConfig("language")

local aip_nectar_config = require("prefabs/aip_nectar_config")
local NEC_COLORS = aip_nectar_config.QUALITY_COLORS

-- 我们复用花蜜的颜色
local QUALITY_COLORS = {
	-- 普通 1
	{ 255, 255, 255 },
	-- 优秀 2
	NEC_COLORS.quality_2,
	-- 精良 3
	NEC_COLORS.quality_3,
	-- 杰出 4
	NEC_COLORS.quality_4,
	-- 完美 5
	NEC_COLORS.quality_5,
}

local LANG_MAP = {
    english = {
		"Normal Quality",
		"Nice Quality",
		"Great Quality",
		"Outstanding Quality",
		"Perfect Quality",
	},
	chinese = {
        "普通品质",
		"优秀品质",
		"精良品质",
		"杰出品质",
		"完美品质",
    },
}

return {
    QUALITY_COLORS = QUALITY_COLORS,
    QUALITY_LANG = LANG_MAP[language] or LANG_MAP.english
}