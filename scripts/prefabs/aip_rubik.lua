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
    inst.components.fueled:InitializeFuelLevel(dev_mode and TUNING.NIGHTLIGHT_FUEL_START or 0)

	return inst
end

return Prefab("aip_rubik", fn, assets, prefabs)
