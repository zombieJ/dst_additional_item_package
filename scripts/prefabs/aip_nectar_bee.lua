-- 开发模式
local dev_mode = aipGetModConfig("dev_mode") == "enabled"

local brain = require("brains/aip_slime_mold_brain")

local assets = {
    Asset("ANIM", "anim/aip_nectar_bee.zip"),
	Asset("SOUND", "sound/glommer.fsb"),
}


local language = aipGetModConfig("language")

local LANG_MAP = {
	english = {
		NAME = "Greedy Bumblebee",
		SAY_NEED_NECTAR = {
			"Where is nectar",
			"Sad, I can't make nectar",
			"Any delicious nectar?",
			"What's Nectar Maker?'",
			"Nectar can also make nectar",
			"Can nectar burn?"
		},
	},
	chinese = {
		NAME = "贪吃熊蜂",
		SAY_NEED_NECTAR = {
			"好想吃花蜜呐",
			"可惜我不会做花蜜",
			"有好吃的花蜜吗",
			"花蜜酿造桶是什么？",
			"花蜜好像可以二次加工",
			"花蜜能燃烧吗？"
		},
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

-- 文字描述
STRINGS.NAMES.AIP_DRAGON = LANG.NAME

---------------------------------- 方法 ----------------------------------
local function say(inst, text)
	inst.components.talker:Say(text)
	inst.components.timer:StartTimer("talked", 8)
end

-- 简易版 brain，不需要 Stage 配合
local function doBrain(inst)
	aipQueue({
        -------------------------- 说话 --------------------------
        function()
            if inst.components.timer:TimerExists("talked") then
				return
			end
	
			-- 随机花蜜
			local text = aipRandomEnt(LANG.SAY_NEED_NECTAR)
			say(inst, text)
			return true
        end,
	})
end

-- 如果玩家靠近，就喊着要吃 花蜜
local function onNear(inst, player)
	inst.components.aipc_timer:NamedInterval("talkCheck", 0.5, function()
		doBrain(inst)
	end)
end

local function onFar(inst, player)
	inst.components.aipc_timer:KillName("talkCheck")
end

---------------------------------- 实例 ----------------------------------
local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    inst.DynamicShadow:SetSize(2, .75)

	MakeGhostPhysics(inst, 1, .5)

	inst.Transform:SetFourFaced()
	-- inst.Transform:SetScale(2, 2, 2)

    inst:AddTag("flying")
    inst:AddTag("ignorewalkableplatformdrowning")

	inst.AnimState:SetBank("aip_nectar_bee")
	inst.AnimState:SetBuild("aip_nectar_bee")
	inst.AnimState:PlayAnimation("idle_loop", true)
	-- inst.AnimState:SetMultColour(1, 1, 1, .7)

	inst.entity:SetPristine()

	inst:AddComponent("talker")
	inst.components.talker.fontsize = 35
	inst.components.talker.font = TALKINGFONT
	inst.components.talker.offset = Vector3(0, -500, 0)

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
	inst.components.locomotor:EnableGroundSpeedMultiplier(false)
	inst.components.locomotor:SetTriggersCreep(false)
	inst.components.locomotor.pathcaps = { ignorewalls = true, ignorecreep = true, allowocean = true }
	inst.components.locomotor.walkspeed = TUNING.CRAWLINGHORROR_SPEED

	inst:AddComponent("playerprox")
	inst.components.playerprox:SetDist(5, 8)
	inst.components.playerprox:SetOnPlayerNear(onNear)
	inst.components.playerprox:SetOnPlayerFar(onFar)

	inst:SetStateGraph("SGaip_slime_mold")
	inst:SetBrain(brain)

	inst:AddComponent("aipc_timer")
	inst:AddComponent("timer")

	inst.persists = false

	return inst
end

return Prefab("aip_nectar_bee", fn, assets)