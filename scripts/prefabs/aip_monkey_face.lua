-- 配置
local dress_uses = aipGetModConfig("dress_uses")
local weapon_damage = aipGetModConfig("weapon_damage")
local language = aipGetModConfig("language")

-- 默认参数
local PERISH_MAP = {
	less = 0.5,
	normal = 1,
	much = 2,
}

local LANG_MAP = {
	english = {
		NAME = "UN-Monkey Face",
		REC_DESC = "A mask that monkeys fear",
		DESC = "Is this an orangutan?",
	},
	chinese = {
		NAME = "驱猴面具",
		REC_DESC = "猴子都害怕的面具",
		DESC = "这是猩猩，还是土著？",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

TUNING.AIP_MONKEY_FACE_FUEL = TUNING.ONEMANBAND_PERISHTIME * PERISH_MAP[dress_uses]

-- 文字描述
STRINGS.NAMES.AIP_MONKEY_FACE = LANG.NAME
STRINGS.RECIPE_DESC.AIP_MONKEY_FACE = LANG.REC_DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_MONKEY_FACE = LANG.DESC

------------------------------------------- 方法 -------------------------------------------
local function onFueled(inst, item, doer)
	if inst.components.fueled ~= nil then
		inst.components.fueled:SetPercent(1)
	end
end

local function loopCheck(inst)
	local dist = 5
	local x, y, z = inst.Transform:GetWorldPosition()
	local monkeys = TheSim:FindEntities(
		x, y, z, dist,
		{ "monkey", "_health" },
		{ "INLIMBO", "player", "engineering" }
	)

	-- TODO: 让猴子逃跑
end

------------------------------------------- 实体 -------------------------------------------
local tempalte = require("prefabs/aip_dress_template")
return tempalte("aip_monkey_face", {
	keepHead = true,
	fueled = {
		level = TUNING.AIP_MONKEY_FACE_FUEL,
	},
	onEquip = function(inst, owner)
		inst.components.aipc_timer:NamedInterval("loopCheck", 1, loopCheck, inst)
	end,
	onUnequip = function(inst, owner)
		inst.components.aipc_timer:KillName("loopCheck")
	end,
	preInst = function(inst)
		-- 双端通用的匹配
		inst:AddComponent("aipc_fueled")
		inst.components.aipc_fueled.prefab = "aip_oldone_plant_broken"
		inst.components.aipc_fueled.onFueled = onFueled
	end,
	postInst = function(inst)
		inst:AddComponent("aipc_timer")
	end,
})
