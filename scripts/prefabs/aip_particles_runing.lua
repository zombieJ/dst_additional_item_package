local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Entangled Particles",
		DESC = "Attack will trigger another one",
        ECHO_NAME = "Echo Particles",
		ECHO_DESC = "Triggers again after a period of time",
        HEART_NAME = "Telltale Particles",
		HEART_DESC = "Trigger when player is nearby",

        MORNING_NAME = "Morning Particles",
		MORNING_DESC = "Trigger when moring",
        NIGHT_NAME = "Night Particles",
		NIGHT_DESC = "Trigger when night",
        DUSK_NAME = "Dusk Particles",
		DUSK_DESC = "Trigger when dusk",
	},
	chinese = {
		NAME = "纠缠粒子",
		DESC = "攻击会触发另一个",
        ECHO_NAME = "回响粒子",
		ECHO_DESC = "间隔一段时间会再次触发",
        HEART_NAME = "告密粒子",
		HEART_DESC = "附近玩家靠近时触发",

        MORNING_NAME = "晨曦粒子",
		MORNING_DESC = "在清晨来临触发",
        NIGHT_NAME = "漆黑粒子",
		NIGHT_DESC = "在夜晚来临触发",
        DUSK_NAME = "黄昏粒子",
		DUSK_DESC = "在黄昏来临触发",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_PARTICLES_VEST_ENTANGLED = LANG.NAME
STRINGS.NAMES.AIP_PARTICLES_ENTANGLED = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_PARTICLES_ENTANGLED = LANG.DESC
STRINGS.NAMES.AIP_PARTICLES_ECHO = LANG.ECHO_NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_PARTICLES_ECHO = LANG.ECHO_DESC
STRINGS.NAMES.AIP_PARTICLES_HEART = LANG.HEART_NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_PARTICLES_HEART = LANG.HEART_DESC

STRINGS.NAMES.AIP_PARTICLES_MORNING = LANG.MORNING_NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_PARTICLES_MORNING = LANG.MORNING_DESC
STRINGS.NAMES.AIP_PARTICLES_NIGHT = LANG.NIGHT_NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_PARTICLES_NIGHT = LANG.NIGHT_DESC
STRINGS.NAMES.AIP_PARTICLES_DUSK = LANG.DUSK_NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_PARTICLES_DUSK = LANG.DUSK_DESC

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_particles_runing.zip"),
    Asset("ATLAS", "images/inventoryimages/aip_particles_entangled_blue.xml"),
    Asset("ATLAS", "images/inventoryimages/aip_particles_entangled_orange.xml"),
    Asset("ATLAS", "images/inventoryimages/aip_particles_echo.xml"),
    Asset("ATLAS", "images/inventoryimages/aip_particles_heart.xml"),
    Asset("ATLAS", "images/inventoryimages/aip_particles_morning.xml"),
    Asset("ATLAS", "images/inventoryimages/aip_particles_night.xml"),
    Asset("ATLAS", "images/inventoryimages/aip_particles_dusk.xml"),
}

-- =========================================================================
-- ==                               共享方法                               ==
-- =========================================================================
local function setImg(inst, name)
    inst.components.inventoryitem.atlasname = "images/inventoryimages/"..name..".xml"
    inst.components.inventoryitem:ChangeImageName(name)
end

local function onCommonHit(inst)
    -- 不会死
    if inst.components.health ~= nil then
        inst.components.health:SetCurrentHealth(1)
    end
end

