-- 配置
local additional_building = aipGetModConfig("additional_building")
if additional_building ~= "open" then
	return nil
end

local fly_totem = aipGetModConfig("fly_totem")
if fly_totem == "close" then
	return nil
end

local language = aipGetModConfig("language")

local LANG_MAP = {
	english = {
		NAME = "Fly Totem",
		RECDESC = "Unicom's flight site",
        DESC = "To Infinity... and Beyond",
        UNNAMED = "[UNNAMED]",
        CURRENT = "I'm already here!",
        IN_DANGER = "It's not safe time to travel!",
	},
	chinese = {
		NAME = "飞行图腾",
		RECDESC = "联通的飞行站点",
        DESC = "飞向宇宙，浩瀚无垠！",
        UNNAMED = "[未命名]",
        CURRENT = "我就在这里！",
        IN_DANGER = "这不是一个安全旅行的时机",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

-- 文字描述
STRINGS.NAMES.AIP_FLY_TOTEM = LANG.NAME
STRINGS.RECIPE_DESC.AIP_FLY_TOTEM = LANG.RECDESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_FLY_TOTEM = LANG.DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_FLY_TOTEM_UNNAMED = LANG.UNNAMED
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_FLY_TOTEM_CURRENT = LANG.CURRENT
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_FLY_TOTEM_IN_DANGER = LANG.IN_DANGER

-- 配方
local aip_fly_totem = Recipe("aip_fly_totem", {Ingredient("boards", 1)}, RECIPETABS.TOWN, TECH.SCIENCE_ONE, "aip_fly_totem_placer")
aip_fly_totem.atlas = "images/inventoryimages/aip_fly_totem.xml"

---------------------------------- 资源 ----------------------------------
require "prefabutil"

local assets = {
	Asset("ANIM", "anim/aip_fly_totem.zip"),
	Asset("ATLAS", "images/inventoryimages/aip_fly_totem.xml"),
}

local prefabs = {}

---------------------------------- 事件 ----------------------------------
local function onhammered(inst, worker)
	if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
		inst.components.burnable:Extinguish()
	end
	inst.components.lootdropper:DropLoot()
	local fx = SpawnPrefab("collapse_small")
	fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
	fx:SetMaterial("wood")
	inst:Remove()
end

local function onhit(inst, worker)
	if not inst:HasTag("burnt") then
		inst.AnimState:PlayAnimation("hit")
		inst.AnimState:PushAnimation("idle", false)
	end
end

local function onbuilt(inst)
    inst.SoundEmitter:PlaySound("dontstarve/common/sign_craft")
end

local function canBeActOn(inst, doer)
	return not inst:HasTag("writeable")
end

---------------------------------- 实体 ----------------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    -- inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, .2)

    -- inst.MiniMapEntity:SetIcon("sign.png")

    inst.AnimState:SetBank("aip_fly_totem")
    inst.AnimState:SetBuild("aip_fly_totem")
    inst.AnimState:PlayAnimation("idle")

    MakeSnowCoveredPristine(inst)

    inst:AddTag("structure")
    -- inst:AddTag("sign")

    --Sneak these into pristine state for optimization
    inst:AddTag("_writeable")

    -- 添加飞行图腾
    inst:AddComponent("aipc_fly_picker_client")

	inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    --Remove these tags so that they can be added properly when replicating components below
    inst:RemoveTag("_writeable")

    inst:AddComponent("inspectable")
    inst:AddComponent("writeable")
    inst:AddComponent("lootdropper")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(onhit)

    MakeSnowCovered(inst)

    MakeSmallBurnable(inst, TUNING.LARGE_BURNTIME)
    MakeSmallPropagator(inst)
    -- inst.OnSave = onsave
    -- inst.OnLoad = onload

    MakeHauntableWork(inst)
    inst:ListenForEvent("onbuilt", onbuilt)

    return inst
end

return Prefab("aip_fly_totem", fn, assets, prefabs),
    MakePlacer("aip_fly_totem_placer", "aip_fly_totem", "aip_fly_totem", "idle")
