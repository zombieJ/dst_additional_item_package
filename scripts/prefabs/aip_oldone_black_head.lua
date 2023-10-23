local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Unknow",
		DESC = "Whattttt is this?!",
        BUFF_NAME = "Sync Value",
        IM_BUFF_NAME = "Insanity",
        TALK_EXILED = "Where am I?",
	},
	chinese = {
		NAME = "不可知",
		DESC = "这这这这是什么？！",
        BUFF_NAME = "神形同步",
        IM_BUFF_NAME = "神志不清",
        TALK_EXILED = "我回到哪儿了？",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_OLDONE_BLACK_HEAD = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_BLACK_HEAD = LANG.DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_BLACK_HEAD_TALK_EXILED = LANG.TALK_EXILED

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_oldone_black_head.zip"),
}

------------------------------------ 配置 ------------------------------------
-- local MAX_HEALTH = 999999
local STATE_COUNT = 5
local DIST_MIN = 6
local DIST_MAX = 7

-- 添加计数器 Buffer
aipBufferRegister("aip_black_count", {
    name = LANG.BUFF_NAME,
    showFX = false,
})

-- 添加免疫 Buffer，有这个 buffer 就不能进入游戏
aipBufferRegister("aip_black_immunity", {
    name = LANG.IM_BUFF_NAME,
    showFX = false,
})

-- 添加传送 Buffer，会被立刻传送回去
aipBufferRegister("aip_black_portal", {
    hideBuffer = true,
    showFX = false,
    startFn = function(source, inst, info)
		-- 优先传送去 绚烂之门
        local pt = nil
        local portal = TheSim:FindFirstEntityWithTag("multiplayer_portal")
        aipSpawnPrefab(inst, "aip_shadow_wrapper").DoShow()

        if portal ~= nil then
            pt = portal:GetPosition()
        else
            pt = aipFindRandomPointInLand()
        end

        if inst.components.talker ~= nil then
            inst.components.talker:Say(
                STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_BLACK_HEAD_TALK_EXILED
            )
        end

        inst.Physics:Teleport(pt.x, 0, pt.z)
        aipSpawnPrefab(inst, "aip_shadow_wrapper").DoShow()
	end,
})

------------------------------------ 方法 ------------------------------------
local function onNear(inst, player)
    inst.components.aipc_blackhole_gamer:NearPlayer(player)
end

local function onFar(inst, player)
    inst.components.aipc_blackhole_gamer:FarPlayer(player)
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
    inst.AnimState:PlayAnimation("idle", true)

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

    inst:DoTaskInTime(0, function()
        aipSpawnPrefab(inst, "aip_aura_indicator")

        inst:SpawnChild("aip_oldone_black_head_eye1")._aipMaster = inst
        inst:SpawnChild("aip_oldone_black_head_eye2")._aipMaster = inst
        inst:SpawnChild("aip_oldone_black_head_eye3")._aipMaster = inst
    end)

    inst.persists = false

    return inst
end

------------------------------------ 实例 ------------------------------------
local function refreshState(inst)
    local stateIdx = math.random(inst._aipAnimState)

    inst.AnimState:PlayAnimation(inst._aipAnimName.."_"..stateIdx)
end

local function eye_fn(name)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:AddFollower()

    inst.AnimState:SetBank("aip_oldone_black_head")
    inst.AnimState:SetBuild("aip_oldone_black_head")
    inst.AnimState:PlayAnimation(name.."_1")

    inst:AddTag("NOCLICK")
    inst:AddTag("FX")

    inst.entity:SetPristine()

    inst._aipAnimName = name
    inst._aipAnimState = 3

    if not TheWorld.ismastersim then
        return inst
    end

    inst:ListenForEvent("animover", refreshState)

    inst:DoTaskInTime(0.1, function()
        if inst._aipMaster ~= nil then
            inst.Follower:FollowSymbol(inst._aipMaster.GUID, "bind_"..name, 0, 0, 0.1)
        end
    end)

    inst.persists = false

    return inst
end

local function eye1_fn()
    local inst = eye_fn("eye1")
    return inst
end

local function eye2_fn()
    local inst = eye_fn("eye2")
    return inst
end

local function eye3_fn()
    local inst = eye_fn("eye3")
    return inst
end

return Prefab("aip_oldone_black_head", fn, assets),
    Prefab("aip_oldone_black_head_eye1", eye1_fn, assets),
    Prefab("aip_oldone_black_head_eye2", eye2_fn, assets),
    Prefab("aip_oldone_black_head_eye3", eye3_fn, assets)
