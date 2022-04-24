TUNING.NECTAR_SPEED_MULT = 1.75

TUNING.NECTAR_DRUNK_SPEED_MULT = 0.4 -- 喝醉时速度一会儿快一会儿慢

--[[local function RGB(r, g, b, a)
	return { r / 255, g / 255, b / 255, (a or 255) / 255 }
end]]

local QUALITY_COLORS = {
	quality_0 = {165,  42,  42},
	quality_1 = nil,
	quality_2 = { 59, 222,  99},
	quality_3 = { 80, 143, 244},
	quality_4 = {128,   0, 128},
	quality_5 = {208, 120,  86},
}

local LANG_MAP = {
	english = {
		NAME = "Nectar",
		DESC = "Made by nectar maker",

		contains = "Contains",
		littleOf = "Little of",
		lotsOf = "Lots of",
		fullOf = "Full of",
		
		health = "Health",
		hunger = "Hunger",
		sanity = "Sanity",

		frozen = "It's a bit cold",
		continueRecover = "Can continuely recover",
		speedMulti = "Movement speed up",
		suckBlook = "To be a vampire",
		damageMulti = "Cause more damage",
	},
	chinese = {
		NAME = "花蜜饮",
		DESC = "由花蜜制造机制作",
		
		contains = "含有",
		littleOf = "少量的",
		lotsOf = "富含",
		fullOf = "充满了",
		
		health = "生命力",
		hunger = "饱腹欲",
		sanity = "理智",
		
		frozen = "冰冰凉",
		continueRecover = "能够持续恢复",
		speedMulti = "跑步速度变快",
		suckBlook = "成为吸血鬼",
		damageMulti = "造成更多伤害",
	},
	russian = {
		NAME = "Нектар",
		DESC = "Сделан при помощи экстрактора",

		contains = "Содержит",
		littleOf = "Немного",
		lotsOf = "Много",
		fullOf = "Полон",
		
		health = "Здоровье",
		hunger = "Голод",
		sanity = "Рассудок",

		frozen = "Немного охлаждён",
		continueRecover = "Может восстанавливать здоровье",
		speedMulti = "Увеличение скорости передвижения",
		suckBlook = "Вампиризм",
		damageMulti = "Увеличение урона",
	},
}

local LANG_VALUE_MAP = {
	english = {
		fruit = "Fruit",
		flower = "Fragrant",
		sweetener = "Honey",
		frozen = "Frozen",
		exquisite = "Exquisite",
		nectar = "Mixed",
		light = "Shining",
		terrible = "Terrible",
		vampire = "Bloodthirsty",
		damage = "Warsong",
		starch = "buzzed",
		wine = "fermentation",

		tasteless = "Tasteless",
		balance = "Balance",
		absolute = "Absolute",
		impurity = "Impurity",
		generation = "L",

		quality_0 = "Bad Quality",
		quality_1 = "Normal Quality",
		quality_2 = "Nice Quality",
		quality_3 = "Great Quality",
		quality_4 = "Outstanding Quality",
		quality_5 = "Perfect Quality",
	},
	chinese = {
		fruit = "果香",
		flower = "清香",
		sweetener = "香甜",
		frozen = "冰镇",
		exquisite = "精酿",
		nectar = "混合",
		light = "光辉",
		terrible = "恐怖",
		vampire = "嗜血",
		damage = "战歌",
		starch = "微醺",
		wine = "酒香",

		tasteless = "平淡",
		balance = "平衡",
		absolute = "极纯",
		impurity = "混杂",
		generation = "代",

		quality_0 = "糟糕品质",
		quality_1 = "普通品质",
		quality_2 = "优秀品质",
		quality_3 = "精良品质",
		quality_4 = "杰出品质",
		quality_5 = "完美品质",
	},
	russian = {
		fruit = "Фрукт",
		flower = "Ароматный",
		sweetener = "Мёд",
		frozen = "Заморожен",
		Exquisite = "Изысканный",
		nectar = "Смешанный",
		light = "Светящийся",
		terrible = "Ужасный",
		vampire = "Кровожадность",
		damage = "Песнь войны",
		starch = "пьяный",
		wine = "Ферментация",

		tasteless = "Безвкусный",
		balance = "Сбалансированный",
		absolute = "Абсолютный",
		impurity = "С примесями",
		generation = "Ур. ",

		quality_0 = "Плохое качество",
		quality_1 = "Нормальное качество",
		quality_2 = "Хорошее качество",
		quality_3 = "Отличное качество",
		quality_4 = "Выдающееся качество",
		quality_5 = "Идеальное качество",
	},	
}

