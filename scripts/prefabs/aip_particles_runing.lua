local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Entangled Particles",
		DESC = "They will trigger on both time",
	},
	chinese = {
		NAME = "纠缠粒子",
		DESC = "触发一个时会触发另一个",
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

----------------------------------- 方法 -----------------------------------
local function syncSkin(inst)
    if inst._aipEntangled then
        inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_particles_entangled_blue.xml"
		inst.components.inventoryitem:ChangeImageName("aip_particles_entangled_blue")
    else
        inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_particles_entangled_orange.xml"
        inst.components.inventoryitem:ChangeImageName("aip_particles_entangled_orange")
    end
end

----------------------------------- 马甲 -----------------------------------
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
    end)

    return inst
end

----------------------------------- 存取 -----------------------------------
local function onSave(inst, data)
    local r, g, b = inst.AnimState:GetMultColour()

    data.entangled = inst._aipEntangled
    data.color = {r, g, b}
end

local function onLoad(inst, data)
    if data ~= nil then
        inst._aipEntangled = data.entangled
        inst.AnimState:SetMultColour(data.color[1], data.color[2], data.color[3], 1)

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

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_particles_entangled_blue.xml"

    inst.OnSave = onSave
    inst.OnLoad = onLoad

    return inst
end

return  Prefab("aip_particles_vest_entangled", vestFn, assets),
        Prefab("aip_particles_entangled", entangledFn, assets)
