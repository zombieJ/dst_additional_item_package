local dev_mode = aipGetModConfig("dev_mode") == "enabled"

local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Magic Rubik",
		DESC = "We need reset it!",
        DESC_HOT = "I need a fire hound",
        DESC_COLD = "I need an ice hound",
        DESC_MIX = "Ask a Bumblebee for a match",
	},
	chinese = {
		NAME = "魔力方阵",
		DESC = "我们需要重置它！",
        DESC_HOT = "我需要一只冰猎犬",
        DESC_COLD = "我需要一只火猎犬",
        DESC_MIX = "找熊蜂要根火柴吧",
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

    -- 看看附近有没有 tag 为 hound 的实体
    local x,y,z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 10, {"hound"})
    if #ents > 0 then
        return
    end

    -- 生成冰猎犬
    local hound = aipSpawnPrefab(inst, "icehound")
    hound.persists = false
    hound.components.follower:SetLeader(inst)
end

local function syncFireFx(inst)
    -- 如果在燃烧，我们取消 冰火 特效
    if inst.components.burnable:IsBurning() then
        inst.components.aipc_type_fire:StopFire()
        return
    end

    -- 如果有颜色的火焰，则停掉传统的火焰
    if inst.components.aipc_type_fire:IsBurning() then
        inst.components.burnable:Extinguish()
        return
    end
end

-- 根据附近死亡的狗狗来决定要不要点火
local function syncFireByHound(inst, data)
    if data.inst == nil or not inst:IsNear(data.inst, 10) then
        return
    end

    -- 计量器
    if data.inst.prefab == "firehound" then
       inst.components.aipc_type_fire:StartFire("hot")
    elseif data.inst.prefab == "icehound" then
        inst.components.aipc_type_fire:StartFire("cold")
    end

    syncFireFx(inst)
end

local function postTypeFire(inst, fx, type)
    fx:RemoveTag("aip_rubik_fire")

    if type == "mix" then
        fx.AnimState:OverrideMultColour(1, 0, 1, 1)
    end

    if fx.components.firefx then
        fx.components.firefx:SetLevel(4)
    end

    fx:AddTag("aip_rubik_fire")
    fx:AddTag("aip_rubik_fire_"..type)
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

------------------------------- 描述 -------------------------------
-- 根据火焰类型来显示不同的描述
local function getDesc(inst)
    local fireType = inst.components.aipc_type_fire:GetType()

    if fireType == "hot" then
        return LANG.DESC_HOT
    elseif fireType == "cold" then
        return LANG.DESC_COLD
    elseif fireType == "mix" then
        return LANG.DESC_MIX
    end

    return LANG.DESC
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
    inst:AddTag("aip_can_lighten") -- 让 aipc_lighter 可以点燃它

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst.components.inspectable.descriptionfn = getDesc

    inst:AddComponent("aipc_rubik")

	-- 可以点燃
	inst:AddComponent("burnable")
    inst.components.burnable:AddBurnFX("nightlight_flame", Vector3(0, 0, 0), "fire_marker")
    inst.components.burnable.canlight = false
    inst:ListenForEvent("onextinguish", onextinguish)
	inst:ListenForEvent("onignite", onignite)

    -- 添加类型火焰特效
    inst:AddComponent("aipc_type_fire")
    inst.components.aipc_type_fire.canMix = true
    inst.components.aipc_type_fire.hotPrefab = "campfirefire"
	inst.components.aipc_type_fire.coldPrefab = "coldfirefire"
    inst.components.aipc_type_fire.mixPrefab = "coldfirefire"
	inst.components.aipc_type_fire.followSymbol = "fire_marker"
	inst.components.aipc_type_fire.followOffset = Vector3(0, 0, 0)
    inst.components.aipc_type_fire.postFireFn = postTypeFire

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
        syncFireByHound(inst, data)
    end
    inst:ListenForEvent("entity_death", inst._onEntityDeath, TheWorld)

    if dev_mode then
        inst:DoTaskInTime(1, function()
            inst.components.aipc_type_fire:StartFire("mix", nil, 5)
        end)
    end

	return inst
end

return Prefab("aip_rubik", fn, assets, prefabs)