local function triggerNearby(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local particles = TheSim:FindEntities(x, y, z, 1.5, { "aip_particles" })
    particles = aipFilterTable(particles, function(v)
        return v ~= inst and v ~= inst._aipTarget
    end)

    for _, particle in ipairs(particles) do
        if particle._aip_particles_trigger ~= nil then
            particle._aip_particles_trigger(particle, inst)
        elseif particle.components.combat ~= nil then
            particle.components.combat:GetAttacked(inst, 1)
        end
    end
end

-- =========================================================================
-- ==                               纠缠粒子                               ==
-- =========================================================================
----------------------------------- 马甲 -----------------------------------
local function syncSkin(inst)
    if inst._aipEntangled then
        setImg(inst, "aip_particles_entangled_blue")
    else
        setImg(inst, "aip_particles_entangled_orange")
    end
end

-- 马甲将会拆分成 2 个纠缠粒子
local function vestFn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

	inst:AddComponent("inventoryitem")

    inst:DoTaskInTime(0, function()
        local particles = aipReplacePrefab(inst, "aip_particles_entangled", nil, nil, nil, 2)

        -- 颜色随机
        local r = .5 + math.random() * .5
        local g = .5 + math.random() * .5
        local b = .5 + math.random() * .5
        particles[1].AnimState:SetMultColour(r, g, b, 1)
        particles[2].AnimState:SetMultColour(r, g, b, 1)

        -- 同步图标
        particles[1]._aipEntangled = true
        particles[2]._aipEntangled = false
        syncSkin(particles[1])
        syncSkin(particles[2])

        -- 创建相互关联
        local uniqueId = os.time()
        particles[1]._aipId = uniqueId
        particles[2]._aipId = uniqueId
        particles[1]._aipTarget = particles[2]
        particles[2]._aipTarget = particles[1]
    end)

    return inst
end

----------------------------------- 方法 -----------------------------------
-- 加载后关联粒子
local function connectParticles(inst)
    local store = aipCommonStore()
    if store ~= nil then
        if store.particles[inst._aipId] == nil then
            store.particles[inst._aipId] = inst
        else
            inst._aipTarget = store.particles[inst._aipId]
            inst._aipTarget._aipTarget = inst

            table.remove(store.particles, inst._aipId)
        end

        inst:SpawnChild(inst._aipEntangled and "aip_aura_entangled_blue" or "aip_aura_entangled_orange")
    end
end



-- 攻击触发另一个
local function onEntangledHit(inst, attacker)
    onCommonHit(inst)

    -- 目标没了，炸毁吧
    if inst._aipTarget == nil or not inst._aipTarget:IsValid() then
        aipSpawnPrefab(inst, "aip_shadow_wrapper").DoShow()
        aipRemove(inst)
        return
    end

    -- 目标有个内置 CD 如果满足则触发
    if inst.components.timer ~= nil and not inst.components.timer:TimerExists("aip_runing") then
        inst.components.timer:StartTimer("aip_runing", .5)
        aipSpawnPrefab(inst, "aip_shadow_wrapper").DoShow()

        -- 触发目标粒子
        if attacker ~= inst._aipTarget then     -- 如果不是自己来源则触发目标
            if inst._aipTarget ~= nil then
                inst._aipTarget.components.combat:GetAttacked(inst, 1)
            end
        else                                    -- 如果是被联通的，则触发附近的元素
            inst:DoTaskInTime(0.1, function()   -- 联通是有延迟的
                triggerNearby(inst)
            end)
        end
    end
end


----------------------------------- 存取 -----------------------------------
local function onEntangledSave(inst, data)
    local r, g, b = inst.AnimState:GetMultColour()

    data.entangled = inst._aipEntangled
    data.color = {r, g, b}
    data.id = inst._aipId
end

local function onEntangledLoad(inst, data)
    if data ~= nil then
        inst._aipEntangled = data.entangled
        inst.AnimState:SetMultColour(data.color[1], data.color[2], data.color[3], 1)
        inst._aipId = data.id

        syncSkin(inst)
    end
end


-- =========================================================================
-- ==                               回响粒子                               ==
-- =========================================================================

-- 攻击触发另一个
local function onEchoHit(inst, attacker)
    onCommonHit(inst)

    -- 目标有个内置 CD 如果满足则触发
    if inst.components.timer ~= nil and not inst.components.timer:TimerExists("aip_runing") then
        inst.components.timer:StartTimer("aip_runing", 2)
        aipSpawnPrefab(inst, "aip_shadow_wrapper").DoShow()

        --触发的人不会触发
        inst._aipTarget = attacker

        -- 延迟 1s 触发
        inst:DoTaskInTime(1, function()
            triggerNearby(inst)
            aipSpawnPrefab(inst, "aip_shadow_wrapper").DoShow()
        end)
    end
end

-- =========================================================================
-- ==                               告密粒子                               ==
-- =========================================================================
local function onNear(inst, player)
    -- 只有在地上才会触发
    if  inst.components.inventoryitem ~= nil and
        inst.components.inventoryitem:GetGrandOwner() == nil then
        triggerNearby(inst)
        aipSpawnPrefab(inst, "aip_shadow_wrapper").DoShow()
    end
end

local function wrapNearBy(inst)
    inst:AddComponent("playerprox")
	inst.components.playerprox:SetDist(4, 8)
	inst.components.playerprox:SetOnPlayerNear(onNear)
	-- inst.components.playerprox:SetOnPlayerFar(onFar)
end

-- =========================================================================
-- ==                               清晨粒子                               ==
-- =========================================================================
local function OnPhase(inst, phase)
    if phase == inst._aipPhase then
        triggerNearby(inst)
        aipSpawnPrefab(inst, "aip_shadow_wrapper").DoShow()
    end
end

local function triggerOnPhase(inst, phase)
    inst._aipPhase = phase
    inst:WatchWorldState("phase", OnPhase)
end

-- =========================================================================
-- ==                               共享实例                               ==
-- =========================================================================
local function commonFn(anim, onHitFn, postFn)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.entity:AddDynamicShadow()
    inst.DynamicShadow:SetSize(1.2, .5)

    inst.AnimState:SetBank("aip_particles_runing")
    inst.AnimState:SetBuild("aip_particles_runing")
    inst.AnimState:PlayAnimation(anim, true)

    inst:AddTag("aip_particles")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

	inst:AddComponent("inventoryitem")

    inst:AddComponent("combat")
    inst.components.combat.onhitfn = onHitFn or onCommonHit

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(1)
    inst.components.health.nofadeout = true
    inst.components.health.canheal = false
    inst.components.health.canmurder = false

    inst:AddComponent("timer")



    if postFn ~= nil then
        postFn(inst)
    end

    return inst
end

--------------------------------- 纠缠粒子 ---------------------------------
local function entangledFn()
    return commonFn("idle", onEntangledHit, function(inst)
        setImg(inst, "aip_particles_entangled_blue")

        inst.OnSave = onEntangledSave
        inst.OnLoad = onEntangledLoad
    
        inst:DoTaskInTime(.1, connectParticles)
    end)
end

--------------------------------- 回响粒子 ---------------------------------
local function echoFn()
    return commonFn("echo", onEchoHit, function(inst)
        setImg(inst, "aip_particles_echo")

        inst:SpawnChild("aip_aura_entangled_echo")
    end)
end

--------------------------------- 告密粒子 ---------------------------------
local function heartFn()
    return commonFn("heart", nil, function(inst)
        setImg(inst, "aip_particles_heart")
        wrapNearBy(inst)

        -- inst:SpawnChild("aip_aura_entangled_echo")
    end)
end

--------------------------------- 清晨粒子 ---------------------------------
local function morningFn()
    return commonFn("morning", nil, function(inst)
        setImg(inst, "aip_particles_morning")
        triggerOnPhase(inst, "day")
    end)
end

local function nightFn()
    return commonFn("night", nil, function(inst)
        setImg(inst, "aip_particles_night")
        triggerOnPhase(inst, "night")
    end)
end

local function duskFn()
    return commonFn("dusk", nil, function(inst)
        setImg(inst, "aip_particles_dusk")
        triggerOnPhase(inst, "dusk")
    end)
end


return  Prefab("aip_particles_vest_entangled", vestFn, assets),
        Prefab("aip_particles_entangled", entangledFn, assets),
        Prefab("aip_particles_echo", echoFn, assets),
        Prefab("aip_particles_heart", heartFn, assets),
        Prefab("aip_particles_morning", morningFn, assets),
        Prefab("aip_particles_night", nightFn, assets),
        Prefab("aip_particles_dusk", duskFn, assets)
