local language = aipGetModConfig("language")

local brain = require("brains/aip_pet_brain")

----------------------------------- 方法 -----------------------------------
-- 移除非必要组件，替换大脑
local function toBePet(inst)
    -- 更新 tag
    local tags = {
        "animal", "prey", "rabbit", "smallcreature", "canbetrapped",
        "cattoy", "catfood", "stunnedbybomb", "cookable", "small_livestock",
        "show_spoilage",
    }

    for _, tag in pairs(tags) do
        inst:RemoveTag(tag)
    end

    inst:AddTag("aip_pet")

    -- 更新 component
    local components = {
        "aipc_not_exist",
        "eater", "inventoryitem", "sanityaura", "cookable", "knownlocations",
        "timer", "health", "lootdropper", "combat", "inspectable", "sleeper", "tradable"
    }

    for _, component in pairs(components) do
        inst:RemoveComponent(component)
    end

    inst.OnEntityWake = nil
	inst.OnEntitySleep = nil

    inst:SetBrain(brain)
end

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

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

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
