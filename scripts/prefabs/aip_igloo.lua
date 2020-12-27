------------------------------------ 配置 ------------------------------------
-- 建筑关闭
local additional_building = aipGetModConfig("additional_building")
if additional_building ~= "open" then
	return nil
end

local language = aipGetModConfig("language")

local LANG_MAP = {
	english = {
		NAME = "Igloo",
        DESC = "No break in winter",
        COLD = "It's frozen!",
        MELT = "It's melting",
	},
	chinese = {
		NAME = "雪人小屋",
        DESC = "冬天不会消耗耐久度",
        COLD = "冻得结结实实的",
        MELT = "有些融化了",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

-- 文字描述
STRINGS.NAMES.AIP_IGLOO = LANG.NAME
STRINGS.RECIPE_DESC.AIP_IGLOO = LANG.DESC
STRINGS.AIP.AIP_IGLOO_COLD = LANG.COLD
STRINGS.AIP.AIP_IGLOO_MELT = LANG.MELT



require "prefabutil"

local igloo_assets =
{
    Asset("ANIM", "anim/aip_igloo.zip"),
    Asset("ATLAS", "images/inventoryimages/aip_igloo.xml"),
}

-----------------------------------------------------------------------
--For regular tents

local function PlaySleepLoopSoundTask(inst, stopfn)
    inst.SoundEmitter:PlaySound("dontstarve/common/tent_sleep")
end

local function stopsleepsound(inst)
    if inst.sleep_tasks ~= nil then
        for i, v in ipairs(inst.sleep_tasks) do
            v:Cancel()
        end
        inst.sleep_tasks = nil
    end
end

local function startsleepsound(inst, len)
    stopsleepsound(inst)
    inst.sleep_tasks =
    {
        inst:DoPeriodicTask(len, PlaySleepLoopSoundTask, 33 * FRAMES),
        inst:DoPeriodicTask(len, PlaySleepLoopSoundTask, 47 * FRAMES),
    }
end

-----------------------------------------------------------------------

local function onhammered(inst, worker)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
        inst.components.burnable:Extinguish()
    end
    inst.components.lootdropper:DropLoot()
    local fx = SpawnPrefab("collapse_big")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("wood")
    inst:Remove()
end

local function onhit(inst, worker)
    if not inst:HasTag("burnt") then
        stopsleepsound(inst)
        inst.AnimState:PlayAnimation("hit")
        inst.AnimState:PushAnimation("idle", true)
    end
    if inst.components.sleepingbag ~= nil and inst.components.sleepingbag.sleeper ~= nil then
        inst.components.sleepingbag:DoWakeUp()
    end
end

local function onfinishedsound(inst)
    inst.SoundEmitter:PlaySound("dontstarve/common/tent_dis_twirl")
end

local function onfinished(inst)
    if not inst:HasTag("burnt") then
        stopsleepsound(inst)
        inst.AnimState:PlayAnimation("destroy")
        inst:ListenForEvent("animover", inst.Remove)
        inst.SoundEmitter:PlaySound("dontstarve/common/tent_dis_pre")
        inst.persists = false
        inst:DoTaskInTime(16 * FRAMES, onfinishedsound)
    end
end

local function onignite(inst)
    inst.components.sleepingbag:DoWakeUp()
end

local function onsleep(inst, sleeper)
    sleeper:ListenForEvent("onignite", onignite, inst)

    if inst.sleep_anim ~= nil then
        inst.AnimState:PlayAnimation(inst.sleep_anim, true)
        startsleepsound(inst, inst.AnimState:GetCurrentAnimationLength())
    end
end

local function onsave(inst, data)
    if inst:HasTag("burnt") or (inst.components.burnable ~= nil and inst.components.burnable:IsBurning()) then
        data.burnt = true
    end
end

local function onload(inst, data)
    if data ~= nil and data.burnt then
        inst.components.burnable.onburnt(inst)
    end
end

local function temperaturetick(inst, sleeper)
    if sleeper.components.temperature ~= nil then
        if inst.is_cooling then
            if sleeper.components.temperature:GetCurrent() > TUNING.SLEEP_TARGET_TEMP_TENT then
                sleeper.components.temperature:SetTemperature(sleeper.components.temperature:GetCurrent() - TUNING.SLEEP_TEMP_PER_TICK)
            end
        elseif sleeper.components.temperature:GetCurrent() < TUNING.SLEEP_TARGET_TEMP_TENT then
            sleeper.components.temperature:SetTemperature(sleeper.components.temperature:GetCurrent() + TUNING.SLEEP_TEMP_PER_TICK)
        end
    end
end

local function onWake(inst, sleeper, nostatechange)
    sleeper:RemoveEventCallback("onignite", onignite, inst)

    if inst.sleep_anim ~= nil then
        inst.AnimState:PushAnimation("idle", true)
        stopsleepsound(inst)
    end

    -- 如果配置过使用方式则用自定义的
    if inst.onUse ~= nil then
        inst.onUse(inst)
    else
        inst.components.finiteuses:Use()
    end
end

local function onBuilt(inst)
    inst.AnimState:PlayAnimation("place")
    inst.AnimState:PushAnimation("idle", true)
    inst.SoundEmitter:PlaySound("dontstarve/common/tent_craft")
end

local function common_fn(name, config)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 1)

    inst:AddTag("tent")
    inst:AddTag("structure")
    if config.tag ~= nil then
        inst:AddTag(config.tag)
    end

    inst.AnimState:SetBank(name)
    inst.AnimState:SetBuild(name)
    inst.AnimState:PlayAnimation("idle", true)

    inst.MiniMapEntity:SetIcon("tent.png")

    MakeSnowCoveredPristine(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.onUse = config.onUse

    inst:AddComponent("inspectable")

    inst:AddComponent("lootdropper")
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(onhit)

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetOnFinished(onfinished)

    inst:AddComponent("sleepingbag")
    inst.components.sleepingbag.onsleep = onsleep
    inst.components.sleepingbag.health_tick = TUNING.SLEEP_HEALTH_PER_TICK * 2
    --convert wetness delta to drying rate
    inst.components.sleepingbag.dryingrate = math.max(0, -TUNING.SLEEP_WETNESS_PER_TICK / TUNING.SLEEP_TICK_PERIOD)
    inst.components.sleepingbag:SetTemperatureTickFn(temperaturetick)

    inst.components.sleepingbag.onwake = onWake

    MakeSnowCovered(inst)
    inst:ListenForEvent("onbuilt", onBuilt)

    if config.burnable then
        MakeLargeBurnable(inst, nil, nil, true)
        MakeMediumPropagator(inst)
    end

    inst.OnSave = onsave
    inst.OnLoad = onload

    MakeHauntableWork(inst)

    return inst
end

--------------------------------------- 冰屋 ---------------------------------------
-- 配方
local aip_igloo = Recipe("aip_igloo", {Ingredient("ice", 21), Ingredient("carrot", 1), Ingredient("twigs", 2)}, RECIPETABS.SURVIVAL, TECH.SCIENCE_TWO, "aip_igloo_placer")
aip_igloo.atlas = "images/inventoryimages/aip_igloo.xml"

-- local function TemperatureChange(inst, data)
--     local curTemp = inst.components.temperature:GetCurrent()
--     aipTypePrint("temp:", curTemp)
-- end

local function onUseIgloo(inst)
    local curTemp = inst.components.temperature:GetCurrent()
    if curTemp > 3 then -- 超过 3 度就开始消费使用次数
        inst.components.finiteuses:Use()
    else -- 反之充满
        inst.components.finiteuses:SetPercent(1)
    end
end

local function getIglooDesc(inst)
    local curTemp = inst.components.temperature:GetCurrent()
    if curTemp > 3 then
        return STRINGS.AIP.AIP_IGLOO_MELT
    end
    return STRINGS.AIP.AIP_IGLOO_COLD
end

local function igloo()
    local inst = common_fn("aip_igloo", {
        tag = "siestahut", -- 移除这个 TAG
        burnable = false,
        onUse = onUseIgloo,
    })

    inst:AddTag("meltable")

    if not TheWorld.ismastersim then
        return inst
    end

    -- TODO: 临时添加一个白天睡觉开发用
    inst.components.sleepingbag:SetSleepPhase("day")

    inst.components.inspectable.descriptionfn = getIglooDesc

    inst.sleep_anim = "sleep_loop"
    inst.components.sleepingbag.hunger_tick = TUNING.SLEEP_HUNGER_PER_TICK

    -- 雪人小屋和帐篷有一样的使用次数，只是在冬天不会消费
    inst.components.finiteuses:SetMaxUses(TUNING.TENT_USES)
    inst.components.finiteuses:SetUses(TUNING.TENT_USES)

    -- 雪人小屋自己有温度
    inst:AddComponent("temperature")
    -- inst.components.temperature.current = TheWorld.state.temperature
    inst.components.temperature.current = -20 -- 初始低温
    inst.components.temperature.inherentinsulation = TUNING.INSULATION_MED
    inst.components.temperature.inherentsummerinsulation = TUNING.INSULATION_MED
    -- inst:ListenForEvent("temperaturedelta", TemperatureChange)

    return inst
end

return Prefab("aip_igloo", igloo, igloo_assets),
    MakePlacer("aip_igloo_placer", "aip_igloo", "aip_igloo", "idle")

--[[
                         c_give"aip_igloo"


self.inst:WatchWorldState("phase", function(inst, phase) 阶段
end)

]]