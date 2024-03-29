-- 开发模式
local dev_mode = aipGetModConfig("dev_mode") == "enabled"

local brain = require "brains/aip_mini_dou_brain"

local assets = {
    Asset("ANIM", "anim/aip_mini_doujiang.zip"),
}

local prefabs = {
    "aip_shadow_wrapper",
    "aip_score_ball_blueprint",
}

-- 配置
local language = aipGetModConfig("language")

local LANG_MAP = {
	english = {
		NAME = "Likeght",
		DESC = "It's cute!",
        NEED_RECIPE = "Are you ingenuity?",
        REQUIRE_PLAY = "Throw it to me~",
        BYE = "Want to eat Grape Sugar~",
        THROW_BALL = "I got it！",
        THROW_BALL_FAIL = "2 times to fall",
        THROW_BALL_REWARD = "Nice play~",
        WAIT_NEXT = "I've seen an Gaint. Maybe you have interested",
        CARDS = "Reciprocity~",
        WRONG_GIFT = "It's meaningless",
        TOTEM_RUBIK = "Shadow Rubik",
	},
	chinese = {
		NAME = "若光",
		DESC = "可爱的小家伙",
        NEED_RECIPE = "你会做豆豆球吗？",
        REQUIRE_PLAY = "把球打给我吧~",
        BYE = "想吃葡果棒~",
        THROW_BALL = "嗷呜！",
        THROW_BALL_FAIL = "落地两次不能算分啦",
        THROW_BALL_REWARD = "和你玩的真开心，谢谢",
        WAIT_NEXT = "我看到过一个大家伙，你也去看看吧",
        CARDS = "礼尚往来~",
        WRONG_GIFT = "我不需要它！",
        TOTEM_RUBIK = "暗影魔方",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

-- 文字描述
STRINGS.NAMES.AIP_MINI_DOUJIANG = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_MINI_DOUJIANG = LANG.DESC
STRINGS.AIP_MINI_DOUJIANG_NEED_RECIPE = LANG.NEED_RECIPE
STRINGS.AIP_MINI_DOUJIANG_REQUIRE_PLAY = LANG.REQUIRE_PLAY
STRINGS.AIP_MINI_DOUJIANG_BYE = LANG.BYE
STRINGS.AIP_MINI_DOUJIANG_THROW_BALL = LANG.THROW_BALL
STRINGS.AIP_MINI_DOUJIANG_THROW_BALL_FAIL = LANG.THROW_BALL_FAIL
STRINGS.AIP_MINI_DOUJIANG_THROW_BALL_REWARD = LANG.THROW_BALL_REWARD
STRINGS.AIP_MINI_DOUJIANG_WAIT_NEXT = LANG.WAIT_NEXT
STRINGS.AIP_MINI_DOUJIANG_CARDS = LANG.CARDS
STRINGS.AIP_MINI_DOUJIANG_WRONG_GIFT = LANG.WRONG_GIFT

------------------------------- 方法 -------------------------------
-- 按队列说话
local function say(inst, talkList, notLockSG)
    if inst.components.timer:TimerExists("aip_mini_dou_no_talk") then
        return
    end

    if inst.talkTask ~= nil then
        inst.talkTask:Cancel()
    end

    inst.talkList = talkList
    inst.talkIndex = 1
    inst.talkNotLockSG = notLockSG

    inst.talkTask = inst:DoPeriodicTask(2, function(inst)
        local talk = inst.talkList[inst.talkIndex]

        if talk ~= nil then
            inst.components.talker:Say(talk)
            if inst.talkNotLockSG ~= true then
                inst:PushEvent("talk")
            end

            inst.talkIndex = inst.talkIndex + 1
        else
            inst.talkTask:Cancel()
        end
    end,0)
end

-- 玩家靠近
local function onNear(inst, player)
    inst:DoTaskInTime(1, function()
        local x, y, z = inst.Transform:GetWorldPosition()
        local balls = TheSim:FindEntities(x, 0, z, 10, { "aip_score_ball" })
        local blueprints = aipFindNearEnts(inst, {"blueprint"}, nil, true)

        if
            player and not player.components.builder:KnowsRecipe("aip_score_ball") and
            not inst.components.timer:TimerExists("aip_mini_dou_dall_blueprints") and
            #balls == 0 and -- 附近有球也不提供图纸
            #blueprints == 0 -- 附近有图纸了
        then
            -- 如果玩家不会制作球就提供一个图纸
            inst.components.timer:StartTimer("aip_mini_dou_dall_blueprints", 300)
            inst.components.lootdropper:SpawnLootPrefab("aip_score_ball_blueprint")
            say(inst, { STRINGS.AIP_MINI_DOUJIANG_NEED_RECIPE })
        else
            say(inst, { STRINGS.AIP_MINI_DOUJIANG_REQUIRE_PLAY })
        end
    end)
end

local function resetDisapper(inst)
    inst.components.timer:StopTimer("aip_mini_dou_dall_disapper")
    inst.components.timer:StartTimer("aip_mini_dou_dall_disapper", dev_mode and 10 or 60)
end

-- 玩家远离
local function onFar(inst)
    if not inst.components.timer:TimerExists("aip_mini_dou_dall_88") then
        say(inst, { STRINGS.AIP_MINI_DOUJIANG_BYE }, true)
    end

    -- 总是重置计时器
    inst.components.timer:StopTimer("aip_mini_dou_dall_88")
    inst.components.timer:StartTimer("aip_mini_dou_dall_88", 30)
    resetDisapper(inst)
end

-- 击球
local function aipThrowBallBack(inst, ball)
    if ball == nil or not ball:IsValid() then
        return
    end

    local players = aipFindNearPlayers(inst, 20)
    local tgtEnt = players[1] or inst
    local tgtEntPos = tgtEnt:GetPosition()
    local tgtPos = aipGetSpawnPoint(tgtEntPos, 3) or tgtEntPos

    ball.components.aipc_score_ball:Throw(
        tgtPos,
        3 + math.random(),
        13 + math.random() * 2
    )

    -- 击球时重置消失时间，防止玩到一半消失了
    if inst.components.timer:TimerExists("aip_mini_dou_dall_disapper") then
        resetDisapper(inst)
    end

    -- 游戏时间内不允许说话
    inst.components.timer:StopTimer("aip_mini_dou_no_talk")
    inst.components.timer:StartTimer("aip_mini_dou_no_talk", 5)
end

-- 创建魔方挑战
local function createChallenge()
    local rubikTotem = false

    for i, totem in ipairs(TheWorld.components.world_common_store.flyTotems) do
        if totem.markType == "RUBIK" then
            rubikTotem = true
        end
    end

    if rubikTotem == false then
        local flyTotem = aipSpawnPrefab(nil, "aip_fly_totem", 3000, 0, 3000)
        flyTotem.components.writeable:SetText(LANG.TOTEM_RUBIK)
        flyTotem.markType = "RUBIK"
    end
end

-- 判断是否要给奖励
local function aipPlayEnd(inst, throwTimes)
    local rewardTimes = dev_mode and 2 or 4

    if throwTimes < rewardTimes then
        -- 得分太低
        say(inst, { STRINGS.AIP_MINI_DOUJIANG_THROW_BALL_FAIL })
    else
        -- 奖励物品 1 ~ 2 个葡萄
        local cnt = 1 + math.random() * 2
        for i = 1, cnt do
            inst.components.lootdropper:SpawnLootPrefab("aip_veggie_grape")
        end

        -- 奖励一张地图
        inst.components.lootdropper:SpawnLootPrefab("aip_map")

        say(inst, { STRINGS.AIP_MINI_DOUJIANG_THROW_BALL_REWARD, STRINGS.AIP_MINI_DOUJIANG_WAIT_NEXT })

        -- 提示信息时不允许打断说话
        inst.components.timer:StopTimer("aip_mini_dou_no_talk")
        inst.components.timer:StartTimer("aip_mini_dou_no_talk", 10)
    end
end

-- >>>>>>>>>>>>>>>>> 交易
local function AbleToAcceptTest(inst, item, giver)
	return true
end

local function AcceptTest(inst, item, giver)
    return item.prefab == "aip_food_grape_suger"
end

local function OnGetItemFromPlayer(inst, giver, item)
    inst.sg:GoToState("throw")
    inst:DoTaskInTime(0.3, function()
        inst.components.lootdropper:SpawnLootPrefab("aip_xiyou_card_package")
        say(inst, { STRINGS.AIP_MINI_DOUJIANG_CARDS }, true)
    end)
end

local function OnRefuseItem(inst, giver, item)
    say(inst, { STRINGS.AIP_MINI_DOUJIANG_WRONG_GIFT })
end

------------------------------- 实体 -------------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst, 50, .5)

    inst.Transform:SetFourFaced()

    inst:AddTag("aip_mini_doujiang")

    inst.AnimState:SetBank("aip_mini_doujiang")
    inst.AnimState:SetBuild("aip_mini_doujiang")
    inst.AnimState:PlayAnimation("idle_loop", true)

    inst.entity:SetPristine()

	inst:AddComponent("talker")
	inst.components.talker.fontsize = 30
	inst.components.talker.font = TALKINGFONT
	inst.components.talker.colour = Vector3(.9, 1, .9)
	inst.components.talker.offset = Vector3(0, -200, 0)

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("timer")

    inst:AddComponent("locomotor")
    inst.components.locomotor:EnableGroundSpeedMultiplier(false)
    inst.components.locomotor:SetTriggersCreep(false)
    inst.components.locomotor.walkspeed = 1
    inst.components.locomotor.runspeed = 4.5
    inst.components.locomotor.pathcaps = { allowocean = true }

    inst:SetStateGraph("SGaip_mini_dou")
	inst:SetBrain(brain)

    inst:AddComponent("inspectable")

    inst:AddComponent("knownlocations")

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetLoot({})

    -- 玩家靠近，提供一个皮球配方
    inst:AddComponent("playerprox")
    inst.components.playerprox:SetDist(5, 10)
    inst.components.playerprox:SetOnPlayerNear(onNear)
    inst.components.playerprox:SetOnPlayerFar(onFar)

    -- 接受葡果棒
    inst:AddComponent("trader")
    inst.components.trader:SetAbleToAcceptTest(AbleToAcceptTest)
    inst.components.trader:SetAcceptTest(AcceptTest)
    inst.components.trader.onaccept = OnGetItemFromPlayer
    inst.components.trader.onrefuse = OnRefuseItem

	-- 闪烁特效
	inst.AnimState:SetErosionParams(0, -0.125, -1.0)

    inst.persists = false

    inst:ListenForEvent("timerdone",  function(inst, data)
        if data.name == "aip_mini_dou_dall_disapper" then
            local effect = aipReplacePrefab(inst, "aip_shadow_wrapper")
	        effect.DoShow()

            if inst._aipTotem ~= nil then
                inst._aipTotem._aipMiniDou = nil
            end
        end
    end)

    inst.aipThrowBallBack = aipThrowBallBack
    inst.aipPlayEnd = aipPlayEnd

    return inst
end

return Prefab("aip_mini_doujiang", fn, assets, prefabs)