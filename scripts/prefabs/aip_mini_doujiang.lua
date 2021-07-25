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
        REQUIRE_PLAY = "Let's play the B'all~",
        BYE = "Bye~",
        YOU_FIRST = "You first~",
	},
	chinese = {
		NAME = "若光",
		DESC = "可爱的小家伙",
        NEED_RECIPE = "你会做豆豆球吗？",
        REQUIRE_PLAY = "来和我拍球把~",
        BYE = "要走了吗？",
        YOU_FIRST = "你先来~",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

-- 文字描述
STRINGS.NAMES.AIP_MINI_DOUJIANG = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_MINI_DOUJIANG = LANG.DESC
STRINGS.AIP_MINI_DOUJIANG_NEED_RECIPE = LANG.NEED_RECIPE
STRINGS.AIP_MINI_DOUJIANG_REQUIRE_PLAY = LANG.REQUIRE_PLAY
STRINGS.AIP_MINI_DOUJIANG_BYE = LANG.BYE
STRINGS.AIP_MINI_DOUJIANG_YOU_FIRST = LANG.YOU_FIRST

------------------------------- 方法 -------------------------------
local function onNear(inst, player)
    inst:DoTaskInTime(1, function()
        if
            player and not player.components.builder:KnowsRecipe("aip_score_ball") and
            not inst.components.timer:TimerExists("aip_mini_dou_dall_blueprints")
        then
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

------------------------------- 实体 -------------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst, 50, .5)

    inst.Transform:SetFourFaced()

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
    inst.components.locomotor.walkspeed = TUNING.PIG_ELITE_WALK_SPEED
    inst.components.locomotor.runspeed = TUNING.PIG_ELITE_RUN_SPEED
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

    return inst
end

return Prefab("aip_mini_doujiang", fn, assets, prefabs)