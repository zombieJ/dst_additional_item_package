local dev_mode = aipGetModConfig("dev_mode") == "enabled"
local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Constrained Particles",
		DESC = "Catch the energy before it's gone",
	},
	chinese = {
		NAME = "束能粒子",
		DESC = "趁能量消失前捕获它",
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

-------------------------------- 事件 --------------------------------
local MAX_DURATION = dev_mode and 10 or 30       -- 存续时间
local INTERVAL = 0.5

local function onUpdateState(inst)
    inst._aipDuration = math.max(0, inst._aipDuration - INTERVAL)
    local redPTG = inst._aipDuration / MAX_DURATION
    local bluePTG = 1 - redPTG
    aipPrint(redPTG, bluePTG)

    -- inst.AnimState:OverrideMultColour(redPTG, 0, bluePTG, 0.5 + redPTG / 2)
    inst.AnimState:SetMultColour(1, 1, 1, redPTG)

    if inst._aipDuration <= 0 then
        aipRemove(inst)
    end
end

-------------------------------- 实例 --------------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    -- MakeInventoryPhysics(inst)

    local scale = 0.5
    inst.Transform:SetScale(scale, scale, scale)

    -- inst.AnimState:SetMultColour(1, 0, 0, 1)

    inst.AnimState:SetBank("aip_particles")
    inst.AnimState:SetBuild("aip_particles")
    inst.AnimState:PlayAnimation("idle", true)
    inst.AnimState:SetRayTestOnBB(true)

    -- MakeInventoryFloatable(inst, "med", 0.3, 1)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("aipc_timer")

	-- inst:AddComponent("inventoryitem")
	-- inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_particles.xml"

	-- inst:AddComponent("tradable")
	-- inst.components.tradable.goldvalue = 12

    -- MakeHauntableLaunch(inst)

    inst.persists = false
    inst._aipDuration = MAX_DURATION

    inst.components.aipc_timer:Interval(INTERVAL, onUpdateState)

    return inst
end

return Prefab("aip_particles", fn, assets)
