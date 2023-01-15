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
        inst.entity:AddNetwork()

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        -- 创建一个目标动物
        inst:DoTaskInTime(.1, function()
            local pet = aipSpawnPrefab(inst, info.origin)
            toBePet(pet)
        end)

        inst.persists = false

        return inst
    end

    return fn
end

----------------------------------- 列表 -----------------------------------
local data = {
    rabbit = {
        -- bank = "rabbit",
        -- build = "rabbit_build",
        -- anim = "idle",
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
