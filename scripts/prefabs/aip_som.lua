local foldername = KnownModIndex:GetModActualName(TUNING.ZOMBIEJ_ADDTIONAL_PACKAGE)

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
	["english"] = {
		["NAME"] = "SOM",
		["REC_DESC"] = "Hello Everyone!",
		["DESC"] = "New come? Good bye~",
	},
	["chinese"] = {
		["NAME"] = "谜之声",
		["REC_DESC"] = "诶！大家好！",
		["DESC"] = "有人刚来吗？晚安晚安~",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

TUNING.AIP_SOM_FUEL = TUNING.YELLOWAMULET_FUEL * PERISH_MAP[dress_uses]

-- 文字描述
STRINGS.NAMES.AIP_SOM = LANG.NAME
STRINGS.RECIPE_DESC.AIP_SOM = LANG.REC_DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_SOM = LANG.DESC

local refreshInterval = 0.1

local tempalte = require("prefabs/aip_dress_template")
return tempalte("aip_som", {
	prefabs = { "aip_vest" },
	hideHead = true,
	fueled = {
		level = TUNING.AIP_SOM_FUEL,
	},
	dapperness = TUNING.DAPPERNESS_TINY,

	onEquip = function(inst, owner)
		-- 添加光环
		local follower = SpawnPrefab("aip_vest")

		follower:AddComponent("sanityaura")
		follower.components.sanityaura.aura = TUNING.DAPPERNESS_LARGE

		inst._follower = follower

		inst._auraTask = inst:DoPeriodicTask(refreshInterval, function()
			follower.Transform:SetPosition(owner.Transform:GetWorldPosition())
		end)
	end,
	onUnequip = function(inst, owner)
		-- 移除光环
		inst._auraTask:Cancel()
		inst._auraTask = nil
		inst._follower:Remove()
	end,
})