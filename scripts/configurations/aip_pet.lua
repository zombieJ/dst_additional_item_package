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

-- 海绵：待在身边时，玩家会快速恢复潮湿度
-- 闪光：没有特殊效果，但是相当稀有。宠物会发出光芒。

-- 掉毛：待在身边时，掉落对应物品
-- 好斗：待在身边时，会提升玩家伤害
-- 保守：待在身边时，会减免玩家受到的伤害
-- 谨慎：待在身边时，玩家受到伤害会提升移动速度
-- 陪伴：待在身边时，提升附近玩家的 san 值
-- 孤狼：待在身边时，玩家砍树会提升速度
-- 伯乐：有一定概率提升你抓捕的宠物品质 1 级，如果只有一个宠物，则一定提升
-- 铁胃：免疫食物带来的生命损失负面效果
-- 米糕：你受到的伤害提升 55%。你每次闪避成功，下一次伤害提升 10%，最多提升 100%，受到伤害后重置

-- 厨神：烹饪速度加快

-- 杂技：没有穿戴防具时，攻击和速度提升
-- 呆呆：初次受到攻击时免疫伤害，再次受到攻击时会获得两倍伤害。之后（或者隔一段时间）重置计数器
-- 诅咒：降低速度，提升攻击和伤害减免。当你为幽灵形态时，则会不断减少附近生物生命值，该效果最低降低至 10% 生命值。



-- 改命：受到致死伤害时，改为恢复生命值。该效果每 10 分钟只能触发一次
-- 游说：提升收腹宠物概率



-- 专属技能
-- 冰凉：待在身边时，玩家不会过热
-- 温暖：待在身边时，玩家不会过冷
-- 治愈：时不时会治愈玩家生命值
-- 泷泓：落水的掉落物品惩罚转为被冰冻
-- 针灸：提升治疗药物的效果
-- 逐月：在月岛地皮，伤害提升 100%
-- 催眠：当你被攻击时有概率让攻击者睡眠
-- 蝶舞：受到攻击有概率免疫这次伤害
-- D4C：将死时，你的身边会出现一个短暂的虫洞，跳入后会从另一个虫洞跳出并且恢复全部生命值
-- 掘地：黄昏时会在玩家身边挖掘一个临时的洞穴通向最后一次做饭的地方
-- 茸茸：采摘植物时，有概率原地生长出一株新的植株
-- 嬉闹：攻击目标时，会使目标攻击伤害减少
-- 杀神：附近有猎犬死亡时，你的伤害提升 100%，该效果持续到杀死一个单位为止

-- 岩烧：你可以点燃岩石，经过一段时间后岩石碎裂并掉落一个熔岩结晶
		-- 炸药可以炸毁岩石，会掉落一个熔岩结晶


