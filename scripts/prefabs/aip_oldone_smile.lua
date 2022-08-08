local dev_mode = aipGetModConfig("dev_mode") == "enabled"

local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Rift Smiler",
		DESC = "Indescribable!",
	},
	chinese = {
		NAME = "裂隙笑颜",
		DESC = "不可名状！",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_OLDONE_SMILE = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_SMILE = LANG.DESC

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_oldone_smile.zip"),
}

---------------------------------- 事件 ----------------------------------
local function syncErosion(inst, alpha)
    local tgtAlpha = math.min(1 - alpha, 1)
    tgtAlpha = math.max(tgtAlpha, 0)

    inst.AnimState:SetErosionParams(tgtAlpha, -0.125, -1.0)
    inst.AnimState:SetMultColour(1, 1, 1, alpha)
end

local SPEED = TUNING.CRAWLINGHORROR_SPEED / 3 / 2 -- 移动很慢，但是很可怕 0.5
local GHOST_RANGE = 5 -- 幽灵创建距离

local GHOST_REDUCE_HEALTH = dev_mode and 10 or 100  -- 每个幽灵扣除笑脸数值
local GHOST_REDUCE_PLAYER = dev_mode and 80 or 25   -- 每个幽灵扣除玩家数值
local MAX_HEALTH = GHOST_REDUCE_HEALTH * 25         -- 笑脸生命值

local function doBrain(inst)
    aipQueue({
        -------------------------- 寻找地毯 --------------------------
        function()
            local pt = inst:GetPosition()
            local watchers = TheSim:FindEntities(pt.x, pt.y, pt.z, 50, { "aip_oldone_smile_active" })

            local tgtPT = nil

            -- 找附近激活的地毯
            local closeWatcher = aipFindCloseEnt(inst, watchers)
            if closeWatcher ~= nil then
                tgtPT = closeWatcher:GetPosition()
            end

            -- 走向地毯
            if tgtPT ~= nil then
                inst:ForceFacePoint(tgtPT.x, 0, tgtPT.z)
                inst.Physics:SetMotorVel(
                    SPEED,
                    0,
                    0
                )

                -- 慢慢显现
                inst._aip_fade_cnt = math.min(1, inst._aip_fade_cnt + 0.08)
                syncErosion(inst, inst._aip_fade_cnt)

                ---------------------- 如果离玩家比较远就创建小幽魂 ----------------------
                local players = aipFindNearPlayers(inst, 20)
                players = aipFilterTable(players, function(player)
                    return aipDist(pt, player:GetPosition()) >= GHOST_RANGE
                end)

                for i, player in ipairs(players) do
                    if
                        player.components.timer ~= nil and
                        not player.components.timer:TimerExists("aip_oldone_sading")
                    then
                        player.components.timer:StartTimer("aip_oldone_sading", 3)

                        local ghost = aipSpawnPrefab(player, "aip_oldone_sad")
                        if ghost.components.homeseeker ~= nil then
                            ghost.components.homeseeker:SetHome(inst)
                        end

                        -- 扣除总量
                        local restValue = GHOST_REDUCE_PLAYER
                        ghost._aip_sanity = 0
                        ghost._aip_hunger = 0

                        -- 扣除玩家的理智值
                        if player.components.sanity ~= nil then
                            local validSanity = math.min(GHOST_REDUCE_PLAYER, player.components.sanity.current)
                            player.components.sanity:DoDelta(-validSanity)
                            ghost._aip_sanity = validSanity
                            restValue = restValue - validSanity
                        end

                        -- 扣除玩家的饥饿
                        restValue = restValue / 2 -- 失去饥饿为理智的 1/2
                        if restValue > 0 and player.components.hunger ~= nil then
                            local validHunger = math.min(restValue, player.components.hunger.current)
                            player.components.hunger:DoDelta(-validHunger)
                            ghost._aip_hunger = validHunger
                        end
                    end
                end
            else -- 没有地毯就停下来
                inst.Physics:Stop()
            end

            return tgtPT ~= nil
        end,

        -------------------------- 慢慢消失 --------------------------
        function()
            inst._aip_fade_cnt = math.max(0, inst._aip_fade_cnt - 0.04)
            syncErosion(inst, inst._aip_fade_cnt)

            if inst._aip_fade_cnt <= 0 then
                aipRemove(inst)
            end

            return true
        end,
    })
end

-- 吃掉小怪物
local function eatSad(inst)
    local pt = inst:GetPosition()
    local sadList = TheSim:FindEntities(pt.x, pt.y, pt.z, 2, { "aip_oldone_sad" })

    for i, sad in ipairs(sadList) do
        if sad.components.health ~= nil then
            if not sad.components.health:IsDead() then -- 如果没死就吃掉
                sad.components.health:Kill()

                -- 扣血咯
                inst.components.health:DoDelta(-GHOST_REDUCE_HEALTH)
            end
        else
            aipRemove(sad)
        end
    end
end

---------------------------------- 实例 ----------------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    inst.DynamicShadow:SetSize(4, 2)

    MakeFlyingGiantCharacterPhysics(inst, 500, 1.4)

    inst.AnimState:SetBank("aip_oldone_smile")
    inst.AnimState:SetBuild("aip_oldone_smile")
    inst.AnimState:PlayAnimation("idle", true)

    inst:AddTag("aip_oldone_smile")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("aipc_timer")

    inst:AddComponent("locomotor")
    inst.components.locomotor:EnableGroundSpeedMultiplier(false)
    inst.components.locomotor:SetTriggersCreep(false)
    inst.components.locomotor.pathcaps = { ignorewalls = true, allowocean = true }
    inst.components.locomotor.walkspeed = TUNING.BEEQUEEN_SPEED

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(MAX_HEALTH)

	inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "body"

    -- 闪烁特效
    syncErosion(inst, 0)
    inst._aip_fade_cnt = 0
    inst.components.aipc_timer:NamedInterval("doBrain", 0.25, doBrain)
    inst.components.aipc_timer:NamedInterval("eatSad", 0.25, eatSad)

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("aip_oldone_smile", fn, assets)
