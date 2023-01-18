local language = aipGetModConfig("language")

local brain = require("brains/aip_pet_brain")

local rabbitsounds = {
    scream = "dontstarve/rabbit/scream",
    hurt = "dontstarve/rabbit/scream_short",
}

----------------------------------- 实例 -----------------------------------
local function createPet(name, info)
    local upperCase = string.upper(name)
    local upperOrigin = string.upper(info.origin)
    STRINGS.NAMES[upperCase] = STRINGS.NAMES[upperOrigin]

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddDynamicShadow()
        inst.entity:AddNetwork()

        MakeFlyingCharacterPhysics(inst, 1, .5)

        inst.DynamicShadow:SetSize(1, .75)
        inst.Transform:SetFourFaced()

        inst.AnimState:SetBank(info.bank)
        inst.AnimState:SetBuild(info.build)
        inst.AnimState:PlayAnimation(info.anim)

        inst:AddComponent("aipc_petable")

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst.sounds = info.sounds

        inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
        inst.components.locomotor.runspeed = TUNING.WILSON_RUN_SPEED
        inst.components.locomotor.walkspeed = TUNING.WILSON_WALK_SPEED

        inst:SetStateGraph(info.sg)
        inst:SetBrain(brain)

        inst.persists = false

        return inst
    end

    return fn
end

----------------------------------- 列表 -----------------------------------
local data = {
    rabbit = {
        bank = "rabbit",
        build = "rabbit_build",
        anim = "idle",
        sg = "SGrabbit",
        sounds = rabbitsounds,
        origin = "rabbit",
    },
}
local prefabs = {}

for name, info in pairs(data) do
    local prefabName = "aip_pet_"..name
    local prefab = Prefab(prefabName, createPet(prefabName, info), {})
    table.insert(prefabs, prefab)
end

return unpack(prefabs)
