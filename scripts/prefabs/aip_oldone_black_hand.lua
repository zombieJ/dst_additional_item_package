local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Hardened Tentacle",
		DESC = "It just came out suddenly!",
	},
	chinese = {
		NAME = "硬化触手",
		DESC = "突然就窜出来了！",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_OLDONE_BLACK_HAND = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_BLACK_HAND = LANG.DESC

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_oldone_black_hand.zip"),
}

------------------------------------ 方法 ------------------------------------
local function randomAnim(inst)
    inst.SoundEmitter:PlaySound("dontstarve/creatures/deerclops/attack")

    local idx = math.random(1, 5)
    inst.AnimState:PlayAnimation("atk"..idx)
    inst.AnimState:PushAnimation("stb"..idx, true)

    inst.Physics:SetActive(true)
    inst.components.health:SetInvincible(false)

    -- 攻击玩家
    local players = aipFindNearPlayers(inst, 0.1)
    for _, player in ipairs(players) do
        -- 玩家疼痛跳一下
        if player.components.combat ~= nil then
            player.components.combat:GetAttacked(inst, 1)
        end

        -- 伤害理智值
        if player.components.sanity ~= nil then
            player.components.sanity:DoDelta(-TUNING.SANITY_MEDLARGE)
        end
    end

    -- remove Event
    inst:RemoveEventCallback("animover", randomAnim)
end

local function onKilled(inst)
    inst:ListenForEvent("animover", inst.Remove)
    inst.AnimState:PlayAnimation("dead")
end

------------------------------------ 实例 ------------------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, .05)
    inst.Physics:SetActive(false)

    inst.AnimState:SetBank("aip_oldone_black_hand")
    inst.AnimState:SetBuild("aip_oldone_black_hand")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("hostile")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    MakeHauntableLaunch(inst)

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(1)
    inst.components.health:SetInvincible(true)

    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "body"

    inst:ListenForEvent("death", onKilled)
    inst:ListenForEvent("animover", randomAnim)

    inst.persists = false

    return inst
end

return Prefab("aip_oldone_black_hand", fn, assets)
