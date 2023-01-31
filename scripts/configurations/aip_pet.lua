local language = aipGetModConfig("language")
local dev_mode = aipGetModConfig("dev_mode") == "enabled"

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
-- 谨慎：待在身边时，玩家受到伤害会提升移动速度
-- 冰凉：待在身边时，玩家不会过热
-- 温暖：待在身边时，玩家不会过冷
-- 陪伴：待在身边时，提升附近玩家的 san 值
-- 口渴：待在身边时，玩家会快速恢复潮湿度
-- 顶撞：待在身边时，玩家砍树会提升速度
-- 闪光：没有特殊效果，但是相当稀有。宠物会发出光芒。

local SKILL_LANG = {
	english = {
		shedding = "Picker",
		aggressive = "Aggressive",
		conservative = "Conservative",
		cowardly = "Cautious",
		accompany = "Accompany",
	},
	chinese = {
		shedding = "捡拾",
		aggressive = "好斗",
		conservative = "保守",
		cowardly = "谨慎",
		accompany = "陪伴",
	},
}

local SKILL_DESC_LANG = {
	english = {
		shedding = "Shedding",
		aggressive = "Aggressive",
		conservative = "Conservative",
		cowardly = "Cowardly",
		accompany = "Accompany",
	},
	chinese = {
		shedding = "会定期丢出捡到的物品",
		aggressive = "提升你的战斗伤害",
		conservative = "减免你受到的伤害",
		cowardly = "受到伤害时提升移动速度 SPD%，持续 DUR 秒",
		accompany = "恢复附近玩家理智值",
	},
}

-- 技能文字描述的计算
local SKILL_DESC_VARS = {
	cowardly = function(info, lv)
		return {
			SPD = info.multi * lv * 100,
			DUR = info.duration,
		}
	end,
}

-- 技能最大等级（不同品质的技能最大等级不同）
local SKILL_MAX_LEVEL = {
	shedding = { 1, 2, 3, 4, 5 },
	aggressive = { 5, 10, 15, 20, 25 },
	conservative = { 4, 8, 12, 16, 20 },
	cowardly = { 2, 4, 6, 8, 10 },
	accompany = { 5, 6, 7, 8, 10 },
}

local dt = TUNING.TOTAL_DAY_TIME
local dt_base = dt * 6
local san = TUNING.DAPPERNESS_TINY / 1.33	-- 1 点 san / 分钟

-- 不同技能对应的数值
local SKILL_CONSTANT = {
	shedding = {
		base = dt_base,								-- 默认掉落为 6 天
		multi = dev_mode and (dt_base - 10) or dt,	-- 每个等级减少 1 天
	},
	aggressive = {
		multi = 0.01,								-- 每个等级增伤 1%
	},
	conservative = {
		multi = 0.01,								-- 每个等级减伤 1%
	},
	cowardly = {
		multi = dev_mode and 1 or 0.01,				-- 每个等级增速 1%
		duration = 6,								-- 持续 6s
	},
	accompany = {
		unit = dev_mode and san * 9 or san * .5,	-- 每分钟恢复 0.5 点理智
	},
}

local SKILL_LIST = {}
for name, v in pairs(SKILL_LANG.english) do
	table.insert(SKILL_LIST, name)
end

-- 开发模式固定技能列表
if dev_mode then
	SKILL_LIST = {
		"shedding",
		-- "aggressive",
		-- "conservative",
		"cowardly",
		"accompany",
	}
end

return {
    QUALITY_COLORS = QUALITY_COLORS,
    QUALITY_LANG = QUALITY_LANG[language] or QUALITY_LANG.english,
	SKILL_LANG = SKILL_LANG[language] or SKILL_LANG.english,
	SKILL_DESC_LANG = SKILL_DESC_LANG[language] or SKILL_DESC_LANG.english,
	SKILL_DESC_VARS = SKILL_DESC_VARS,
	SKILL_LIST = SKILL_LIST,
	SKILL_MAX_LEVEL = SKILL_MAX_LEVEL,
	SKILL_CONSTANT = SKILL_CONSTANT,
}