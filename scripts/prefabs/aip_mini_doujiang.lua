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
        BYE = "Bye~",
        THROW_BALL = "I got it！",
	},
	chinese = {
		NAME = "若光",
		DESC = "可爱的小家伙",
        NEED_RECIPE = "你会做豆豆球吗？",
        REQUIRE_PLAY = "把球打给我吧~",
        BYE = "要走了吗？",
        THROW_BALL = "嗷呜！",
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

------------------------------- 方法 -------------------------------
-- 玩家靠近
local function onNear(inst, player)
    -- 如果附近有球就不提示了
    local x, y, z = inst.Transform:GetWorldPosition()
    local balls = TheSim:FindEntities(x, 0, z, 10, { "aip_score_ball" })
    if #balls > 0 then
        return
    end

    inst:DoTaskInTime(1, function()
        if
            player and not player.components.builder:KnowsRecipe("aip_score_ball") and
            not inst.components.timer:TimerExists("aip_mini_dou_dall_blueprints")
        then
            -- 如果玩家不会制作球就提供一个图纸
            inst.components.timer:StartTimer("aip_mini_dou_dall_blueprints", 300)
            inst.components.lootdropper:SpawnLootPrefab("aip_score_ball_blueprint")
            inst.components.talker:Say(STRINGS.AIP_MINI_DOUJIANG_NEED_RECIPE)
            inst:PushEvent("talk")
        else
            inst.components.talker:Say(STRINGS.AIP_MINI_DOUJIANG_REQUIRE_PLAY)
            inst:PushEvent("talk")
        end
    end)
end

-- 玩家远离
local function onFar(inst)
    if not inst.components.timer:TimerExists("aip_mini_dou_dall_88") then
        inst.components.talker:Say(STRINGS.AIP_MINI_DOUJIANG_BYE)
    end

    -- 总是重置计时器
    inst.components.timer:StopTimer("aip_mini_dou_dall_88")
    inst.components.timer:StartTimer("aip_mini_dou_dall_88", 30)
    inst.components.timer:StopTimer("aip_mini_dou_dall_disapper")
    inst.components.timer:StartTimer("aip_mini_dou_dall_disapper", 60)
end

-- 击球
local function aipThrowBallBack(inst, ball)
    local players = aipFindNearPlayers(inst, 20)
    local tgtEnt = players[1] or inst
    local tgtPos = aipGetSpawnPoint(tgtEnt:GetPosition(), 2)

    ball.components.aipc_score_ball:Throw(
        tgtPos,
        3 + math.random(),
        13 + math.random() * 2
    )
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
    inst.AnimState:PlayAnimation("idle", true)

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
    inst.components.locomotor.walkspeed = 2
    inst.components.locomotor.runspeed = 4
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

	-- 闪烁特效
	inst.AnimState:SetErosionParams(0, -0.125, -1.0)

    inst.persists = false

    inst:ListenForEvent("timerdone",  function(inst, data)
        if data.name == "aip_mini_dou_dall_disapper" then
            local effect = aipReplacePrefab(inst, "aip_shadow_wrapper")
	        effect.DoShow()
        end
    end)

    inst.aipThrowBallBack = aipThrowBallBack

    return inst
end

return Prefab("aip_mini_doujiang", fn, assets, prefabs)