-- 恐惧：当你处于疯狂状态时，攻击有概率时目标恐惧
-- 引雷：像避雷针一样吸引闪电
-- 嗜血：每次攻击都会恢复的生命值
-- 矩阵：身边每有一个玩家，都会提升你的伤害
-- 武僧：提升拳头的伤害
-- 饕餮：提升食物的所有效果，如果是负面的也会加倍
-- 玉米：你可以投掷玉米造成伤害，投掷后地上会长出一颗玉米


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
		winterSwim = "Winter-Swimer",
		acupuncture = "Acupuncture",
		taster = "Cast-Iron Stomach",
		luna = "Luna",
		hypnosis = "Hypnosis",
		sponge = "Sponge",
		dancer = "Dancer",
		d4c = "D4C",
		dig = "Digger",
		ge = "Gold Experience",
		play = "Play Rough",
		migao = "Migao",
		johnWick = "John Wick",
		graveCloak = "Gravekeeper's Cloak",
		cooker = "Cooker",
		giants = "Giants",
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
		winterSwim = "泷泓",
		acupuncture = "针灸",
		taster = "铁胃",
		luna = "逐月",
		hypnosis = "催眠",
		sponge = "海绵",
		dancer = "蝶舞",
		d4c = "恶行易施",
		dig = "掘地",
		ge = "茸茸",
		play = "嬉闹",
		migao = "米糕",
		johnWick = "杀神",
		graveCloak = "陵卫斗篷",
		cooker = "厨神",
		giants = "巨兽",
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
	winterSwim = { 1, 1, 1, 1, 1 },
	acupuncture = { 10, 20, 30, 40, 50 },
	taster = { 1, 1, 1, 1, 1 },
	luna = { 1, 1, 1, 1, 1 },
	hypnosis = { 5, 10, 15, 20, 25 },
	sponge = { 5, 6, 7, 8, 10 },
	dancer = { 5, 6, 7, 8, 10 },
	d4c = { 1, 1, 1, 1, 1 },
	dig = { 1, 2, 3, 4, 5 },
	ge = { 6, 7, 8, 9, 10 },
	play = { 1, 2, 3, 4, 5 },
	migao = { 2, 4, 6, 8, 10 },
	johnWick = { 5, 6, 7, 8, 10 },
	graveCloak = { 1, 2, 3, 4, 5 },
	cooker = { 5, 6, 7, 8, 9 },
	giants = { 1, 2, 3, 4, 5 },
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
	winterSwim = {
		special = true,									-- 专属技能，不会被随机到
		goldern = true,									-- 金色技能
	},
	acupuncture = {
		special = true,									-- 专属技能，不会被随机到
		multi = dev_mode and 1 or 0.01,					-- 每个等级提升 1% 效果
	},
	luna = {
		special = true,
		goldern = true,
		land = 0.44,									-- 月岛地皮增伤
		full = 0.58,									-- 满月增伤
	},
	hypnosis = {
		special = true,
		multi = dev_mode and 0.4 or 0.01,				-- 每个等级提升 1% 效果
	},
	sponge = {
		multi = 1,										-- 每个等级吸收 1 点雨露
		interval = 5,									-- 间隔 5 秒
	},
	dancer = {
		special = true,
		multi = dev_mode and 1 or 0.01,					-- 每个等级提升 1% 效果
	},
	d4c = {
		special = true,
		goldern = true,
		percent = dev_mode and 0.5 or 0.1,				-- 恢复百分比
	},
	dig = {
		special = true,
		duration = 25,									-- 维持 25 秒
		durationUnit = 5,								-- 每个等级增加 5 秒
	},
	ge = {
		special = true,
		goldern = true,
		ptg = dev_mode and 1 or 0.05,					-- 概率重新种植
	},
	play = {
		special = true,
		weak = dev_mode and 1 or 0.05,					-- 减攻概率
		duration = 10,									-- 持续时间
	},
	migao = {
		special = true,
		goldern = true,
		pain = .55,										-- 受伤提升
		multi = dev_mode and 0.5 or 0.1,				-- 伤害提升
	},
	johnWick = {
		goldern = true,
		multi = 1,										-- 每个等级增伤 1 点
	},
	graveCloak = {
		goldern = true,
		interval = dev_mode and 3 or 6,					-- 每隔 N 秒
		count = dev_mode and 3 or 5,					-- 几个防御
		def = 0.1,										-- 每个斗篷减伤 10%
		defMulti = 0.03,								-- 每个等级增加 3%
	},
	cooker = {
		multi = dev_mode and 0.99 or 0.1,				-- 每个等级增加 10% 烹饪速度
	},
	giants = {
		hp = dev_mode and 50 or 2000,					-- 基础判定血量
		multi = 0.2,									-- 每个等级增伤 20%
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
		winterSwim = "Replace drowning punishment with freezing",
		acupuncture = "Increase the effect of acupuncture by PTG%",
		taster = "Food will not reduce your health",
		luna = "Increase your damage by LND% on the moon land and FUL% on full moon",
		hypnosis = "Has PTG% chance to hypnotize who attack you",
		sponge = "Convert PNT points moisture to hunger every ITV seconds",
		dancer = "Has PTG% chance to be immune to damage taken",
		d4c = "When health < PTG%, jump into wormhole will recover full health. One times per day",
		dig = "Dig a hole to the place you last use cookpot when dusk. Exist for DUR seconds",
		ge = "Have PTG% change to replant the seed when harvest",
		play = "Your attack will make target reduce PTG% damage for DUR seconds",
		migao = "Damage received increases PAN%. Every time you successfully dodge an attack, increase PTG% damage, up to TTL%. Reset when damaged",
		johnWick = "Raise ATK damage. If your pet is hound, player near you will also get this buff",
		graveCloak = "Get barrier per ITV sec (max CNT). Each barrier can reduce PTG% damage but will break one by one when get hurt",
		cooker = "Increase cooking speed by PTG%",
		giants = "Increase PTG% damage for the target whose current health > HP",
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
		winterSwim = "落水惩罚不再失去生命值与物品，转而变为被冰冻状态",
		acupuncture = "提升物品治疗效果PTG%",
		taster = "免疫食物造成的生命损失",
		luna = "在月岛地皮伤害提升LND%，满月伤害提升FUL%",
		hypnosis = "有PTG%概率让攻击你的生物睡着",
		sponge = "每隔ITV秒转化PNT点雨露值为饥饿值",
		dancer = "有PTG%概率免疫受到的伤害",
		d4c = "当生命值小于PTG%时跳入虫洞会恢复至满血，每天限1次",
		dig = "黄昏时会在玩家身边挖掘一个持续DUR秒的洞穴通向最后一次做饭的地方",
		ge = "收成植物时有PTG%概率重新种植",
		play = "被你攻击的目标会降低PTG%伤害，持续DUR秒",
		migao = "受到的伤害提升PAN%。每次成功闪避攻击，提升PTG%伤害，最多TTL%。受到伤害则重置",
		johnWick = "提升ATK点伤害，如果你的宠物是小猎犬，则身边伙伴也获得增伤效果",
		graveCloak = "每隔ITV秒获得一个屏障，最多CNT个。每个屏障减免PTG%伤害，受到伤害时会消耗一层屏障",
		cooker = "烹饪速度提升PTG%",
		giants = "攻击当前生命值大于HP的生物伤害提升PTG%",
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
	acupuncture = function(info, lv)
		return {
			PTG = info.multi * lv * 100,
		}
	end,
	luna = function(info, lv)
		return {
			LND = info.land * lv * 100,
			FUL = info.full * lv * 100,
		}
	end,
	hypnosis = function(info, lv)
		return {
			PTG = info.multi * lv * 100,
		}
	end,
	sponge = function(info, lv)
		return {
			PNT = info.multi * lv,
			ITV = info.interval,
		}
	end,
	dancer = function(info, lv)
		return {
			PTG = info.multi * lv * 100,
		}
	end,
	d4c = function(info, lv)
		return {
			PTG = info.percent * 100,
		}
	end,
	dig = function(info, lv)
		return {
			DUR = info.duration + info.durationUnit * lv,
		}
	end,
	ge = function(info, lv)
		return {
			PTG = info.ptg * 100,
		}
	end,
	play = function(info, lv)
		return {
			PTG = info.weak * 100,
			DUR = info.duration,
		}
	end,
	migao = function(info, lv)
		return {
			PAN = info.pain * 100,
			PTG = info.multi * 100,
			TTL = info.multi * lv * 100,
		}
	end,
	johnWick = function(info, lv)
		return {
			ATK = info.multi * lv,
		}
	end,
	graveCloak = function(info, lv)
		return {
			ITV = info.interval,
			CNT = info.count,
			PTG = (info.def + info.defMulti * lv) * 100,
		}
	end,
	cooker = function(info, lv)
		return {
			PTG = info.multi * lv * 100,
		}
	end,
	giants = function(info, lv)
		return {
			PTG = info.multi * lv * 100,
			HP = info.hp,
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
		-- "taster",
		-- "sponge",
		-- "johnWick",
		-- "graveCloak",
		-- "cooker",
		"giants",
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