local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Constrained Particles",
		DESC = "It's leaving",
	},
	chinese = {
		NAME = "束能粒子",
		DESC = "它正在消失",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_PARTICLES = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_PARTICLES = LANG.DESC

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_particles.zip"),
	-- Asset("ATLAS", "images/inventoryimages/aip_particles.xml"),
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    -- MakeInventoryPhysics(inst)

    local scale = 0.6
    inst.Transform:SetScale(scale, scale, scale)

    inst.AnimState:SetMultColour(1, 0, 0, 1)

    inst.AnimState:SetBank("aip_particles")
    inst.AnimState:SetBuild("aip_particles")
    inst.AnimState:PlayAnimation("idle", true)

    -- MakeInventoryFloatable(inst, "med", 0.3, 1)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

	-- inst:AddComponent("inventoryitem")
	-- inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_particles.xml"

	-- inst:AddComponent("tradable")
	-- inst.components.tradable.goldvalue = 12

    -- MakeHauntableLaunch(inst)

    return inst
end

return Prefab("aip_particles", fn, assets)
