local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Unknow",
		DESC = "Whattttt is this?!",
	},
	chinese = {
		NAME = "不可知",
		DESC = "这这这这是什么？！",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_OLDONE_BLACK_HEAD = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_BLACK_HEAD = LANG.DESC

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_oldone_black_head.zip"),
}

------------------------------------ 配置 ------------------------------------
-- local MAX_HEALTH = 999999
local STATE_COUNT = 5
local DIST_MIN = 6
local DIST_MAX = 7

------------------------------------ 方法 ------------------------------------
local function refreshState(inst)
    local stateIdx = math.random(STATE_COUNT)

    inst.AnimState:PlayAnimation("idle"..stateIdx)
end

local function onNear(inst, player)
    player.components.talker:Say("What is this?!")
end

local function onFar(inst, player)
    player.components.talker:Say("Bye bye!")
end

------------------------------------ 实例 ------------------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, .5)

    inst.AnimState:SetBank("aip_oldone_black_head")
    inst.AnimState:SetBuild("aip_oldone_black_head")
    inst.AnimState:PlayAnimation("idle1")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("playerprox")
    inst.components.playerprox:SetTargetMode(inst.components.playerprox.TargetModes.AllPlayers)
	inst.components.playerprox:SetDist(DIST_MIN, DIST_MAX)
	inst.components.playerprox:SetOnPlayerNear(onNear)
	inst.components.playerprox:SetOnPlayerFar(onFar)

    inst:AddComponent("aipc_blackhole_gamer")

    MakeHauntableLaunch(inst)

    inst:ListenForEvent("animover", refreshState)

    inst:DoTaskInTime(0, function()
        inst:SpawnChild("aip_aura_indicator")
    end)

    inst.persists = false

    return inst
end

return Prefab("aip_oldone_black_head", fn, assets)
