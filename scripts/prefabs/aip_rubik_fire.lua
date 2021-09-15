local colors = {
    red = { 1, 0, 0 },
    green = { 0, 1, 0 },
    blue = { 0, 0, 1 },
}

-- string.upper(name)

------------------------------- 描述 -------------------------------
local language = aipGetModConfig("language")

local LANG_MAP = {
	english = {
		NAME = "Fire",
		DESC = "Examine close fire to move",
	},
	chinese = {
		NAME = "火焰",
		DESC = "检查相邻火焰移动",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

for colorName, rgb in pairs(colors) do
    local name = "AIP_RUBIK_FIRE_"..string.upper(colorName)
    STRINGS.NAMES[name] = LANG.NAME
    STRINGS.CHARACTERS.GENERIC.DESCRIBE[name] = LANG.DESC
end

------------------------------- 事件 -------------------------------
local function onSelect(inst, viewer)
    if inst.aipRubik ~= nil and inst.aipRubik.components.aipc_rubik ~= nil then
        inst.aipRubik.components.aipc_rubik:Select(inst)
    end
end

------------------------------- 实体 -------------------------------
local MakeTorchFire = require("prefabs/torchfire_common")

local ANIM_HAND_TEXTURE = "fx/animhand.tex"
local ANIM_SMOKE_TEXTURE = "fx/animsmoke.tex"

local SHADER = "shaders/vfx_particle.ksh"
local REVEAL_SHADER = "shaders/vfx_particle_reveal.ksh"

local assets = {
    Asset("ANIM", "anim/aip_rubik_fire.zip"),
    Asset("IMAGE", ANIM_HAND_TEXTURE),
    Asset("IMAGE", ANIM_SMOKE_TEXTURE),
    Asset("SHADER", SHADER),
    Asset("SHADER", REVEAL_SHADER),
}

local function fillColor(multiple, strongColor, normalColor)
    return math.max(strongColor * multiple, normalColor)
end

local function genRubik(colorName, rgb)
    local COLOUR_ENVELOPE_NAME_SMOKE = "aip_rubik_fire_"..colorName.."_colourenvelope_smoke"
    local SCALE_ENVELOPE_NAME_SMOKE = "aip_rubik_fire_"..colorName.."_scaleenvelope_smoke"
    local COLOUR_ENVELOPE_NAME = "aip_rubik_fire_"..colorName.."_colourenvelope"
    local SCALE_ENVELOPE_NAME = "aip_rubik_fire_"..colorName.."_scaleenvelope"
    local COLOUR_ENVELOPE_NAME_HAND = "aip_rubik_fire_"..colorName.."_colourenvelope_hand"
    local SCALE_ENVELOPE_NAME_HAND = "aip_rubik_fire_"..colorName.."_scaleenvelope_hand"

    --------------------------------------------------------------------------

    local function IntColour(r, g, b, a)
        return { r / 255, g / 255, b / 255, a / 255 }
    end

    local aipScale = 3
    local aipSmokeScale = 1 -- 1.4

    local aipTimeScale = 1.2 -- 1.3
    local aipSmokeTimeScale = 1 -- 1.3
    local aipSmokeOffset = 0 -- 0.5

    local function InitEnvelope()
        EnvelopeManager:AddColourEnvelope(
            COLOUR_ENVELOPE_NAME_SMOKE,
            {
                { 0,    IntColour(24, 24, 24, 64) },
                { .2,   IntColour(20, 20, 20, 240) },
                { .7,   IntColour(18, 18, 18, 256) },
                { 1,    IntColour(12, 12, 12, 0) },
            }
        )

        local smoke_max_scale = .3 * aipSmokeScale
        EnvelopeManager:AddVector2Envelope(
            SCALE_ENVELOPE_NAME_SMOKE,
            {
                { 0,    { smoke_max_scale * .2, smoke_max_scale * .2} },
                { .40,  { smoke_max_scale * .7, smoke_max_scale * .7} },
                { .60,  { smoke_max_scale * .8, smoke_max_scale * .8} },
                { .75,  { smoke_max_scale * .7, smoke_max_scale * .7} },
                { 1,    { smoke_max_scale, smoke_max_scale } },
            }
        )

        EnvelopeManager:AddColourEnvelope(
            COLOUR_ENVELOPE_NAME,
            {
                { 0,    IntColour(
                            fillColor(rgb[1], 100, 10),
                            fillColor(rgb[2], 100, 10),
                            fillColor(rgb[3], 100, 10),
                            25) },
                { .5,   IntColour(
                            fillColor(rgb[1], 255, 20),
                            fillColor(rgb[2], 255, 20),
                            fillColor(rgb[3], 255, 20),
                            255) },
                { 1,    IntColour(
                            fillColor(rgb[1], 255, 0),
                            fillColor(rgb[2], 255, 0),
                            fillColor(rgb[3], 255, 0),
                            0) },
            }
        )

        local fire_max_scale = .1 * aipScale
        EnvelopeManager:AddVector2Envelope(
            SCALE_ENVELOPE_NAME,
            {
                { 0,    { fire_max_scale * .5, fire_max_scale * .5 } },
                { .55,  { fire_max_scale * 1.3, fire_max_scale * 1.3 } },
                { 1,    { fire_max_scale * 1.5, fire_max_scale * 1.5 } },
            }
        )

        EnvelopeManager:AddColourEnvelope(
            COLOUR_ENVELOPE_NAME_HAND,
            {
                { 0,    IntColour(24, 24, 24, 64) },
                { .2,   IntColour(20, 20, 20, 256) },
                { .75,  IntColour(18, 18, 18, 256) },
                { 1,    IntColour(12, 12, 12, 0) },
            }
        )

        local hand_max_scale = 1 * aipSmokeScale
        EnvelopeManager:AddVector2Envelope(
            SCALE_ENVELOPE_NAME_HAND,
            {
                { 0,    { hand_max_scale * .3, hand_max_scale * .3} },
                { .2,   { hand_max_scale * .7, hand_max_scale * .7} },
                { 1,    { hand_max_scale, hand_max_scale } },
            }
        )

        InitEnvelope = nil
        IntColour = nil
    end

    --------------------------------------------------------------------------

    local SMOKE_MAX_LIFETIME = 1.1 * aipSmokeTimeScale
    local FIRE_MAX_LIFETIME = .9 * aipTimeScale
    local HAND_MAX_LIFETIME = 1.7 * aipSmokeTimeScale

    local function emit_fire_fn(effect, sphere_emitter)
        local vx, vy, vz = .005 * UnitRand(), 0, .0005 * UnitRand()
        local lifetime = FIRE_MAX_LIFETIME * (.9 + UnitRand() * .1)
        local px, py, pz = sphere_emitter()

        effect:AddRotatingParticleUV(
            0,
            lifetime,           -- lifetime
            px, py, pz,         -- position
            vx, vy, vz,         -- velocity
            math.random() * 360,-- angle
            UnitRand() * 2,     -- angle velocity
            0, 0                -- uv offset
        )
    end

    local function emit_smoke_fn(effect, sphere_emitter)
        local vx, vy, vz = .01 * UnitRand(), .06 + .02 * UnitRand(), .01 * UnitRand()
        local lifetime = SMOKE_MAX_LIFETIME * (.9 + UnitRand() * .1)
        local px, py, pz = sphere_emitter()
        --offset the flame particles upwards a bit so they can be used on a torch

        effect:AddRotatingParticleUV(
            1,
            lifetime,           -- lifetime
            px, py + .35 + aipSmokeOffset, pz,   -- position
            vx, vy, vz,         -- velocity
            math.random() * 360,--* 2 * PI, -- angle
            UnitRand() * 2,     -- angle velocity
            0, 0                -- uv offset
        )
    end

    local function emit_hand_fn(effect, sphere_emitter)
        local vx, vy, vz = 0, .07 + .01 * UnitRand(), 0
        local px, py, pz = sphere_emitter()
        --offset the flame particles upwards a bit so they can be used on a torch

        local uv_offset = math.random(0, 3) * .25

        effect:AddRotatingParticleUV(
            2,
            HAND_MAX_LIFETIME,  -- lifetime
            px, py + .65 + aipSmokeOffset, pz,   -- position
            vx, vy, vz,         -- velocity
            0,                  --* 2 * PI, -- angle
            UnitRand(),         -- angle velocity
            uv_offset, 0        -- uv offset
        )
    end

    --------------------------------------------------------------------------

    local function common_postinit(inst)
        inst.entity:AddAnimState()
        inst.AnimState:SetBank("aip_rubik_fire")
        inst.AnimState:SetBuild("aip_rubik_fire")
        inst.AnimState:PlayAnimation("idle")

        MakeTinyFlyingCharacterPhysics(inst, 0, 0)
        -- MakeInventoryPhysics(inst, 1, .5)
        RemovePhysicsColliders(inst)

        inst:RemoveTag("FX")

        --Dedicated server does not need to spawn local particle fx
        if TheNet:IsDedicated() then
            return
        elseif InitEnvelope ~= nil then
            InitEnvelope()
        end

        -----------------------------------------------------

        local effect = inst.entity:AddVFXEffect()
        effect:InitEmitters(3)

        --FIRE
        effect:SetRenderResources(0, ANIM_SMOKE_TEXTURE, REVEAL_SHADER)
        effect:SetMaxNumParticles(0, 32)
        effect:SetRotationStatus(0, true)
        effect:SetMaxLifetime(0, FIRE_MAX_LIFETIME)
        effect:SetColourEnvelope(0, COLOUR_ENVELOPE_NAME)
        effect:SetScaleEnvelope(0, SCALE_ENVELOPE_NAME)
        effect:SetBlendMode(0, BLENDMODE.AlphaAdditive)
        effect:EnableBloomPass(0, true)
        effect:SetUVFrameSize(0, 1, 1)
        effect:SetSortOrder(0, 0)
        effect:SetSortOffset(0, 1)
        effect:SetKillOnEntityDeath(0, true)
        effect:SetFollowEmitter(0, true)

        --SMOKE
        effect:SetRenderResources(1, ANIM_SMOKE_TEXTURE, REVEAL_SHADER) --REVEAL_SHADER --particle_add
        effect:SetMaxNumParticles(1, 32)
        effect:SetRotationStatus(1, true)
        effect:SetMaxLifetime(1, SMOKE_MAX_LIFETIME)
        effect:SetColourEnvelope(1, COLOUR_ENVELOPE_NAME_SMOKE)
        effect:SetScaleEnvelope(1, SCALE_ENVELOPE_NAME_SMOKE)
        effect:SetBlendMode(1, BLENDMODE.AlphaBlended) --AlphaBlended Premultiplied
        effect:EnableBloomPass(1, true)
        effect:SetUVFrameSize(1, 1, 1)
        effect:SetSortOrder(1, 0)
        effect:SetSortOffset(1, 1)

        --HAND
        effect:SetRenderResources(2, ANIM_HAND_TEXTURE, REVEAL_SHADER) --REVEAL_SHADER --particle_add
        effect:SetMaxNumParticles(2, 32)
        effect:SetRotationStatus(2, true)
        effect:SetMaxLifetime(2, HAND_MAX_LIFETIME)
        effect:SetColourEnvelope(2, COLOUR_ENVELOPE_NAME_HAND)
        effect:SetScaleEnvelope(2, SCALE_ENVELOPE_NAME_HAND)
        effect:SetBlendMode(2, BLENDMODE.AlphaBlended) --AlphaBlended Premultiplied
        effect:EnableBloomPass(2, true)
        effect:SetUVFrameSize(2, .25, 1)
        effect:SetSortOrder(2, 0)
        effect:SetSortOffset(2, 1)
        --effect:SetDragCoefficient(2, 50)

        -----------------------------------------------------

        local tick_time = TheSim:GetTickTime()

        local fire_desired_pps = 6
        local fire_particles_per_tick = fire_desired_pps * tick_time
        local fire_num_particles_to_emit = 0

        local smoke_desired_pps = 10
        local smoke_particles_per_tick = smoke_desired_pps * tick_time
        local smoke_num_particles_to_emit = -5 --start delay

        local hand_desired_pps = .3
        local hand_particles_per_tick = hand_desired_pps * tick_time
        local hand_num_particles_to_emit = -1 ---50 --start delay

        local sphere_emitter = CreateSphereEmitter(.05)

        EmitterManager:AddEmitter(inst, nil, function()
            --FIRE
            while fire_num_particles_to_emit > 1 do
                emit_fire_fn(effect, sphere_emitter)
                fire_num_particles_to_emit = fire_num_particles_to_emit - 1
            end
            fire_num_particles_to_emit = fire_num_particles_to_emit + fire_particles_per_tick * math.random() * 3

            --SMOKE
            while smoke_num_particles_to_emit > 1 do
                emit_smoke_fn(effect, sphere_emitter)
                smoke_num_particles_to_emit = smoke_num_particles_to_emit - 1
            end
            smoke_num_particles_to_emit = smoke_num_particles_to_emit + smoke_particles_per_tick

            --HAND
            while hand_num_particles_to_emit > 1 do
                emit_hand_fn(effect, sphere_emitter)
                hand_num_particles_to_emit = hand_num_particles_to_emit - 1
            end
            hand_num_particles_to_emit = hand_num_particles_to_emit + hand_particles_per_tick
        end)
    end

    local function master_postinit(inst)
        inst:AddComponent("inspectable")
        inst.components.inspectable.descriptionfn = onSelect
    end

    return MakeTorchFire("aip_rubik_fire_"..colorName, assets, nil, common_postinit, master_postinit)
end

local prefabList = {}

for colorName, rgb in pairs(colors) do
    table.insert(prefabList, genRubik(colorName, rgb))
end

return unpack(prefabList)