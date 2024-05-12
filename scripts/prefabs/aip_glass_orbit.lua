local dev_mode = aipGetModConfig("dev_mode") == "enabled"

local language = aipGetModConfig("language")

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
    Asset("ANIM", "anim/aip_glass_orbit_column.zip"),
}

------------------------------------ 实例：端节点 ------------------------------------
local function onPointRemove(inst)
    if inst._aip_columns ~= nil then
        for _, column in pairs(inst._aip_columns) do
            column:Remove()
        end
    end
end

local function pointFn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeTinyFlyingCharacterPhysics(inst, 0, 0)

    inst.AnimState:SetBank("aip_glass_orbit")
    inst.AnimState:SetBuild("aip_glass_orbit")
    inst.AnimState:PlayAnimation("loop", true)
    -- inst.AnimState:SetRayTestOnBB(true)

    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
	-- inst.AnimState:SetLayer(LAYER_WORLD_BACKGROUND)
	-- inst.AnimState:SetSortOrder(3)

    -- 如果在空中则不用担心遮挡玩家
    inst:DoTaskInTime(1, function()
        local pt = inst:GetPosition()
        if pt.y == 0 then
            inst.AnimState:SetLayer(LAYER_WORLD_BACKGROUND)
	        inst.AnimState:SetSortOrder(3)
        else
            if TheNet:IsDedicated() then  -- 专服不需要轨道贴图
                return
            end

            inst._aip_columns = {}
            for i = 0, pt.y, 0.5 do
                local column = aipSpawnPrefab(inst, "aip_glass_orbit_column", nil, i)
                table.insert(inst._aip_columns, column)

                local cols = TheSim:FindEntities(pt.x, pt.y, pt.z, 5, { "aip_glass_orbit_column" })
            end



            inst.OnRemoveEntity = onPointRemove
        end
    end)

    inst:AddTag("aip_glass_orbit_point")

    -- 让船无视它
    inst:AddTag("flying")

    -- 轨道驱动器
    inst:AddComponent("aipc_orbit_point")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    MakeHauntableLaunch(inst)

    -- 轨道相关实体注册
    -- -- inst.aipId = tostring(os.time())..tostring(math.random())
    -- inst.aipPoints = {}

    return inst
end

----------------------------------- 实例：玩家可见高度点 -----------------------------------
-- 空中轨道的话，仅仅是 端节点 玩家很难去对准，所以我们要画一个柱子标记一下
local function columnFn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    inst.AnimState:SetBank("aip_glass_orbit_column")
    inst.AnimState:SetBuild("aip_glass_orbit_column")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("aip_glass_orbit_column")
    inst:AddTag("NOCLICK")
    inst:AddTag("fx")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    return inst
end

------------------------------------ 实例：玩家可见轨道 ------------------------------------
-- 轨道是玩家侧才能看到的
local function orbitFn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    -- inst.entity:AddNetwork()

    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
	-- inst.AnimState:SetLayer(LAYER_WORLD_BACKGROUND)
	-- inst.AnimState:SetSortOrder(2)

    inst.AnimState:SetBank("aip_glass_orbit")
    inst.AnimState:SetBuild("aip_glass_orbit")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("NOCLICK")
    inst:AddTag("fx")

    -- inst.entity:SetPristine()

    inst:DoTaskInTime(1, function()
        if inst:GetPosition().y == 0 then
            inst.AnimState:SetLayer(LAYER_WORLD_BACKGROUND)
	        inst.AnimState:SetSortOrder(2)
        end
    end)

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    return inst
end

------------------------------------ 实例：轨道创建器 ------------------------------------
local function linkFn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeTinyFlyingCharacterPhysics(inst, 0, 0)

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

return	Prefab("aip_glass_orbit_point", pointFn, assets),
        Prefab("aip_glass_orbit_column", columnFn, assets),
        Prefab("aip_glass_orbit", orbitFn, assets),
        Prefab("aip_glass_orbit_link", linkFn, assets)
