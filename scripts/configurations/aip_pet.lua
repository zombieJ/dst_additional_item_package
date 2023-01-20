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

local QUALITY_LANG = {
    english = {
		"Normal",
		"Nice",
		"Great",
		"Outstanding",
		"Perfect",
	},
	chinese = {
        "普通",
		"优秀",
		"精良",
		"杰出",
		"完美",
    },
}

-- 掉毛：待在身边时，掉落对应物品
-- 好斗：待在身边时，会提升玩家伤害
-- 保守：待在身边时，会减免玩家受到的伤害
-- 怯懦：待在身边时，玩家受到伤害会提升移动速度
-- 冰凉：待在身边时，玩家不会过热
-- 温暖：待在身边时，玩家不会过冷
-- 陪伴：待在身边时，提升附近玩家的 san 值
-- 口渴：待在身边时，玩家会快速恢复潮湿度
-- 顶撞：待在身边时，玩家砍树会提升速度
-- 闪光：没有特殊效果，但是相当稀有。宠物会发出光芒。

local SKILL_LANG = {
	english = {
		shedding = "Shedding",
		aggressive = "Aggressive",
		conservative = "Conservative",
		cowardly = "Cowardly",
	},
	chinese = {
		shedding = "掉毛",
		aggressive = "好斗",
		conservative = "保守",
		cowardly = "怯懦",
	},
}

local SKILL_DESC_LANG = {
	english = {
		shedding = "Shedding",
		aggressive = "Aggressive",
		conservative = "Conservative",
		cowardly = "Cowardly",
	},
	chinese = {
		shedding = "每隔一段时间会掉落物品",
		aggressive = "提升你的战斗伤害",
		conservative = "减免你受到的伤害",
		cowardly = "当你被攻击时提升移动速度",
	},
}

local SKILL_LIST = {}
for name, v in pairs(SKILL_LANG.english) do
	table.insert(SKILL_LIST, name)
end

return {
    QUALITY_COLORS = QUALITY_COLORS,
    QUALITY_LANG = QUALITY_LANG[language] or QUALITY_LANG.english,
	SKILL_LANG = SKILL_LANG[language] or SKILL_LANG.english,
	SKILL_DESC_LANG = SKILL_DESC_LANG[language] or SKILL_DESC_LANG.english,
	SKILL_LIST = SKILL_LIST,
}