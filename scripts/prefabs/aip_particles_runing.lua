local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Entangled Particles",
		DESC = "Attack will trigger another one",
	},
	chinese = {
		NAME = "纠缠粒子",
		DESC = "攻击会触发另一个",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_PARTICLES_ENTANGLED = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_PARTICLES_ENTANGLED = LANG.DESC

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_particles_runing.zip"),
    Asset("ATLAS", "images/inventoryimages/aip_particles_entangled_blue.xml"),
    Asset("ATLAS", "images/inventoryimages/aip_particles_entangled_orange.xml"),
}

----------------------------------- 马甲 -----------------------------------
local function syncSkin(inst)
    if inst._aipEntangled then
        inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_particles_entangled_blue.xml"
		inst.components.inventoryitem:ChangeImageName("aip_particles_entangled_blue")
    else
        inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_particles_entangled_orange.xml"
        inst.components.inventoryitem:ChangeImageName("aip_particles_entangled_orange")
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
local function onHit(inst, attacker)
    -- 目标没了，炸毁吧
    if inst._aipTarget == nil or not inst._aipTarget:IsValid() then
        aipSpawnPrefab(inst, "aip_shadow_wrapper").DoShow()
        aipRemove(inst)
        return
    end

    -- 不会死
    if inst.components.health ~= nil then
        inst.components.health:SetCurrentHealth(1)
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
                local x, y, z = inst.Transform:GetWorldPosition()
                local particles = TheSim:FindEntities(x, y, z, 1, { "aip_particles" })
                particles = aipFilterTable(particles, function(v)
                    return v ~= inst and v ~= inst._aipTarget
                end)

                for _, particle in ipairs(particles) do
                    particle.components.combat:GetAttacked(inst, 1)
                end
            end)
        end
    end
end


----------------------------------- 存取 -----------------------------------
local function onSave(inst, data)
    local r, g, b = inst.AnimState:GetMultColour()

    data.entangled = inst._aipEntangled
    data.color = {r, g, b}
    data.id = inst._aipId
end

local function onLoad(inst, data)
    if data ~= nil then
        inst._aipEntangled = data.entangled
        inst.AnimState:SetMultColour(data.color[1], data.color[2], data.color[3], 1)
        inst._aipId = data.id

        syncSkin(inst)
    end
end

----------------------------------- 实例 -----------------------------------
local function entangledFn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.entity:AddDynamicShadow()
    inst.DynamicShadow:SetSize(1.2, .5)

    inst.AnimState:SetBank("aip_particles_runing")
    inst.AnimState:SetBuild("aip_particles_runing")
    inst.AnimState:PlayAnimation("idle", true)

    inst:AddTag("aip_particles")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_particles_entangled_blue.xml"

    inst:AddComponent("combat")
    inst.components.combat.onhitfn = onHit

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(1)
    inst.components.health.nofadeout = true
    inst.components.health.canheal = false
    inst.components.health.canmurder = false

    inst:AddComponent("timer")

    inst.OnSave = onSave
    inst.OnLoad = onLoad

    inst:DoTaskInTime(.1, connectParticles)

    return inst
end

return  Prefab("aip_particles_vest_entangled", vestFn, assets),
        Prefab("aip_particles_entangled", entangledFn, assets)
