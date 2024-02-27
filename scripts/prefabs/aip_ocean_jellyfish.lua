local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
    english = {NAME = "Ocean Jellyfish"},
    chinese = {NAME = "海洋水母"}
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_OCEAN_JELLYFISH = LANG.NAME

-- 资源
local assets = {Asset("ANIM", "anim/aip_ocean_jellyfish.zip")}

--------------------------------- 单个 -----------------------------------
local MAX_TIMES = 20
local INTERVAL = 0.1

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.entity:AddLight()
    inst.Light:Enable(true)
    inst.Light:SetRadius(.5)
    inst.Light:SetFalloff(.9)
    inst.Light:SetIntensity(0)
    inst.Light:SetColour(210 / 255, 210 / 255, 240 / 255)

    inst:AddTag("NOBLOCK")
    inst:AddTag("DECOR")

    inst.AnimState:SetBank("aip_ocean_jellyfish")
    inst.AnimState:SetBuild("aip_ocean_jellyfish")
    inst.AnimState:PlayAnimation("idle", true)
    -- inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGroundFixed)
    inst.AnimState:SetLayer(LAYER_BELOW_GROUND)
    inst.AnimState:SetSortOrder(ANIM_SORT_ORDER_BELOW_GROUND.UNDERWATER)
    inst.AnimState:SetFinalOffset(0)
    inst.AnimState:SetOceanBlendParams(TUNING.OCEAN_SHADER.EFFECT_TINT_AMOUNT)
    inst.AnimState:SetInheritsSortKey(false)

    local scale = 0.3 + math.random() * 0.2
    inst.AnimState:SetScale(scale, scale, scale)
    inst.AnimState:OverrideMultColour(1, 1, 1, 0)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then return inst end

    inst.persists = false

    inst._aipTimes = 0
    local depth = 0.8 + math.random() * 0.1

    inst._aipFadeTask = inst:DoPeriodicTask(INTERVAL, function()
        inst._aipTimes = inst._aipTimes + 1
        local ptg = inst._aipTimes / MAX_TIMES

        -- 调整颜色，逐渐出现
        inst.AnimState:OverrideMultColour(1, 1, 1, depth * ptg)
        inst.Light:SetIntensity(.8 * ptg)

        if inst._aipTimes >= MAX_TIMES then
            inst._aipFadeTask:Cancel()
            inst._aipFadeTask = nil
            return
        end
    end)

    inst._aipFakeOut = function()
        local leaveId = math.random(1, 3)
        inst.AnimState:PlayAnimation("leave"..leaveId)

        inst._aipFadeOutTask = inst:DoPeriodicTask(INTERVAL, function()
            inst._aipTimes = inst._aipTimes - 1
            local ptg = inst._aipTimes / MAX_TIMES

            -- 调整颜色，逐渐消失
            inst.AnimState:OverrideMultColour(1, 1, 1, depth * ptg)
            inst.Light:SetIntensity(.8 * ptg)

            if inst._aipTimes <= 0 then
                inst:Remove()
                return
            end
        end)
    end

    return inst
end

--------------------------------- 群体 -----------------------------------
local function onFadeOut(inst)
    inst:DoTaskInTime(INTERVAL * MAX_TIMES, inst.Remove)

    for i, v in ipairs(inst._aipList) do
        if v._aipFakeOut then
            v._aipFakeOut()
        end
    end
end

local function grpFn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    inst:AddTag("NOBLOCK")
    inst:AddTag("DECOR")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("playerprox")
    inst.components.playerprox:SetDist(6, 10)
    inst.components.playerprox:SetOnPlayerNear(onFadeOut)

    inst.persists = false
    inst._aipList = {}

    inst:DoTaskInTime(.5, function()
        local lv2 = math.random(3, 5)
        local lv3 = lv2 + math.random(1, 3)

        local center = SpawnPrefab("aip_ocean_jellyfish")
        inst:AddChild(center)
        table.insert(inst._aipList, center)
        center.Transform:SetPosition(0, 0, 0)

        for i = 1, lv2 do
            local child = SpawnPrefab("aip_ocean_jellyfish")
            table.insert(inst._aipList, child)
            inst:AddChild(child)

            local angle = 2 * PI * (i + math.random() / 2) / lv2
            local radius = 0.9 + math.random() * 0.5
            child.Transform:SetPosition(radius * math.cos(angle), 0,
                                        radius * math.sin(angle))
        end

        for i = 1, lv3 do
            local child = SpawnPrefab("aip_ocean_jellyfish")
            table.insert(inst._aipList, child)
            inst:AddChild(child)

            local angle = 2 * PI * (i + math.random() / 2) / lv3
            local radius = 2.5 + math.random() * 0.5
            child.Transform:SetPosition(radius * math.cos(angle), 0,
                                        radius * math.sin(angle))
        end
    end)

    inst:WatchWorldState("isnight", function(_, isnight)
		if not isnight then
			onFadeOut(inst)
		end
	end)

    return inst
end

return Prefab("aip_ocean_jellyfish", fn, assets),
       Prefab("aip_ocean_jellyfish_group", grpFn, assets)
