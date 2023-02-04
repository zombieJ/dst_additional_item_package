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
        "普通的",
		"优秀的",
		"精良的",
		"杰出的",
		"完美的",
    },
}

-- 口渴：待在身边时，玩家会快速恢复潮湿度
-- 闪光：没有特殊效果，但是相当稀有。宠物会发出光芒。

-- 掉毛：待在身边时，掉落对应物品
-- 好斗：待在身边时，会提升玩家伤害
-- 保守：待在身边时，会减免玩家受到的伤害
-- 谨慎：待在身边时，玩家受到伤害会提升移动速度
-- 陪伴：待在身边时，提升附近玩家的 san 值
-- 孤狼：待在身边时，玩家砍树会提升速度
-- 伯乐：有一定概率提升你抓捕的宠物品质 1 级，如果只有一个宠物，则一定提升

-- 改命：受到致死伤害时，改为恢复生命值。该效果每 10 分钟只能触发一次
-- 铁胃：免疫食物带来的生命损失负面效果
-- 游说：提升收腹宠物概率


-- 专属技能
-- 冰凉：待在身边时，玩家不会过热
-- 温暖：待在身边时，玩家不会过冷
-- 治愈：时不时会治愈玩家生命值

-- 恐惧：当你处于疯狂状态时，攻击有概率时目标恐惧
-- 引雷：像避雷针一样吸引闪电
-- 针灸：提升治疗药物的效果
-- 蝶舞：受到攻击有概率免疫这次伤害
-- 嗜血：每次攻击都会恢复的生命值


local SKILL_LANG = {
	english = {
		shedding = "Picker",
		aggressive = "Aggressive",
		conservative = "Conservative",
		cowardly = "Cautious",
		accompany = "Accompany",
		alone = "Long Wolf",
		eloquence = "Eloquence",
		insight = "Insight",
		cool = "Ice-Cold",
		hot = "Fiery",
		cure = "Cure",
	},
	chinese = {
		shedding = "捡拾",
		aggressive = "好斗",
		conservative = "保守",
		cowardly = "谨慎",
		accompany = "陪伴",
		alone = "孤狼",
		eloquence = "游说",
		insight = "伯乐",
		cool = "冰凉",
		hot = "炙热",
		cure = "治愈",
	},
}

-- 技能最大等级（不同品质的技能最大等级不同）
local SKILL_MAX_LEVEL = {
	shedding = { 1, 2, 3, 4, 5 },
	aggressive = { 5, 10, 15, 20, 25 },
	conservative = { 4, 8, 12, 16, 20 },
	cowardly = { 2, 4, 6, 8, 10 },
	accompany = { 5, 6, 7, 8, 10 },
	alone = { 1, 2, 3, 4, 5 },
	eloquence = { 2, 4, 6, 8, 10 },
	insight = { 5, 10, 15, 20, 25 },
	cool = { 1, 1, 1, 1, 1 },
	hot = { 1, 1, 1, 1, 1 },
	cure = { 1, 2, 3, 4, 5 },
}

local dt = TUNING.TOTAL_DAY_TIME			-- 1 天
local dt_base = dt * 3.5
local san = TUNING.DAPPERNESS_TINY / 1.33	-- 1 点 san / 分钟

