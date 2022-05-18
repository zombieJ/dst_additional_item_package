-- 配置
local dress_uses = aipGetModConfig("dress_uses")
local language = aipGetModConfig("language")

-- 默认参数
local PERISH_MAP = {
	["less"] = 0.5,
	["normal"] = 1,
	["much"] = 2,
}

local LANG_MAP = {
	english = {
		NAME = "Fisher Hat",
		DESC = "Let's go fishing!",
	},
	chinese = {
		NAME = "鱼仔帽",
		DESC = "让我们盘一盘这个大海",
	},
}

TUNING.AIP_FISHER_FUEL = TUNING.YELLOWAMULET_FUEL * PERISH_MAP[dress_uses]

local LANG = LANG_MAP[language] or LANG_MAP.english

-- 文字描述
STRINGS.NAMES.AIP_OLDONE_FISHER = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_FISHER = LANG.DESC

-- 配方
local tempalte = require("prefabs/aip_dress_template")

----------------------------------- Buff -----------------------------------

----------------------------------- 实例 -----------------------------------
return tempalte("aip_oldone_fisher", {
	rad = 0,
	fueled = {
		level = TUNING.AIP_FISHER_FUEL,
	},
	waterproofer = true,
	onEquip = function(inst, owner)
		owner:AddTag("aip_oldone_good_fisher")
	end,
	onUnequip = function(inst, owner)
		owner:RemoveTag("aip_oldone_good_fisher")
	end,
})
