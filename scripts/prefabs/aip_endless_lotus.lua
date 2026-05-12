local language = aipGetModConfig("language")

require "prefabutil"

local skinUtil = require("utils/aip_skin_util")
local lotusConfig = require("configurations/skin/aip_endless_lotus")

local PREFAB = "aip_endless_lotus"
local SEED_PREFAB = "aip_endless_lotus_seed"
local RIPPLE_PREFAB = "aip_endless_lotus_ripple"
local BUILD = "aip_endless_lotus"
local PLACER = "aip_endless_lotus_placer"

local LANG_MAP = {
	english = {
		LOTUS_NAME = "Endless Lotus",
		LOTUS_DESC = "It blooms between waves.",
		SEED_NAME = "Endless Lotus Seed",
		SEED_DESC = "It wants a quiet stretch of sea.",
	},
	chinese = {
		LOTUS_NAME = "无尽之莲",
		LOTUS_DESC = "它在浪间静静绽放。",
		SEED_NAME = "无尽之莲子",
		SEED_DESC = "它想落在一片安静的海面上。",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_ENDLESS_LOTUS = LANG.LOTUS_NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_ENDLESS_LOTUS = LANG.LOTUS_DESC
STRINGS.NAMES.AIP_ENDLESS_LOTUS_SEED = LANG.SEED_NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_ENDLESS_LOTUS_SEED = LANG.SEED_DESC
skinUtil.RegisterBuildSkinConfig(lotusConfig, language, LANG.LOTUS_DESC)

local assets = {
	Asset("ANIM", "anim/aip_endless_lotus.zip"),
	Asset("ATLAS", "images/inventoryimages/aip_endless_lotus_seed.xml"),
}

local rippleAssets = {
	Asset("ANIM", "anim/oceanfishing_hook.zip"),
}

for _, asset in ipairs(lotusConfig.GetInventoryAtlasAssets(true)) do
	table.insert(assets, asset)
end

local LOTUS_SKINS = { "style_1", "style_2", "style_3" }
local LOTUS_DEPLOY_RANGE_SPACING = DEPLOYSPACING.LARGE
local LOTUS_WATER_DEPLOY_RADIUS = 0
local LOTUS_RIPPLE_SCALE = 2.35

-- 刷新当前莲花样式动画。
local function playSkin(inst, skin)
	inst.AnimState:PlayAnimation(lotusConfig.GetSkin(skin), true)
end

local skinner = skinUtil.CreatePrefabSkinner(lotusConfig, {
	net_field = "_aipEndlessLotusSkin",
	current_field = "_aipCurrentSkin",
	dirty_event = "aip_endless_lotus_skindirty",
	set_fn_name = "SetLotusSkin",
	next_fn_name = "NextLotusSkin",
	play_fn = playSkin,
})

-- 随机切换一种莲花样式。
local function setRandomSkin(inst, allowSame)
	local currentSkin = not allowSame and lotusConfig.GetSkin(inst._aipCurrentSkin) or nil
	local nextSkin = LOTUS_SKINS[math.random(#LOTUS_SKINS)]

	if currentSkin ~= nil and #LOTUS_SKINS > 1 then
		while nextSkin == currentSkin do
			nextSkin = LOTUS_SKINS[math.random(#LOTUS_SKINS)]
		end
	end

	inst:SetAipSkin(nextSkin)
end

-- 挖掉莲花时返还一颗莲子。
local function onDug(inst)
	inst.components.lootdropper:DropLoot()

	local splash = SpawnPrefab("splash")
	if splash ~= nil then
		splash.Transform:SetPosition(inst.Transform:GetWorldPosition())
	end

	inst:Remove()
end

-- 读取存档时恢复魔法扫把切换过的样式。
local function onLoad(inst, data)
	skinner.OnLoad(inst, data)
end

-- 将莲子种到海面并随机选择莲花样式。
local function onDeploy(inst, pt, deployer)
	inst = inst.components.stackable:Get()

	local lotus = SpawnPrefab(PREFAB)
	if lotus ~= nil then
		lotus.Transform:SetPosition(pt:Get())
		lotus:RandomLotusSkin(true)
	end

	local splash = SpawnPrefab("splash")
	if splash ~= nil then
		splash.Transform:SetPosition(pt:Get())
	end

	inst:Remove()
end

-- 判断莲子是否能种到目标水面，避免把长距离操作误用为落点清空半径。
local function canDeployLotusSeed(inst, pt, mouseover)
	return TheWorld.Map:CanDeployAtPointInWater(pt, inst, mouseover, {
		land = 0.2,
		boat = 0.2,
		radius = LOTUS_WATER_DEPLOY_RADIUS,
	})
end

-- 创建跟随莲花循环播放的水波纹特效。
local function rippleFn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()

	inst:AddTag("CLASSIFIED")
	inst:AddTag("FX")
	inst:AddTag("NOCLICK")

	inst.AnimState:SetBank("oceanfishing_hook")
	inst.AnimState:SetBuild("oceanfishing_hook")
	inst.AnimState:PlayAnimation("fx_ripple_small", true)
	inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
	inst.AnimState:SetLayer(LAYER_BELOW_GROUND)
	inst.AnimState:SetSortOrder(ANIM_SORT_ORDER_BELOW_GROUND.UNDERWATER)

	inst.persists = false

	return inst
end

-- 在客户端给莲花挂上动态水波纹。
local function addRippleFx(inst)
	if not TheNet:IsDedicated() then
		local ripple = SpawnPrefab(RIPPLE_PREFAB)

		if ripple ~= nil then
			inst:AddChild(ripple)
			ripple.Transform:SetPosition(0, 0, 0)
			ripple.Transform:SetScale(LOTUS_RIPPLE_SCALE, LOTUS_RIPPLE_SCALE, LOTUS_RIPPLE_SCALE)
			inst._aipRipple = ripple
		end
	end
end

local function lotusFn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	inst:AddTag("plant")
	inst:AddTag("aip_endless_lotus")
	inst:AddTag("ignorewalkableplatforms")

	inst.AnimState:SetBank(BUILD)
	inst.AnimState:SetBuild(BUILD)
	inst.AnimState:SetFinalOffset(1)
	inst.AnimState:SetRayTestOnBB(true)

	skinner.SetupNetwork(inst)
	inst.RandomLotusSkin = setRandomSkin
	inst.RandomAipSkin = setRandomSkin
	addRippleFx(inst)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	skinner.SetupMaster(inst)

	inst:AddComponent("inspectable")

	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetLoot({ SEED_PREFAB })

	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.DIG)
	inst.components.workable:SetWorkLeft(1)
	inst.components.workable:SetOnFinishCallback(onDug)

	inst.OnSave = skinner.OnSave
	inst.OnLoad = onLoad

	MakeHauntableWork(inst)

	return inst
end

local function seedFn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)

	inst.AnimState:SetBank(BUILD)
	inst.AnimState:SetBuild(BUILD)
	inst.AnimState:PlayAnimation("seed")

	inst:AddTag("deployedplant")
	-- 海边种植需要更远的操作距离，实际落点半径由自定义部署函数控制。
	inst:AddTag("usedeployspacingasoffset")
	inst._custom_candeploy_fn = canDeployLotusSeed

	inst.scrapbook_specialinfo = "PLANTABLE"
	inst.overridedeployplacername = PLACER

	MakeInventoryFloatable(inst, "med", 0.2, 0.75)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("inspectable")

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_endless_lotus_seed.xml"
	inst.components.inventoryitem.imagename = "aip_endless_lotus_seed"

	inst:AddComponent("stackable")
	inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

	inst:AddComponent("tradable")
	inst.components.tradable.goldvalue = 1

	inst:AddComponent("deployable")
	inst.components.deployable:SetDeployMode(DEPLOYMODE.CUSTOM)
	inst.components.deployable:SetDeploySpacing(LOTUS_DEPLOY_RANGE_SPACING)
	inst.components.deployable.ondeploy = onDeploy

	MakeHauntableLaunch(inst)

	return inst
end

local prefabs = {
	Prefab(PREFAB, lotusFn, assets, { "splash", SEED_PREFAB, RIPPLE_PREFAB }),
	Prefab(SEED_PREFAB, seedFn, assets, { "splash", PREFAB }),
	Prefab(RIPPLE_PREFAB, rippleFn, rippleAssets),
	MakePlacer(PLACER, BUILD, BUILD, lotusConfig.DEFAULT_SKIN),
}

for _, skinPrefab in ipairs(skinner.CreatePrefabSkins()) do
	table.insert(prefabs, skinPrefab)
end

return unpack(prefabs)