-- 不同技能对应的数值
local SKILL_CONSTANT = {
	shedding = {
		base = dt_base,									-- 默认掉落为 3.5 天
		multi = dev_mode and dt_base or (dt / 2),		-- 每个等级减少 0.5 天
	},
	aggressive = {
		multi = 0.01,									-- 每个等级增伤 1%
	},
	conservative = {
		multi = 0.01,									-- 每个等级减伤 1%
	},
	cowardly = {
		multi = dev_mode and 1 or 0.01,					-- 每个等级增速 1%
		duration = 6,									-- 持续 6s
	},
	accompany = {
		unit = dev_mode and san * 9 or san * .5,		-- 每分钟恢复 0.5 点理智
	},
	alone = {
		multi = dev_mode and 10 or 0.3,					-- 每个等级提升效率
	},
	eloquence = {
		multi = dev_mode and 1 or 0.01,					-- 每个等级提升概率
	},
	insight = {
		multi = dev_mode and 1 or 0.01,					-- 每个等级提升概率
	},
	cool = {
		special = true,									-- 专属技能，不会被随机到
		heat = dev_mode and -1000 or -100,				-- 降低 100 点温度
	},
	hot = {
		special = true,									-- 专属技能，不会被随机到
		heat = dev_mode and 1000 or 100,				-- 增加 100 点温度
	},
	cure = {
		special = true,									-- 专属技能，不会被随机到
		multi = 1,										-- 治愈量
		interval = 5,									-- 每隔 5 秒
		max = dev_mode and 0.5 or 0.25,					-- 低于 25% 生命值时才会触发
		maxMulti = 0.05,								-- 每级别提升 5%
	},
}

local SKILL_DESC_LANG = {
	english = {
		shedding = "Drop items every DAY days",
		aggressive = "Increase your ATK% damage",
		conservative = "Reduce your getting damage PTC%",
		cowardly = "Increase your SPD% when attacked (DUR seconds)",
		accompany = "Recover SAN points/minute for nearby players",
		alone = "Increase work effect(chop, mine) WRK% when no other players nearby",
		eloquence = "Increase catch chance of pets by PTG%",
		insight = "Has PTG% chance to increase catch pet quality. Be 100% if this is your only pet",
		cool = "It's cool. Take care to not to close",
		hot = "It's hot. Take care to not to close",
		cure = "Cure HLT point health every ITV seconds when health is lower than PTG%",
	},
	chinese = {
		shedding = "每隔DAY天会丢出捡到的物品",
		aggressive = "提升你的战斗伤害ATK%",
		conservative = "减免你受到的伤害PTC%",
		cowardly = "受到伤害时提升移动速度SPD%，持续DUR秒",
		accompany = "恢复附近玩家理智值SAN点/分",
		alone = "如果附近没有其他玩家，则提升砍伐、采矿工作效率WRK%",
		eloquence = "提升捕捉宠物概率PTG%",
		insight = "有PTG%概率提升捕捉宠物的品质，如果这是你唯一的宠物则为100%概率",
		cool = "散发着寒气，小心靠近被冻着哦",
		hot = "冒着热气，靠太近小心被烫伤哦",
		cure = "当生命值低于PTG%时，每隔ITV秒恢复HLT点生命值",
	},
}

-- 技能文字描述的计算
local SKILL_DESC_VARS = {
	shedding = function(info, lv)
		return {
			DAY = (info.base - info.multi * lv) / dt,
		}
	end,
	aggressive = function(info, lv)
		return {
			ATK = info.multi * lv * 100,
		}
	end,
	conservative = function(info, lv)
		return {
			PTC = info.multi * lv * 100,
		}
	end,
	cowardly = function(info, lv)
		return {
			SPD = info.multi * lv * 100,
			DUR = info.duration,
		}
	end,
	accompany = function(info, lv)
		return {
			SAN = info.unit * lv / san,
		}
	end,
	alone = function(info, lv)
		return {
			WRK = info.multi * lv * 100,
		}
	end,
	eloquence = function(info, lv)
		return {
			PTG = info.multi * lv * 100,
		}
	end,
	insight = function(info, lv)
		return {
			PTG = info.multi * lv * 100,
		}
	end,
	cure = function(info, lv)
		return {
			PTG = (info.max + info.maxMulti * lv) * 100,
			ITV = info.interval,
			HLT = info.multi * lv,
		}
	end,
}

local SKILL_LIST = {}
for name, v in pairs(SKILL_CONSTANT) do
	if not v.special then -- 专属技能不会被随机到
		table.insert(SKILL_LIST, name)
	end
end

-- 开发模式固定技能列表
if dev_mode then
	SKILL_LIST = {
		-- "shedding",
		-- "aggressive",
		-- "conservative",
		-- "cowardly",
		-- "accompany",
		-- "alone",
		-- "eloquence",
		-- "insight",
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