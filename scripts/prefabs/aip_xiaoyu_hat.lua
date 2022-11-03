local dev_mode = aipGetModConfig("dev_mode") == "enabled"

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
		DESC = "Advance ocean, more bullkelp!",
	},
	chinese = {
		NAME = "小渔",
		DESC = "无畏大海，更多海带！",
	},
}

TUNING.AIP_XIAOYU_HAT_FUEL = TUNING.YELLOWAMULET_FUEL * PERISH_MAP[dress_uses]

local LANG = LANG_MAP[language] or LANG_MAP.english

-- 文字描述
STRINGS.NAMES.AIP_XIAOYU_HAT = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_XIAOYU_HAT = LANG.DESC

-- 配方
local tempalte = require("prefabs/aip_dress_template")

----------------------------------- 事件 -----------------------------------
local function onHealthDelta(owner, data)
	local ptg = dev_mode and 0.01 or 0.66

	if owner ~= nil and owner:IsOnOcean(true) and data ~= nil and data.amount < 0 then
		data.amount = data.amount * ptg
	end
end

----------------------------------- 实例 -----------------------------------
return tempalte("aip_xiaoyu_hat", {
	rad = 0,
	fueled = {
		level = TUNING.AIP_XIAOYU_HAT_FUEL,
	},
	waterproofer = true,
	dapperness = TUNING.DAPPERNESS_TINY,
	onEquip = function(inst, owner)
		owner:AddTag("aip_xiaoyu_picker")
		owner:ListenForEvent("aip_healthdelta", onHealthDelta)
	end,
	onUnequip = function(inst, owner)
		owner:RemoveTag("aip_xiaoyu_picker")
		owner:RemoveEventCallback("aip_healthdelta", onHealthDelta)
	end,
})
