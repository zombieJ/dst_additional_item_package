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

------------------------------------ 洞洞实例 ------------------------------------
local function replaceWithHand(inst)
    aipReplacePrefab(inst, "aip_oldone_black_hand_stick")
end

local function holeFn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("aip_oldone_black_hand")
    inst.AnimState:SetBuild("aip_oldone_black_hand")
    inst.AnimState:PlayAnimation("idle")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:ListenForEvent("animover", replaceWithHand)

    inst.persists = false

    return inst
end

------------------------------------ 手手实例 ------------------------------------
local function birthAttack(inst)
    inst.SoundEmitter:PlaySound("dontstarve/creatures/deerclops/attack")

    local idx = math.random(1, 5)
    inst.AnimState:PlayAnimation("atk"..idx)
    inst.AnimState:PushAnimation("stb"..idx, true)

    -- 攻击玩家
    local players = aipFindNearPlayers(inst, 1)
    for _, player in ipairs(players) do
        -- 玩家疼痛跳一下
        if player.components.combat ~= nil then
            player.components.combat:GetAttacked(inst, 0.00001)
        end

        -- 伤害理智值
        if player.components.sanity ~= nil then
            player.components.sanity:DoDelta(-TUNING.SANITY_MEDLARGE)
        end

        -- 伤害同步率
        if aipBufferExist(player, "aip_black_count") then
            aipBufferPatch(inst, player, "aip_black_count", 9999999, function(info)
                local nextStack = (info.stack or 1) - 1

                if nextStack <= 0 then
                    aipBufferRemove(player, "aip_black_count")
                    aipBufferPatch(inst, player, "aip_black_immunity", 60 * 10)

                    aipBufferPatch(inst, player, "aip_black_portal", 0.001)
                end

                return nextStack
            end)
        end
    end
end

local function onKilled(inst)
    inst:ListenForEvent("animover", inst.Remove)
    inst.AnimState:PlayAnimation("dead")
end

local function handFn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, .05)

    inst.AnimState:SetBank("aip_oldone_black_hand")
    inst.AnimState:SetBuild("aip_oldone_black_hand")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("hostile")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(1)

    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "body"

    inst:ListenForEvent("death", onKilled)

    inst:DoTaskInTime(0.1, birthAttack)

    inst.persists = false

    return inst
end

return  Prefab("aip_oldone_black_hand", holeFn, assets),
        Prefab("aip_oldone_black_hand_stick", handFn, assets)
