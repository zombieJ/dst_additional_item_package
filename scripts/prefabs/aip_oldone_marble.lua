local dev_mode = aipGetModConfig("dev_mode") == "enabled"
local language = aipGetModConfig("language")

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

--------------------------------- 雕塑 ---------------------------------
-- 简易版 brain，不需要 Stage 配合
local function doBrain(inst)
    aipQueue({
        ------------------------- 控制头攻击 -------------------------
        function()
            if inst._aipHead == nil then
                return false
            end

            -- 按照目标位置开始爆炸
            if inst._aipBombPos ~= nil and not inst.components.timer:TimerExists("aip_bomb") then
                inst.components.timer:StartTimer("aip_bomb", 0.15)

                local cx = inst._aipBombPos.x
                local cy = inst._aipBombPos.y
                local cz = inst._aipBombPos.z

                local tgtPos = inst._aipHead:GetPosition()

                local ptg = 0.8
                local nPtg = 1 - ptg

                local ox = cx * ptg + tgtPos.x * nPtg
                local oy = cy * ptg + tgtPos.y * nPtg
                local oz = cz * ptg + tgtPos.z * nPtg

                aipSpawnPrefab(inst, "aip_shadow_wrapper", ox, oy, oz).DoShow()

                inst._aipBombPos.x = ox
                inst._aipBombPos.y = oy
                inst._aipBombPos.z = oz

                if aipDist(inst._aipBombPos, tgtPos) < 0.25 then
                    inst._aipHead:Remove()
                    inst._aipHead = nil
                    inst.AnimState:PlayAnimation("idle", true)
                end
            end

            return true
        end,

        ------------------- 附近有玩家的时候投掷脓包 -------------------
        function()
            -- CD 中则不执行其他操作了
            if inst.components.timer:TimerExists("aip_throw") then
                return true
            end

            -- 没有玩家则跳过
            local players = aipFindNearPlayers(inst, 6)
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
            inst._aipHead = aipSpawnPrefab(player, "aip_oldone_marble_head")
            inst._aipBombPos = nil

            local px, py, pz = player.Transform:GetWorldPosition()

            -- 让大理石暂时可以移动，落地后则继续不能移动
            inst._aipHead.Physics:SetMass(1)
            inst._aipHead.Physics:SetCapsule(0, PHYSICS_HEIGHT)

            inst._aipHead.Physics:Teleport(px + 0.1, 30, pz + 0.1)
            inst._aipHead.Physics:SetMotorVel(0, -30, 0)

            -- 延迟一会儿炸开
            inst:DoTaskInTime(1, function()
                local sinkhole = aipSpawnPrefab(inst._aipHead, "antlion_sinkhole", nil, 0)
                sinkhole.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/sfx/ground_break")

                -- 变成可以搬动的状态
                inst._aipHead.Physics:Stop()
                inst._aipHead.Physics:Teleport(px + 0.1, 0, pz + 0.1)
                inst._aipHead.Physics:SetMass(0)
                inst._aipHead.Physics:SetCapsule(PHYSICS_RADIUS, PHYSICS_HEIGHT)

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
                    -- inst._aipBombPos = inst:GetPosition()
                    inst._aipHand = SpawnPrefab("shadowhand")
                    inst._aipHand.Transform:SetPosition(ix, 0, iz)
                    inst._aipHand:SetTargetFire(fire)

                    -- 给手注入一些数据
                    inst._aipHand.components.playerprox:SetDist(1.4, 1.4) -- 让玩家更难踩
                    inst._aipHand:RemoveEventCallback("enterlight", inst._aipHand.dissipatefn)
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

---------------------------------- AI ----------------------------------
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

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("timer")

    inst:AddComponent("inspectable")

    -- 创造跟随的头部
    inst:DoTaskInTime(3, function()
        -- inst.AnimState:Hide("head")
    end)

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

    return inst
end

--------------------------------- 头像 ---------------------------------
local headAssets = {
    Asset("ANIM", "anim/aip_oldone_marble_head.zip"),
    Asset("ATLAS", "images/inventoryimages/aip_oldone_marble_head.xml"),
}

local function onequip(inst, owner)
	owner.AnimState:OverrideSymbol("swap_body", "aip_oldone_marble_head", "swap_body")
end

local function onunequip(inst, owner)
	owner.AnimState:ClearOverrideSymbol("swap_body")
end

local function headFn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeHeavyObstaclePhysics(inst, PHYSICS_RADIUS, PHYSICS_HEIGHT)
    inst.Physics:CollidesWith(COLLISION.WORLD)

    inst.AnimState:SetBank("chesspiece")
    inst.AnimState:SetBuild("aip_oldone_marble_head")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("heavy")

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

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

    inst.persists = false

    -- 这个是头，别放错地方！

    return inst
end

return Prefab("aip_oldone_marble", fn, assets), Prefab("aip_oldone_marble_head", headFn, headAssets)
