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

------------------------------------------- BUFF -------------------------------------------
aipBufferRegister("aip_hauntable_panic", {
	startFn = function(source, inst)
		if not inst._aipBufferPanic then
			local buff = aipSpawnPrefab(inst, "aip_buffer_panic")
			inst:AddChild(buff)
			buff.Transform:SetPosition(0, 0, 0)
			inst._aipBufferPanic = buff
		end
	end,

	endFn = function(source, inst)
		if inst._aipBufferPanic then
			inst:RemoveChild(inst._aipBufferPanic)
			aipRemove(inst._aipBufferPanic)
			inst._aipBufferPanic = nil
		end
	end,

	showFX = false,
})

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

	local lastTime = 3 -- 3秒

	-- 让猴子痛苦而逃跑
	for i, monkey in ipairs(monkeys) do
		if monkey.components.hauntable ~= nil then
			monkey.components.hauntable:Panic(lastTime)

			aipBufferPatch(inst, monkey, "aip_hauntable_panic", lastTime)
		end
	end
end

------------------------------------------- 实体 -------------------------------------------
local tempalte = require("prefabs/aip_dress_template")
return tempalte("aip_monkey_face", {
	keepHead = true,
	fueled = {
		level = TUNING.AIP_MONKEY_FACE_FUEL,
	},
	onEquip = function(inst, owner)
		inst.components.aipc_timer:NamedInterval("loopCheck", 0.3, loopCheck, 0, inst)
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