----------------------------------------------------------------------------
local HP = TUNING.HEALING_TINY -- 1 healing
local HU = TUNING.CALORIES_HUGE / 75 -- 1 hunger
local SAN = TUNING.SANITY_SUPERTINY -- 1 sanity
local PER = TUNING.PERISH_ONE_DAY -- 1 day
local TT = TUNING.FOOD_TEMP_AVERAGE / 10 -- 1 second

local VALUE_WEIGHT = {
	fruit =			{1.0, 0.1, 0.1, 1.0},
	flower =		{0.5, 1.0, 0.8, 1.0},
	sweetener =		{0.1, 1.0, 1.0, 1.0},
	frozen =		{1.0, 1.0, 1.0, 0.0},
	exquisite =		{1.0, 1.0, 1.0, 1.0},
	nectar =		{0.2, 0.2, 0.2, 1.0},
	light =			{1.0, 1.0, 1.0, 1.0},
	terrible =		{0.0, 0.0, 0.0, 1.0},
	vampire =		{1.0, 0.5, 0.5, 1.0},
	damage =		{0.5, 1.0, 1.0, 1.0},
	starch =		{1.0, 0.5, 1.0, 1.0},
	wine =			{1.0, 0.5, 0.5, 1.0},

	tasteless =		{1.0, 1.0, 1.0, 1.0},
	balance =		{1.0, 1.0, 1.0, 1.0},
	absolute =		{1.0, 1.0, 1.0, 1.0},
	generation =	{1.0, 1.0, 1.0, 1.0},
}

local VALUE_EAT_BONUS = {
	fruit = {
		health = HP * 3,
		hunger = HU * 4,
		sanity = SAN * 1,
	},
	flower = {
		health = HP * 1,
		hunger = HU * 0,
		sanity = SAN * 7,
	},
	sweetener = {
		health = HP * 6,
		hunger = HU * 1,
		sanity = SAN * 1,
	},
	frozen = {
		health = HP * 0,
		hunger = HU * 0,
		sanity = SAN * 3,
		temperature = TUNING.COLD_FOOD_BONUS_TEMP,
		temperatureduration = TT * 2,
	},
	exquisite = {
		health = HP * 0,
		hunger = HU * 0,
		sanity = SAN * 8,
	},
	nectar = {
		health = HP * 3,
		hunger = HU * 2,
		sanity = SAN * 3,
	},
	light = {
		health = HP * 0,
		hunger = HU * 0,
		sanity = SAN * 3,
	},
	terrible = {
		health = HP * -5,
		hunger = HU * 0,
		sanity = SAN * -5,
	},
	starch = {
		health = HP * 4,
		hunger = HU * 5,
		sanity = SAN * -1,
	},
	wine = {
		health = HP * 0,
		hunger = HU * 0,
		sanity = SAN * -3,
	},
}

return {
	QUALITY_COLORS = QUALITY_COLORS,
	LANG_MAP = LANG_MAP,
	LANG_VALUE_MAP = LANG_VALUE_MAP,
	VALUE_WEIGHT = VALUE_WEIGHT,
	VALUE_EAT_BONUS = VALUE_EAT_BONUS,
}
