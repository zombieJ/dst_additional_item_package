local dev_mode = aipGetModConfig("dev_mode") == "enabled"
local language = aipGetModConfig("language")
local createEffectVest = require("utils/aip_vest_util").createEffectVest

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Defaced Statue",
		DESC = "It has a heavy head",
	},
	chinese = {
		NAME = "污损的雕像",
		DESC = "它的头似乎很沉重",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_OLDONE_MARBLE = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_MARBLE = LANG.DESC

---------------------------------- AI ----------------------------------
local function IsDead(inst)
    return inst.components.health ~= nil and inst.components.health:IsDead()
end

local function findHead()
    return aipFindEnt("aip_oldone_marble_head", "aip_oldone_marble_head_lock")
end

-- 简易版 brain，不需要 Stage 配合
local function doBrain(inst)
    aipQueue({
        -------------------------- 尚未启动 --------------------------
        function()
            return inst._aipStart ~= true
        end,
        -------------------------- 已经死亡 --------------------------
        function()
            if IsDead(inst) then
                return true
            end
            return false
        end,
        -------------------------- 转手角度 --------------------------
        function()
            if inst._aipHead ~= nil and not inst._aipHead:IsValid() then
                inst._aipHead = nil
            end

            return inst._aipHead ~= nil
        end,
        ---------------------------- 等待 ----------------------------
        function()
            -- 播放特定动画
            if
                inst.AnimState:IsCurrentAnimation("throw") or
                inst.AnimState:IsCurrentAnimation("launch") or
                inst.AnimState:IsCurrentAnimation("launchBack") or
                inst.AnimState:IsCurrentAnimation("back")
            then
                return true
            end

            return false
        end,

        ------------------- 附近有玩家的时候投掷脓包 -------------------
        function()
            -- CD 中则不执行其他操作了
            if inst.components.timer:TimerExists("aip_throw") then
                return true
            end

            -- 没有玩家则跳过
            local players = aipFindNearPlayers(inst, 8)
            local player = aipRandomEnt(players)
            if player == nil then
                return false
            end

            inst.AnimState:PlayAnimation("throw")
            inst.AnimState:PushAnimation("idle", true)
            inst.components.timer:StartTimer("aip_throw", 1.55)
            local ball = aipSpawnPrefab(inst, "aip_oldone_plant_full")
            local x, y, z = player.Transform:GetWorldPosition()
            ball.components.complexprojectile:SetLaunchOffset(Vector3(0, 6, 0))
            ball.components.complexprojectile:Launch(
                Vector3(
                    x,
                    0,
                    z
                ),
                inst
            )
            ball._aipDuration = 1.5 -- 和正常的比持续更短的时间

            return true
        end,

        ------------ 如果附近没有玩家，则找远一点的玩家用头怼 ------------
        function()
            local players = aipFindNearPlayers(inst, 30)
            local player = aipRandomEnt(players)
            if player == nil then
                return false
            end

            inst.AnimState:PlayAnimation("launch", false)
            local head = aipSpawnPrefab(player, "aip_oldone_marble_head")
            head.persists = false -- 不允许保存
            inst._aipHead = head
            inst._aipBombPos = nil

            -- 马甲
            inst._aipVest = aipSpawnPrefab(player, "aip_oldone_marble_vest")

            local px, py, pz = player.Transform:GetWorldPosition()

            -- 让大理石暂时可以移动，落地后则继续不能移动
            -- head.Physics:SetMass(1)
            head.Physics:SetCapsule(0, 1)

            head.Physics:Teleport(px + 0.1, 30, pz + 0.1)
            head.Physics:SetMotorVel(0, -30, 0)

            -- 延迟一会儿炸开
            inst:DoTaskInTime(1, function()
                local sinkhole = aipSpawnPrefab(head, "antlion_sinkhole", nil, 0)
                sinkhole.persists = false -- 重启时消失
                sinkhole.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/sfx/ground_break")

                -- 变成可以搬动的状态
                -- head.Physics:Stop()
                head.Physics:Teleport(px + 0.1, 0, pz + 0.1)
                head.resetHeadPhysics(head)

                -- 伤害附近的玩家
                local ents = TheSim:FindEntities(
                    px + 0.1, 0, pz + 0.1,
                    2.5,
                    { "_combat", "_health" },
                    { "INLIMBO", "NOCLICK", "ghost", "flying" }
                )

                for i, v in ipairs(ents) do
                    if v.components.combat ~= nil and not IsDead(v) then
                        v.components.combat:GetAttacked(inst, 50)
                    end
                end

                -- 过一会儿开始暗触手去拿回头颅
                inst:DoTaskInTime(1, function()
                    local ix, iy, iz = inst.Transform:GetWorldPosition()
                    local hand = SpawnPrefab("shadowhand")
                    -- hand.components.locomotor.walkspeed = 0.5 -- 它走的很慢
                    hand.Transform:SetPosition(ix, 0, iz)
                    hand:SetTargetFire(inst._aipVest)

                    -- 给手注入一些数据
                    hand:RemoveComponent("playerprox") -- 不会被踩熄灭
                    hand:RemoveEventCallback("enterlight", hand.dissipatefn)
                    hand:RemoveEventCallback("enterlight", hand.dissipatefn)

                    -- 鬼手抓到后归位
                    hand:ListenForEvent("startaction", function(_, data)
                        if data.action ~= nil then
                            if data.action.action == ACTIONS.EXTINGUISH then
                                hand:DoTaskInTime(17 * FRAMES, function()
                                    -- 无论如何地震波都会消失
                                    if sinkhole ~= nil then
                                        ErodeAway(sinkhole)
                                    end

                                    if inst._aipVest ~= nil and inst._aipHead ~= nil then
                                        -- 计算间距
                                        local dist = aipDist(
                                            inst._aipVest:GetPosition(),
                                            inst._aipHead:GetPosition()
                                        )

                                        -- 如果没有被搬走，我们就移除头颅
                                        if dist < 2 and not IsDead(inst) then
                                            local owner = head.components.inventoryitem:GetGrandOwner()
                                            if owner ~= nil then
                                                owner.components.inventory:DropItem(head, true, true)
                                            end

                                            -- 播放一个特效
                                            local headPos = head:GetPosition()
                                            aipReplacePrefab(
                                                inst._aipVest,
                                                "aip_shadow_wrapper", headPos.x, headPos.y, headPos.z
                                            ).DoShow()

                                            head:Remove()
                                            inst._aipHead = nil

                                            -- 播放长回头颅的动画
                                            inst.AnimState:PlayAnimation("back")
                                            inst.AnimState:PushAnimation("idle", true)
                                        else
                                            -- 没有取回头颅，继续待机
                                            head.persists = true
                                        end
                                    end

                                    -- 清理无用引用
                                    inst._aipHand = nil
                                    inst._aipVest = nil
                                end)
                            end
                        end
                    end)

                    inst._aipHand = hand
                end)
            end)
        end,
    })
end

local function stopBrain(inst)
    if inst._aipBrain ~= nil then
        inst._aipBrain:Cancel()
    end

    inst._aipBrain = nil
end

local function startBrain(inst)
    stopBrain(inst)

    inst._aipBrain = inst:DoPeriodicTask(0.25, function()
		doBrain(inst)
	end, 0.1)
end

local function onNear(inst)
    startBrain(inst)
end

local function onFar(inst)
    stopBrain(inst)
end

--------------------------------- 雕塑 ---------------------------------
local assets = {
    Asset("ANIM", "anim/aip_oldone_marble.zip"),
}

local function onDeath(inst)
    aipSpawnPrefab(inst, "aip_shadow_wrapper").DoShow(2)
    inst.AnimState:PlayAnimation("broken", false)

    inst:DoTaskInTime(0.1, function()
        if inst._aipHead == nil then
            local head = findHead()
            if head == nil then
                inst.components.lootdropper:DropLoot()
                inst.components.lootdropper:SpawnLootPrefab("aip_oldone_marble_head")
            end
        end
        inst._aipHead = nil
    end)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 1.2)

    inst.AnimState:SetBank("aip_oldone_marble")
    inst.AnimState:SetBuild("aip_oldone_marble")
    inst.AnimState:PlayAnimation("idle", true)

    inst:AddTag("largecreature")
    inst:AddTag("monster")
    inst:AddTag("hostile")
    inst:AddTag("aip_oldone")
    inst:AddTag("aip_oldone_marble")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("timer")

    inst:AddComponent("inspectable")

    inst:AddComponent("playerprox")
	inst.components.playerprox:SetDist(15, 30)
	inst.components.playerprox:SetOnPlayerNear(onNear)
	inst.components.playerprox:SetOnPlayerFar(onFar)

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetLoot({"marble","marble","marble"})

    -- 生命
    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(dev_mode and 100 or TUNING.STALKER_ATRIUM_HEALTH)
	inst.components.health.nofadeout = true
    inst:ListenForEvent("death", onDeath)

	inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "body"

    -- 寻找头部，如果存在则跳转至无头状态
    inst:DoTaskInTime(1, function()
        if IsDead(inst) then
            inst.AnimState:PlayAnimation("broken", false) -- 死了就不用管了
        else
            local head = findHead()

            if head ~= nil then
                inst._aipHead = head
                inst.AnimState:PlayAnimation("launch", false)
            end
        end

        inst._aipStart = true
    end)

    return inst
end

--------------------------------- 马甲 ---------------------------------
local function vestFn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    MakeSmallObstaclePhysics(inst, 0, 0)

    inst:AddTag("NOCLICK")
    inst:AddTag("fx")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    -- 添加一个火，从而让手可以拿走它
    inst:AddComponent("burnable")
    inst:AddComponent("fueled")
    inst.components.fueled.maxfuel = TUNING.CAMPFIRE_FUEL_MAX
    inst.components.fueled.accepting = false
    inst.components.fueled:SetSections(4)
    inst.components.fueled:InitializeFuelLevel(TUNING.CAMPFIRE_FUEL_MAX)
    inst.components.fueled:StopConsuming()

    inst.persists = false

    return inst
end

return Prefab("aip_oldone_marble", fn, assets),
    Prefab("aip_oldone_marble_vest", vestFn, {})
