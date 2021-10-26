-- 配置
local dress_uses = aipGetModConfig("dress_uses")
local language = aipGetModConfig("language")

local LANG_MAP = {
	english = {
		NAME = "Haunted Wizard Hat",
		DESC = "I have 4 legs",
	},
	chinese = {
		NAME = "闹鬼巫师帽",
		DESC = "我感觉长了4条腿",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

-- 文字描述
STRINGS.NAMES.AIP_WIZARD_HAT = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_WIZARD_HAT = LANG.DESC

local function onremovebody(body)
    body._aipHat._aipEye = nil
end

-- 配方
local tempalte = require("prefabs/aip_dress_template")
return tempalte("aip_wizard_hat", {
	-- keepHead = true,
	waterproofer = true,
	onEquip = function(inst, owner)
		if inst._aipEye ~= nil then
			inst._aipEye:Remove()
		end
		inst._aipEye = SpawnPrefab("redlanternbody")
		inst._aipEye._aipHat = inst
		inst:ListenForEvent("onremove", onremovebody, inst._aipEye)

		inst._aipEye.entity:SetParent(owner.entity)
		inst._aipEye.entity:AddFollower()
		inst._aipEye.Follower:FollowSymbol(owner.GUID, "hair", 0, 0, 1)
	end,
	onUnequip = function(inst, owner)
		if inst._aipEye ~= nil then
			inst._aipEye:Remove()
		end
		inst._aipEye = nil
	end,
})
