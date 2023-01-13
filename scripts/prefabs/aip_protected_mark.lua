-- 配置
local additional_building = aipGetModConfig("additional_building")
if additional_building ~= "open" then
	return nil
end

local language = aipGetModConfig("language")

local LANG_MAP = {
	english = {
		NAME = "Peace Sign",
		RECDESC = "To hold a doll fighting competition, you need to put the dolls into the field to activate the game.",
		DESC = "Let's have fun!",
	},
	chinese = {
		NAME = "和平标识",
		RECDESC = "举办玩偶战斗比赛，需要将玩偶放入场地激活游戏。",
		DESC = "让我们玩个痛快！",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

-- 文字描述
STRINGS.NAMES.AIP_PROTECTED_MARK = LANG.NAME
STRINGS.RECIPE_DESC.AIP_PROTECTED_MARK = LANG.RECDESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_PROTECTED_MARK = LANG.DESC

---------------------------------- 资源 ----------------------------------
require "prefabutil"

local assets = {
	Asset("ANIM", "anim/aip_protected_mark.zip"),
	-- Asset("ATLAS", "images/inventoryimages/aip_glass_chest.xml"),
}

local prefabs = {}


---------------------------------- 事件 ----------------------------------
local function onhammered(inst, worker)
	local fx = aipReplacePrefab(inst, "collapse_small"):SetMaterial("wood")
end

-- local function onhit(inst, worker)
-- 	inst.AnimState:PlayAnimation("hit")
-- 	inst.AnimState:PushAnimation("idle")
-- end

local function onbuilt(inst)
	inst.AnimState:PlayAnimation("place")
	inst.AnimState:PushAnimation("idle")
	inst.SoundEmitter:PlaySound("dontstarve/common/chest_craft")
end

---------------------------------- 实体 ----------------------------------
local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddMiniMapEntity()
	inst.entity:AddNetwork()

	inst:AddTag("structure")

	inst.AnimState:SetBank("aip_protected_mark")
	inst.AnimState:SetBuild("aip_protected_mark")
	inst.AnimState:PlayAnimation("idle")

	MakeObstaclePhysics(inst, .1)

	--Dedicated server does not need deployhelper
	-- if not TheNet:IsDedicated() then
	-- 	inst:AddComponent("deployhelper")
	-- 	inst.components.deployhelper.onenablehelper = OnEnableHelper
	-- end
	
	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("inspectable")

	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
	inst.components.workable:SetWorkLeft(3)
	inst.components.workable:SetOnFinishCallback(onhammered)
	-- inst.components.workable:SetOnWorkCallback(onhit)

	MakeHauntableLaunch(inst)

	inst:ListenForEvent("onbuilt", onbuilt)

	return inst
end

-- -------------------------------- 影响范围 --------------------------------
-- local function placer_postinit_fn(inst)
--     --Show the flingo placer on top of the flingo range ground placer

--     local placer2 = CreateEntity()

--     --[[Non-networked entity]]
--     placer2.entity:SetCanSleep(false)
--     placer2.persists = false

--     placer2.entity:AddTransform()
--     placer2.entity:AddAnimState()

--     placer2:AddTag("CLASSIFIED")
--     placer2:AddTag("NOCLICK")
--     placer2:AddTag("placer")

--     local s = 1 / PLACER_SCALE
--     placer2.Transform:SetScale(s, s, s)

--     placer2.AnimState:SetBank("aip_protected_mark")
--     placer2.AnimState:SetBuild("aip_protected_mark")
--     placer2.AnimState:PlayAnimation("idle")
--     placer2.AnimState:SetLightOverride(1)

--     placer2.entity:SetParent(inst.entity)

--     inst.components.placer:LinkEntity(placer2)
-- end

return Prefab("aip_protected_mark", fn, assets, prefabs),
		MakePlacer("aip_protected_mark_placer", "firefighter_placement", "firefighter_placement", "idle")
	-- MakePlacer(
	-- 	"aip_protected_mark_placer", "firefighter_placement", "firefighter_placement", "idle",
	-- 	true, nil, nil, PLACER_SCALE, nil, nil, placer_postinit_fn)
