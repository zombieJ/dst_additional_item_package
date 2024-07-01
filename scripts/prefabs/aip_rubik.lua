local dev_mode = aipGetModConfig("dev_mode") == "enabled"

local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Magic Rubik",
		DESC = "We need reset it!",
	},
	chinese = {
		NAME = "魔力方阵",
		DESC = "我们需要重置它！",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_RUBIK = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_RUBIK = LANG.DESC

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_rubik.zip"),
}

local prefabs = {
	"aip_rubik_fire_blue",
	"aip_rubik_fire_green",
	"aip_rubik_fire_red",
}

------------------------------- 火焰 -------------------------------
-- 不同的火焰来源可以产生不同的火焰特效

------------------------------- 燃烧 -------------------------------
local function onextinguish(inst)
    if inst.components.fueled ~= nil then
        inst.components.fueled:InitializeFuelLevel(0)
    end
	inst:RemoveTag("shadow_fire")
	inst.components.aipc_rubik:Stop()
end

local function onignite(inst)
	inst:AddTag("shadow_fire")
	inst.components.aipc_rubik:Start()
end

------------------------------- 混合 -------------------------------
local function OnFullMoon(inst, isfullmoon)
    if not isfullmoon then
        return
    end

    -- 生成冰猎犬
    local hound = aipSpawnPrefab(inst, "icehound")
    hound.persists = false
    hound.components.follower:SetLeader(inst)
end

local function syncTypeFireFx(inst, instVar, instRef, prefabName, tag, centerFire)
    -- 如果在燃烧，我们取消 冰火 特效
    if inst.components.burnable:IsBurning() or not inst[instVar] then
        if inst[instRef] ~= nil then
            inst[instRef]:Remove()
            inst[instRef] = nil
            inst[instVar] = false
        end

        return
    end

    -- 如果没有燃烧，我们添加 冰火 特效
    if inst[instVar] and not inst[instRef] then
        local scale = centerFire and 0.65 or 1
        local fx = inst:SpawnChild(prefabName)
        fx.Transform:SetScale(scale, scale, scale)
        fx.entity:AddFollower()
        fx.Follower:FollowSymbol(
            inst.GUID, "fire_marker", 0,
            centerFire and -30 or 0, centerFire and 0.1 or 0
        )

        fx:AddTag("aip_torchfire")
        fx:AddTag(tag)

        if fx.components.firefx then
            fx.components.firefx:SetLevel(4)
        end

        inst[instRef] = fx
    end
end

local function syncFireFx(inst)
    syncTypeFireFx(inst, "_aipIsHot", "_aipHotFire", "campfirefire", "aip_torchfire_hot", true)
    syncTypeFireFx(inst, "_aipIsCold", "_aipColdFire", "coldfirefire", "aip_torchfire_cold")
end

-- 根据附近死亡的狗狗来决定要不要点火
local function syncFire(inst, data)
    if data.inst == nil or not inst:IsNear(data.inst, 10) then
        return
    end

    -- 计量器
    if data.inst.prefab == "firehound" then
        inst._aipIsHot = true
    elseif data.inst.prefab == "icehound" then
        inst._aipIsCold = true
    end

    syncFireFx(inst)
end

------------------------------- 燃料 -------------------------------
local function ontakefuel(inst)
    inst.SoundEmitter:PlaySound("dontstarve/common/nightmareAddFuel")
end

local function onupdatefueled(inst)
    if inst.components.burnable ~= nil then
        inst.components.burnable:SetFXLevel(inst.components.fueled:GetCurrentSection(), inst.components.fueled:GetSectionPercent())
    end
end

local function onfuelchange(newsection, oldsection, inst)
    if newsection <= 0 then
        inst.components.burnable:Extinguish()
    else
        if not inst.components.burnable:IsBurning() then
            inst.components.burnable:Ignite()
        end

        inst.components.burnable:SetFXLevel(newsection, inst.components.fueled:GetSectionPercent())
    end

    syncFireFx(inst)
end

------------------------------- 实体 -------------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, .2)

    inst.AnimState:SetBank("aip_rubik")
    inst.AnimState:SetBuild("aip_rubik")
    inst.AnimState:PlayAnimation("idle")

	inst:AddTag("wildfireprotected")
    inst:AddTag("aip_rubik")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("aipc_rubik")

	-- 可以点燃
	inst:AddComponent("burnable")
    inst.components.burnable:AddBurnFX("nightlight_flame", Vector3(0, 0, 0), "fire_marker")
    inst.components.burnable.canlight = false
    inst:ListenForEvent("onextinguish", onextinguish)
	inst:ListenForEvent("onignite", onignite)

    -- -- 添加类型火焰特效
    -- inst:AddComponent("aipc_type_fire")
    -- inst.components.aipc_type_fire.hotPrefab = "aip_hot_torchfire"
	-- inst.components.aipc_type_fire.coldPrefab = "aip_cold_torchfire"
	-- inst.components.aipc_type_fire.followSymbol = "swap_object"
	-- inst.components.aipc_type_fire.followOffset = Vector3(0, -140, 0)

	-- 使用燃料
	inst:AddComponent("fueled")
    inst.components.fueled.maxfuel = TUNING.NIGHTLIGHT_FUEL_MAX
    inst.components.fueled.accepting = true
    inst.components.fueled.fueltype = FUELTYPE.NIGHTMARE
    inst.components.fueled:SetSections(4)
    inst.components.fueled:SetTakeFuelFn(ontakefuel)
    inst.components.fueled:SetUpdateFn(onupdatefueled)
    inst.components.fueled:SetSectionCallback(onfuelchange)
    inst.components.fueled:InitializeFuelLevel(0) -- dev_mode TUNING.NIGHTLIGHT_FUEL_START

    inst:WatchWorldState("isfullmoon", OnFullMoon)
    OnFullMoon(inst, TheWorld.state.isfullmoon)

    -- 监听附近是否有冰火狗死了
    inst._onEntityDeath = function(src, data)
        syncFire(inst, data)
    end
    inst:ListenForEvent("entity_death", inst._onEntityDeath, TheWorld)

    inst._aipIsHot = false
    inst._aipIsCold = false

	return inst
end

return Prefab("aip_rubik", fn, assets, prefabs)
