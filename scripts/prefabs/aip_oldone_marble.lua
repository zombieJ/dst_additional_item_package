local dev_mode = aipGetModConfig("dev_mode") == "enabled"
local language = aipGetModConfig("language")
local createEffectVest = require("utils/aip_vest_util").createEffectVest

-- local brain = require("brains/aip_oldone_marble_brain")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Defaced Statue",
		DESC = "It has a heavy head",
        HEAD_NAME = "Head Part",
        HEAD_DESC = "This is the main part",
	},
	chinese = {
		NAME = "污损的雕像",
		DESC = "它的头似乎很沉重",
        HEAD_NAME = "头颅部件",
        HEAD_DESC = "这是它的本体",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_OLDONE_MARBLE = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_MARBLE = LANG.DESC

STRINGS.NAMES.AIP_OLDONE_MARBLE_HEAD = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_MARBLE_HEAD = LANG.DESC

local PHYSICS_RADIUS = .45
local PHYSICS_HEIGHT = 1
local PHYSICS_MASS = 10
local HEAD_WALK_SPEED = 1

---------------------------------- AI ----------------------------------
-- 简易版 brain，不需要 Stage 配合
local function doBrain(inst)
    aipQueue({
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
            head.Physics:SetCapsule(0, PHYSICS_HEIGHT)

            head.Physics:Teleport(px + 0.1, 30, pz + 0.1)
            head.Physics:SetMotorVel(0, -30, 0)

            -- 延迟一会儿炸开
            inst:DoTaskInTime(1, function()
                local sinkhole = aipSpawnPrefab(head, "antlion_sinkhole", nil, 0)
                sinkhole.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/sfx/ground_break")

                -- 变成可以搬动的状态
                -- head.Physics:Stop()
                head.Physics:Teleport(px + 0.1, 0, pz + 0.1)
                head.Physics:SetMotorVel(0, 0, 0)
                -- head.Physics:SetMass(0)
                head.Physics:SetCapsule(PHYSICS_RADIUS, PHYSICS_HEIGHT)

                -- 伤害附近的玩家
                local ents = TheSim:FindEntities(
                    px + 0.1, 0, pz + 0.1,
                    2.5,
                    { "_combat", "_health" },
                    { "INLIMBO", "NOCLICK", "ghost", "flying" }
                )

                for i, v in ipairs(ents) do
                    if v.components.combat ~= nil and v.components.health ~= nil and not v.components.health:IsDead() then
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

                                    -- 计算间距
                                    local dist = aipDist(
                                        inst._aipVest:GetPosition(),
                                        inst._aipHead:GetPosition()
                                    )

                                    -- 如果没有被搬走，我们就移除头颅
                                    if dist < 2 then
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
                                        head.persists = nil
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

local function onremovebody(body)
    body._aipBody._aipHead = nil
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 1.5)

    inst.AnimState:SetBank("aip_oldone_marble")
    inst.AnimState:SetBuild("aip_oldone_marble")
    inst.AnimState:PlayAnimation("idle", true)

    inst:AddTag("largecreature")
    inst:AddTag("monster")
    inst:AddTag("hostile")
    inst:AddTag("aip_oldone")

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

    -- 生命
    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(dev_mode and 100 or TUNING.STALKER_ATRIUM_HEALTH)
	inst.components.health.nofadeout = true

	inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "body"

    -- 寻找头部，如果存在则跳转至无头状态
    inst:DoTaskInTime(1, function()
        local head = aipFindEnt("aip_oldone_marble_head")
        inst._aipHead = head
        inst.AnimState:PlayAnimation("launch", false)
    end)

    return inst
end

--------------------------------- 头像 ---------------------------------
local headAssets = {
    Asset("ANIM", "anim/aip_oldone_marble_head.zip"),
    Asset("ATLAS", "images/inventoryimages/aip_oldone_marble_head.xml"),
}

local function getBody(inst)
    -- 找到自己的基座 Ents[GUID]
    local body = Ents[inst._aipBodyGUID]
    if body == nil then
        body = aipFindEnt("aip_oldone_marble")

        if body ~= nil then
            inst._aipBodyGUID = body.GUID
        end
    end

    return body
end

local function stopTryDrop(inst)
    if inst._aipDropTask ~= nil then
        inst._aipDropTask:Cancel()
        inst._aipDropTask = nil
    end
end

local function starTryDrop(inst)
    stopTryDrop(inst)

    local timeout = dev_mode and 3 or (6 + math.random() * 4)

    inst._aipDropTask = inst:DoTaskInTime(timeout, function()
        local body = getBody(inst)

        if body ~= nil then
            -- 如果手还在取回状态则重新等待
            if body._aipHand ~= nil then
                starTryDrop(inst)
                return
            end

            -- 尝试掉落
            local owner = inst.components.inventoryitem:GetGrandOwner()
            if owner ~= nil then
                owner.components.inventory:DropItem(inst, true, true)

                -- 掉落还要攻击一下携带者
                inst.AnimState:PlayAnimation("aipAttack")
                inst.AnimState:PushAnimation("aipJump", true)

                if owner.components.combat ~= nil then
                    owner.components.combat:GetAttacked(body, 10)
                end
            end
        end
    end)
end

local function stopTryBack(inst)
    if inst._aipBackTask ~= nil then
        inst._aipBackTask:Cancel()
        inst._aipBackTask = nil
    end

    inst.components.locomotor:Stop()
    inst.components.locomotor:Clear()
end

-- 尝试回到基处
local function startTryBack(inst)
    stopTryBack(inst)

    inst._aipBackTask = inst:DoPeriodicTask(2, function()
        local body = getBody(inst)

        if body ~= nil then
            -- 如果手还在，则先不做事情
            if body._aipHand ~= nil then
                return
            end


            local bodyPos = body:GetPosition()

            -- 如果已经到了附近就直接飞上去 aipJumpBack launchBack
            if aipDist(inst:GetPosition(), bodyPos) < 5 then
                inst.AnimState:PlayAnimation("aipJumpBack")
                inst:ListenForEvent("animover", function()
                    body.AnimState:PlayAnimation("launchBack")
                    body.AnimState:PushAnimation("idle", true)
                    inst:Remove()
                end)
                return
            end

            -- 继续往基座走
            inst.Physics:SetMass(PHYSICS_MASS)
            inst.Physics:CollidesWith(COLLISION.WORLD)
            inst.Physics:CollidesWith(COLLISION.OBSTACLES)
            inst.Physics:CollidesWith(COLLISION.SMALLOBSTACLES)

            if inst.Physics:GetMotorSpeed() <= 0 then
                inst.Physics:SetMotorVel(HEAD_WALK_SPEED, 0, 0)
            end

            inst.components.locomotor:GoToPoint(bodyPos)
        end
    end, 1)
end

local function onequip(inst, owner)
	owner.AnimState:OverrideSymbol("swap_body", "aip_oldone_marble_head", "swap_body")
    starTryDrop(inst)
    stopTryBack(inst)
end

local function onunequip(inst, owner)
	owner.AnimState:ClearOverrideSymbol("swap_body")
    stopTryDrop(inst)
    startTryBack(inst)
end

local function headFn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    -- MakeHeavyObstaclePhysics(inst, PHYSICS_RADIUS, PHYSICS_HEIGHT)
    -- MakeGiantCharacterPhysics(inst, 999, PHYSICS_RADIUS)
    MakeCharacterPhysics(inst, PHYSICS_MASS, PHYSICS_RADIUS)
    inst.Physics:CollidesWith(COLLISION.WORLD)

    inst.AnimState:SetBank("chesspiece")
    inst.AnimState:SetBuild("aip_oldone_marble_head")
    inst.AnimState:PlayAnimation("aipJump", true)

    inst:AddTag("heavy")

    MakeInventoryFloatable(inst, "med", nil, 0.65)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    -- 这个是头，别放错地方！

    inst:AddComponent("heavyobstaclephysics")
    inst.components.heavyobstaclephysics:SetRadius(PHYSICS_RADIUS)

    inst:AddComponent("inspectable")

    inst:AddComponent("lootdropper")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.cangoincontainer = false
    inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_oldone_marble_head.xml"

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.BODY
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    inst.components.equippable.walkspeedmult = TUNING.HEAVY_SPEED_MULT

    -- 也能自己回去
    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = HEAD_WALK_SPEED
    inst.components.locomotor.runspeed = HEAD_WALK_SPEED
    inst.components.locomotor.slowmultiplier = 1
    inst.components.locomotor.fastmultiplier = 1
	inst.components.locomotor:SetTriggersCreep(false)
    inst.components.locomotor.pathcaps = { ignorecreep = true } -- , allowocean = true

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

    -- 这个是头，别放错地方！

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
    Prefab("aip_oldone_marble_head", headFn, headAssets),
    Prefab("aip_oldone_marble_vest", vestFn, {})
