local dev_mode = aipGetModConfig("dev_mode") == "enabled"

local language = aipGetModConfig("language")

local createGroudVest = require("utils/aip_vest_util").createGroudVest

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Moon Connection Point",
		DESC = "Create an invisible path",
	},
	chinese = {
		NAME = "月能联结点",
		DESC = "链接着远方的道路",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_GLASS_ORBIT_POINT = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_GLASS_ORBIT_POINT = LANG.DESC

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_glass_orbit.zip"),
	Asset("ANIM", "anim/aip_glass_orbit_point.zip"),
}

------------------------------------ 实例：节点 ------------------------------------
local function pointFn()
    local scale = 1
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("aip_glass_orbit_point")
    inst.AnimState:SetBuild("aip_glass_orbit_point")
    inst.AnimState:PlayAnimation("idle")

    inst.Transform:SetScale(scale, scale, scale)

    inst:AddTag("aip_glass_orbit_point")

    inst.entity:SetPristine()

    -- 创建一个光环旋转效果
    if not TheNet:IsDedicated() then
        inst:DoTaskInTime(0.1, function()
            local vest = createGroudVest("aip_glass_orbit", "aip_glass_orbit", "loop", true)
            inst:AddChild(vest)
        end)
    end

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    MakeHauntableLaunch(inst)

    -- 轨道相关实体注册
    -- -- inst.aipId = tostring(os.time())..tostring(math.random())
    inst.aipPoints = {}

    return inst
end

------------------------------------ 实例：轨道 ------------------------------------
-- 轨道是玩家侧才能看到的
local function orbitFn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    -- inst.entity:AddNetwork()

    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
	inst.AnimState:SetLayer(LAYER_WORLD_BACKGROUND)
	inst.AnimState:SetSortOrder(2)

    inst.AnimState:SetBank("aip_glass_orbit")
    inst.AnimState:SetBuild("aip_glass_orbit")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("NOCLICK")
    inst:AddTag("fx")

    -- inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    return inst
end

------------------------------------ 实例：直线 ------------------------------------
local function linkFn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("aip_glass_orbit_point")
    inst.AnimState:SetBuild("aip_glass_orbit_point")
    inst.AnimState:PlayAnimation("idle")

    inst.AnimState:OverrideMultColour(0,0,0,dev_mode and 0.3 or 0)

    inst:AddTag("NOCLICK")
    inst:AddTag("fx")

    -- 双端通用组件
    inst:AddComponent("aipc_orbit_link")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    return inst
end

return	Prefab("aip_glass_orbit", orbitFn, assets),
		Prefab("aip_glass_orbit_point", pointFn, assets),
        Prefab("aip_glass_orbit_link", linkFn, assets)
