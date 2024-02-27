local dev_mode = aipGetModConfig("dev_mode") == "enabled"

local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
    english = {NAME = "Vortex"},
    chinese = {NAME = "旋涡"}
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_OCEAN_VORTEX = LANG.NAME

-- 资源
local assets = {Asset("ANIM", "anim/aip_ocean_vortex.zip")}

--------------------------------- 单个 -----------------------------------
local function common(order)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst:AddTag("NOBLOCK")
    inst:AddTag("DECOR")
    inst:AddTag("FX")

    inst.AnimState:SetBank("aip_ocean_vortex")
    inst.AnimState:SetBuild("aip_ocean_vortex")
    inst.AnimState:PlayAnimation("enter")
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGroundFixed)
    -- inst.AnimState:SetLayer(LAYER_BELOW_GROUND)
    inst.AnimState:SetLayer(LAYER_WIP_BELOW_OCEAN)
    -- inst.AnimState:SetSortOrder(ANIM_SORT_ORDER_BELOW_GROUND.UNDERWATER)
    inst.AnimState:SetSortOrder(order)
    inst.AnimState:SetFinalOffset(0)
    inst.AnimState:SetOceanBlendParams(TUNING.OCEAN_SHADER.EFFECT_TINT_AMOUNT)
    inst.AnimState:SetInheritsSortKey(false)

    inst.AnimState:PushAnimation("loop", true)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then return inst end

    inst:AddComponent("fader")

    inst.persists = false

    return inst
end

local function topFn()
    return common(ANIM_SORT_ORDER_BELOW_GROUND.BOAT_TRAIL)
end

local function bottomFn()
    return common(ANIM_SORT_ORDER_BELOW_GROUND.UNDERWATER)
end

--------------------------------- 群体 -----------------------------------
local function removeVortex(inst)
    if inst._aipRemoved then
        return
    end
    inst._aipRemoved = true

    for i, vortex in ipairs(inst._aipList) do
        vortex.components.fader:Fade(1, 0, 1,
            function(alphaval)
                vortex.AnimState:OverrideMultColour(1, 1, 1, alphaval)
            end,
            inst.Remove
        )
    end

    inst:DoTaskInTime(2, inst.Remove)
end

local function attrackFn(inst)
    -- 获取附近的船
    local minForce = 0.7
    local maxForce = 2
    local attackDist = 15

    local instPos = inst:GetPosition()
    local boats = TheSim:FindEntities(
        instPos.x, instPos.y, instPos.z, attackDist, { "boat" }
    )

    local hasBoat = false

    -- 施加一个力
    for i, boat in ipairs(boats) do
        if boat.components.boatphysics then
            local boatPos = boat:GetPosition()
            local dirX = instPos.x - boatPos.x
            local dirZ = instPos.z - boatPos.z

            local boatDist = aipDist(instPos, boatPos)
            local distForce = Remap(boatDist, 0, attackDist, maxForce, minForce)

            boat.components.boatphysics:ApplyRowForce(
                dirX,
                dirZ,
                distForce,
                distForce
            )

            if boatDist < 1 then
                hasBoat = true
            end
        end
    end

    if hasBoat then
        inst:DoTaskInTime(10, removeVortex)
    end
end

local function grpFn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    inst:AddTag("NOBLOCK")
    inst:AddTag("DECOR")
    inst:AddTag("FX")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    inst._aipList = {}

    inst:DoTaskInTime(.1, function()
        local yList = { 0, -0.5, -1.1, -1.8, -2.2, -2.6 }
        -- local scaleList = { 3, 2.5, 2, 1, 0.7, 0.5 }
        local scaleList = { 4.5, 4, 3, 2.5, 1.7, 1 }
        local orderList = { 1, 4, 2, 5, 3, 6 }

        for i = 1, 6 do
            local order = orderList[i]
            inst:DoTaskInTime(.1 + order * 0.3, function()
                local prefab = order == 1 and "aip_ocean_vortex_fx_top" or "aip_ocean_vortex_fx_bottom"
                local vortex = aipSpawnPrefab(inst, prefab)
                inst:AddChild(vortex)

                local scale = scaleList[order]
                vortex.Transform:SetScale(scale, scale, scale)
                vortex.Transform:SetPosition(0, yList[order], 0)
                table.insert(inst._aipList, vortex)

                
            end)
        end
    end)

    inst:DoPeriodicTask(0.2, attrackFn)

    inst:DoTaskInTime(120, removeVortex)

    return inst
end

return  Prefab("aip_ocean_vortex_fx_top", topFn, assets),
        Prefab("aip_ocean_vortex_fx_bottom", bottomFn, assets),
        Prefab("aip_ocean_vortex", grpFn, assets)
