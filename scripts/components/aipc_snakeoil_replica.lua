local language = aipGetModConfig("language")

local aip_nectar_config = require("prefabs/aip_nectar_config")
local NEC_COLORS = aip_nectar_config.QUALITY_COLORS

-- 文字描述
local LANG_MAP = {
	english = {
		vampire = "Vampire",
		blood = "Blood",
		week = "Week",
		repair = "Repair",
		free = "Flash",
		back = "Back",
		slow = "Obtuse",
		pain = "Pain",
	},
	chinese = {
		vampire = "吸血",
		blood = "流血",
		week = "虚弱",
		repair = "复苏",
		free = "游侠",
		back = "击退",
		slow = "断筋",
		pain = "痛击",
	},
}
local LANG = LANG_MAP[language] or LANG_MAP.english

-- 和 aipc_snakeoil.lua 配合使用，	-- 普通 1，优秀 2，精良 3，杰出 4，完美 5
local abilities = {
	vampire = {
		color = NEC_COLORS.quality_2,
	},
	blood ={
		color = NEC_COLORS.quality_2,
	},
	week = {
		color = NEC_COLORS.quality_3,
	},
	repair = {
		color = NEC_COLORS.quality_3,
	},
	free = {
		color = NEC_COLORS.quality_2,
	},
	back = {
		color = NEC_COLORS.quality_3,
	},
	slow = {
		color = NEC_COLORS.quality_2,
	},
	pain = {
		color = NEC_COLORS.quality_2,
	},
}

----------------------------------------------------------------
local SnakeOilReplica = Class(function(self, inst)
	self.inst = inst

	-- 存一下颜色
	self._ability = net_string(inst.GUID, "aipSnakeOil._ability", "aipSnakeOil._abilityDirty")
end)

function SnakeOilReplica:Sync(ability)
	self._ability:set(ability)
end

function SnakeOilReplica:GetAbility()
	return self._ability:value() or ""
end

-- 获取描述信息，用于在鼠标 hover 时展示
function SnakeOilReplica:GetInfo()
	local ability = self:GetAbility()

	if ability and ability ~= "" then
		local infoName = LANG[ability] or "???"
		local infoColor = abilities[ability] and abilities[ability].color or NEC_COLORS.quality_1

		return infoName, infoColor
	end
end

return SnakeOilReplica