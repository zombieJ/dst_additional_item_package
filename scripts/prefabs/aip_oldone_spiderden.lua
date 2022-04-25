local dev_mode = aipGetModConfig("dev_mode") == "enabled"
local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Parasitic Spider Den",
		DESC = "Seems a big difference inside",
        SEE = "Who is watching?",
	},
	chinese = {
		NAME = "寄生蜘蛛巢",
		DESC = "内部结果似乎已经大不一样了",
        SEE = "谁在注视我？",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_OLDONE_SPIDERDEN = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_SPIDERDEN = LANG.DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_SPIDERDEN_SEE = LANG.SEE

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_oldone_spiderden.zip"),
}


----------------------------------- 事件 -----------------------------------
local function updateCreep(inst)
    if inst:GetCurrentPlatform() == nil then
        inst.GroundCreepEntity:SetRadius(5)
    end
end

local function OnHit(inst, attacker)
    if inst.components.health:IsDead() then
        return
    end

    inst.AnimState:PlayAnimation("hit")
    inst.AnimState:PushAnimation("idle", true)

    -- 不再生产
    inst.components.childspawner:StopSpawning()
    if inst._aipStartTimer ~= nil then
        inst._aipStartTimer:Cancel()
        inst._aipStartTimer = nil
    end

    -- 让孩子回家
    for k, v in pairs(inst.components.childspawner.childrenoutside) do
        v._aipAttacker = attacker
        v:PushEvent("gohome")
    end

    -- 一段时间后恢复生产
    inst._aipStartTime = inst:DoTaskInTime(10, function()
        inst.components.childspawner:StartSpawning()
        inst._aipStartTime = nil
    end)
end

-- 不断在玩家附近创建眼睛
aipBufferRegister("aip_see_eyes", {
    clientFn = function(inst)
        local pt = inst:GetPosition()

        for i = 1, 2 do
            local eye = aipSpawnPrefab(
                inst, "aip_oldone_eye",
                pt.x + math.random(-10, 10), 0,
                pt.z + math.random(-10, 10)
            )
    
            local scale = 1 + math.random() / 2
            eye.Transform:SetScale(scale, scale, scale)
            eye.Transform:SetRotation(math.random() * 360)
        end
    end,

    -- 告知客机玩家可以看见特殊东西了
    startFn = function(source, inst)
        if inst.player_classified ~= nil and inst.player_classified.aip_see_eyes ~= nil then
            inst.player_classified.aip_see_eyes:set(true)
        end
    end,

    -- 告知客机玩家不用再看了
    endFn = function(source, inst)
        if inst.player_classified ~= nil and inst.player_classified.aip_see_eyes ~= nil then
            inst.player_classified.aip_see_eyes:set(false)
        end
    end,

    showFX = true,
})

local function OnKilled(inst)
    -- 诅咒附近的玩家
    local players = aipFindNearPlayers(inst, 9)
    for k, player in pairs(players) do
        aipBufferPatch(inst, player, "aip_see_eyes", dev_mode and 10 or 30)

        if player.components.talker ~= nil then
            player.components.talker:Say(
                STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_SPIDERDEN_SEE
            )
        end
    end

    -- 实际上死亡时是无法将蜘蛛释放出来的
    if inst.components.childspawner ~= nil then
        inst.components.childspawner:ReleaseAllChildren()
    end

    inst.AnimState:PlayAnimation("death")

    RemovePhysicsColliders(inst)

    inst.SoundEmitter:PlaySound("dontstarve/creatures/spider/spiderLair_destroy")
    inst.components.lootdropper:DropLoot(inst:GetPosition())
end

-- 投毒计时器，让投毒更有美感
local function startThrow(inst, target)
    table.insert(inst._aipTargets, target)

    if inst._aipTimer ~= nil then
        return
    end

    inst._aipTimer = inst:DoPeriodicTask(1.5, function()
        if #inst._aipTargets <= 0 or inst.components.health:IsDead() then
            inst._aipTimer:Cancel()
            inst._aipTimer = nil
            return
        end

        local target = table.remove(inst._aipTargets, 1)
        if target ~= nil and target:IsValid() then
            local ball = aipSpawnPrefab(inst, "aip_oldone_plant_full")
            local x, y, z = target.Transform:GetWorldPosition()
            ball.components.complexprojectile:Launch(
                Vector3(
                    x + math.random(-2, 2),
                    y,
                    z + math.random(-2, 2)
                ),
                inst
            )
        end
    end, 0.5)
end

-- 扔毒药给攻击者，需要按照队列延迟才行
local function onGoHome(inst, child)
    startThrow(inst, child._aipAttacker)
end

----------------------------------- 实体 -----------------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:AddSoundEmitter()
    inst.entity:AddGroundCreepEntity()

    inst:AddTag("hostile")
    inst:AddTag("aip_oldone")
    inst:AddTag("aip_oldone_spiderden")

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("aip_oldone_spiderden")
    inst.AnimState:SetBuild("aip_oldone_spiderden")
    inst.AnimState:PlayAnimation("idle", true)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("childspawner")
    inst.components.childspawner.childname = "aip_oldone_rabbit"
    inst.components.childspawner:SetRegenPeriod(dev_mode and 1 or TUNING.SPIDERDEN_REGEN_TIME)
    inst.components.childspawner:SetSpawnPeriod(dev_mode and 1 or TUNING.SPIDERDEN_RELEASE_TIME)
    inst.components.childspawner:SetMaxChildren(3)
    inst.components.childspawner.allowboats = true
    inst.components.childspawner.childreninside = 3
    inst.components.childspawner:StartSpawning()
    inst.components.childspawner:StartRegen()
    inst.components.childspawner:SetGoHomeFn(onGoHome)

    inst:AddComponent("inspectable")

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = -TUNING.SANITYAURA_SMALL

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:AddChanceLoot("plantmeat", 1)
    inst.components.lootdropper:AddChanceLoot("silk", 1)

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(dev_mode and 66 or 666)
    -- inst.components.health.nofadeout = true

    inst:AddComponent("combat")
    inst.components.combat:SetOnHit(OnHit)
    inst:ListenForEvent("death", OnKilled)

    MakeHauntableLaunch(inst)
    MakeMediumPropagator(inst)

    inst:DoTaskInTime(0, updateCreep)

    -- 测试模式直接释放蜘蛛
    if dev_mode then
        inst:DoTaskInTime(0, function()
            inst.components.childspawner:ReleaseAllChildren()
        end)
    end

    inst._aipTargets = {}

    return inst
end

return Prefab("aip_oldone_spiderden", fn, assets)
