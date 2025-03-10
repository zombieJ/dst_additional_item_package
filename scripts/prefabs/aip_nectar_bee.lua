-- 开发模式
local dev_mode = aipGetModConfig("dev_mode") == "enabled"

local brain = require("brains/aip_nectar_bee_brain")

local assets = {
    Asset("ANIM", "anim/aip_nectar_bee.zip"),
	Asset("SOUND", "sound/glommer.fsb"),
}


local language = aipGetModConfig("language")

local LANG_MAP = {
	english = {
		NAME = "Greedy Bumblebee",
		DESC = "Looks like it loves nectar",
		SAY_NEED_NECTAR = {
			"Where is nectar",
			"Sad, I can't make nectar",
			"Any delicious nectar?",
			"What's Nectar Maker?'",
			"Nectar can also make nectar",
			"Can nectar burn?"
		},
		SAY_NECTAR_BAD = "Not good",
		SAY_NECTAR_NORMAL = "Good. Do you know Magic Rubik can be ignited by hound?",
		SAY_NECTAR_GOOD = "It's delicious!",
		SAY_WELL_DONE = "You have completed the trial, this is the reward",
	},
	chinese = {
		NAME = "贪吃熊蜂",
		DESC = "它看起来很喜欢吃花蜜",
		SAY_NEED_NECTAR = {
			"好想吃花蜜呐",
			"可惜我不会做花蜜",
			"有好吃的花蜜吗",
			"花蜜酿造桶是什么？",
			"花蜜好像可以二次加工",
			"花蜜能燃烧吗？"
		},
		SAY_NECTAR_BAD = "这花蜜不咋地",
		SAY_NECTAR_NORMAL = "好吃。你知道 魔力方阵 可以被猎犬引火吗?",
		SAY_NECTAR_GOOD = "这花蜜真好吃",
		SAY_WELL_DONE = "你完成了试炼，这是奖励",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

-- 文字描述
STRINGS.NAMES.AIP_NECTAR_BEE = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_NECTAR_BEE = LANG.DESC

---------------------------------- 方法 ----------------------------------
local function say(inst, text)
	inst.components.timer:StopTimer("talked")
	inst.components.talker:Say(text)
	inst.components.timer:StartTimer("talked", 8)
end

-- 简易版 brain，不需要 Stage 配合
local function doBrain(inst)
	aipQueue({
		-------------------------- 奖励 --------------------------
        function()
			if inst.components.timer:TimerExists("giveFinalGift") then
				return true
			end

			-- TODO: 检查 buff，然后添加一下 buff 对应的图标
			local players = aipFindNearPlayers(inst, 3)

			for _, player in ipairs(players) do
				if aipBufferExist(player, "aip_torch_warm") then
					-- 如果没有学过就掉落一下配方，一分钟一次
					aipTypePrint("giveFinalGift", inst.components.timer:TimerExists("giveFinalGift"))
					aipTypePrint("player", player.components.builder:KnowsRecipe("aip_torch_stand_final"))
					if
						not inst.components.timer:TimerExists("giveFinalGift") and
						not player.components.builder:KnowsRecipe("aip_torch_stand_final")
					then
						inst._aipGift = "aip_torch_stand_final_blueprint"
						inst.sg:GoToState("gift")
						inst.components.timer:StartTimer("giveFinalGift", 60)
					end

					say(inst, LANG.SAY_WELL_DONE)
					return true
				end
			end
        end,

        -------------------------- 说话 --------------------------
        function()
            if inst.components.timer:TimerExists("talked") then
				return true
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

-- 接受玩家给的花蜜，然后提供奖励
local function validteFood(food)
    return food ~= nil and food:HasTag("aip_nectar")
end

local function ShouldAcceptItem(inst, item)
    return validteFood(item)
end

local function OnGetItemFromPlayer(inst, giver, item)
end

-- 吃下东西后，给与奖励
local function OnEat(inst, food)
	if validteFood(food) then
		local currentQuality = food.currentQuality or 0
		local text = nil
		local gift = nil

		if currentQuality <= 1 then
			text = LANG.SAY_NECTAR_BAD
		elseif currentQuality <= 3 then
			text = LANG.SAY_NECTAR_NORMAL
			gift = "aip_torch"
		else
			text = LANG.SAY_NECTAR_GOOD
			gift = "aip_torch_blueprint"
		end

		say(inst, text)

		-- 延迟一下送礼
		inst._aipGift = gift
    end
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
	inst:AddTag("aip_nectar_bee")

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
	inst.components.locomotor.pathcaps = {
		ignorewalls = true,
		ignorecreep = true,
		-- allowocean = true,
	}
	inst.components.locomotor.walkspeed = TUNING.CRAWLINGHORROR_SPEED

	inst:AddComponent("playerprox")
	inst.components.playerprox:SetDist(5, 8)
	inst.components.playerprox:SetOnPlayerNear(onNear)
	inst.components.playerprox:SetOnPlayerFar(onFar)

	inst:SetStateGraph("SGaip_nectar_bee")
	inst:SetBrain(brain)

	inst:AddComponent("aipc_timer")
	inst:AddComponent("timer")

	inst:AddComponent("inventory")

	inst:AddComponent("inspectable")

	inst:AddComponent("trader")
    inst.components.trader:SetAcceptTest(ShouldAcceptItem)
    inst.components.trader.onaccept = OnGetItemFromPlayer
    inst.components.trader.deleteitemonaccept = false

	inst:AddComponent("eater")
    inst.components.eater:SetDiet({ FOODGROUP.OMNI }, { FOODGROUP.OMNI })
    inst.components.eater:SetCanEatHorrible()
    inst.components.eater:SetCanEatRaw()
    inst.components.eater:SetStrongStomach(true)
    inst.components.eater:SetOnEatFn(OnEat)

	inst.persists = false

	return inst
end

return Prefab("aip_nectar_bee", fn, assets)
