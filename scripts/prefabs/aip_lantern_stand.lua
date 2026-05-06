local language = aipGetModConfig("language")

require "prefabutil"

local skinUtil = require("utils/aip_skin_util")
local standConfig = require("configurations/skin/aip_lantern_stand")

local PREFAB = "aip_lantern_stand"
local BUILD = "aip_lantern_stand"
local SLOT_COUNT = 3
local DISPLAY_SYMBOL_PREFIX = "swap_lantern_"
local DISPLAY_SCALE = .9
local DISPLAY_FOLLOW_Z_OFFSET = .1
local DISPLAY_FOLLOW_Z_STEP = .25
local LIGHT_COLOUR = Vector3(200 / 255, 100 / 255, 100 / 255)

local LANG_MAP = {
	english = {
		NAME = "Lantern Stand",
		REC_DESC = "Hang lanterns where the wind can find them",
		DESC = "The lanterns sway softly in the breeze.",
	},
	chinese = {
		NAME = "灯笼架",
		REC_DESC = "把灯笼挂在风经过的地方",
		DESC = "灯笼在风里轻轻晃着。",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_LANTERN_STAND = LANG.NAME
STRINGS.RECIPE_DESC.AIP_LANTERN_STAND = LANG.REC_DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_LANTERN_STAND = LANG.DESC
skinUtil.RegisterBuildSkinConfig(standConfig, language, LANG.DESC)

local assets = {
	Asset("ANIM", "anim/aip_lantern_stand.zip"),
}

for _, asset in ipairs(standConfig.GetInventoryAtlasAssets(true)) do
	table.insert(assets, asset)
end

local DEFAULT_SKIN = standConfig.DEFAULT_SKIN
local queueRefreshLanternDisplays

local function playSkin(inst, skin, hit)
	skin = standConfig.GetSkin(skin)

	if hit then
		inst.AnimState:PlayAnimation(skin.."_hit")
		inst.AnimState:PushAnimation(skin, true)
	else
		inst.AnimState:PlayAnimation(skin, true)

		if TheWorld.ismastersim and queueRefreshLanternDisplays ~= nil then
			queueRefreshLanternDisplays(inst)
		end
	end
end

local skinner = skinUtil.CreatePrefabSkinner(standConfig, {
	net_field = "_aipLanternStandSkin",
	current_field = "_aipCurrentSkin",
	dirty_event = "aip_lantern_stand_skindirty",
	set_fn_name = "SetLanternStandSkin",
	next_fn_name = "NextLanternStandSkin",
	play_fn = playSkin,
})

local function getDisplaySymbol(slot)
	return DISPLAY_SYMBOL_PREFIX..slot
end

local function getDisplayZOffset(slot)
	return DISPLAY_FOLLOW_Z_OFFSET + (SLOT_COUNT - slot) * DISPLAY_FOLLOW_Z_STEP
end

local function getDisplayFinalOffset(slot)
	return SLOT_COUNT - slot + 1
end

local function getDisplayAnimSync(inst)
	if not inst.AnimState:IsCurrentAnimation(standConfig.GetSkin(inst._aipCurrentSkin)) then
		return nil, nil
	end

	local length = inst.AnimState:GetCurrentAnimationLength()

	if length ~= nil and length > 0 then
		return (inst.AnimState:GetCurrentAnimationTime() % length) / length, length
	end

	return nil, nil
end

local function isLanternLit(item)
	return item ~= nil
		and item.components.fueled ~= nil
		and not item.components.fueled:IsEmpty()
end

local function setLightCount(inst, count)
	if inst.Light == nil then
		return
	end

	inst.Light:Enable(count > 0)

	if count > 0 then
		inst.Light:SetRadius(1 + .35 * count)
		inst.Light:SetIntensity(.45 + .1 * count)
		inst.Light:SetFalloff(.7)
		inst.Light:SetColour(LIGHT_COLOUR.x, LIGHT_COLOUR.y, LIGHT_COLOUR.z)
	end
end

local function exposeDisplayItem(item)
	if item.Network ~= nil then
		item.Network:SetClassifiedTarget(nil)
	end

	local classified = item.replica ~= nil and
		item.replica.inventoryitem ~= nil and
		item.replica.inventoryitem.classified or nil

	if classified ~= nil and classified.Network ~= nil then
		classified.Network:SetClassifiedTarget(nil)
	end
end

local function isStoredDisplayItem(inst, item)
	return item ~= nil
		and item.components.inventoryitem ~= nil
		and item.components.inventoryitem.owner == inst
		and inst.components.container ~= nil
		and inst.components.container:GetItemSlot(item) ~= nil
end

local function forgetDisplayItem(inst, item)
	if inst._aipLanternStandDisplayItems == nil then
		return
	end

	for slot = 1, SLOT_COUNT do
		if inst._aipLanternStandDisplayItems[slot] == item then
			inst._aipLanternStandDisplayItems[slot] = nil
		end
	end
end

local function getDisplaySlotForItem(inst, item)
	if inst._aipLanternStandDisplayItems == nil then
		return nil
	end

	for slot = 1, SLOT_COUNT do
		if inst._aipLanternStandDisplayItems[slot] == item then
			return slot
		end
	end

	return nil
end

local function restoreDisplayScale(item)
	if item._aipLanternStandScale ~= nil then
		item.Transform:SetScale(unpack(item._aipLanternStandScale))
		item._aipLanternStandScale = nil
	else
		item.Transform:SetScale(1, 1, 1)
	end
end

local function onDisplayLanternFuelChanged(item)
	local stand = item._aipLanternStand

	if stand ~= nil and stand:IsValid() and queueRefreshLanternDisplays ~= nil then
		queueRefreshLanternDisplays(stand)
	end
end

local function unbindDisplayItem(inst, item, leaving)
	if item == nil or not item:IsValid() then
		forgetDisplayItem(inst, item)
		return
	end

	forgetDisplayItem(inst, item)
	inst:RemoveEventCallback("percentusedchange", onDisplayLanternFuelChanged, item)

	if item._aipLanternStand == inst then
		item._aipLanternStand = nil
		item._aipLanternStandDisplaySlot = nil
	end

	if item.Follower ~= nil then
		item.Follower:StopFollowing()
	end

	if item.ClearLanternStandDisplay ~= nil then
		item:ClearLanternStandDisplay()
	end

	restoreDisplayScale(item)
	if item.AnimState ~= nil then
		item.AnimState:SetFinalOffset(0)
	end
	item:RemoveTag("NOCLICK")
	item:ForceOutOfLimbo(false)

	if leaving or not isStoredDisplayItem(inst, item) then
		item:RemoveTag("INLIMBO")
		item:ReturnToScene()

		if item.Physics ~= nil then
			item.Physics:SetActive(true)
		end
	else
		item:RemoveFromScene()
		item.Transform:SetPosition(0, 0, 0)
	end
end

local function unbindDisplaySlot(inst, slot, leaving)
	local item = inst._aipLanternStandDisplayItems ~= nil and
		inst._aipLanternStandDisplayItems[slot] or nil

	unbindDisplayItem(inst, item, leaving)
end

local function bindDisplayItem(inst, item, slot, showTassle, syncPercent, syncLength)
	if item == nil or not item:IsValid() then
		unbindDisplaySlot(inst, slot, false)
		return false
	end

	local oldSlot = getDisplaySlotForItem(inst, item)
	if oldSlot ~= nil and oldSlot ~= slot then
		unbindDisplaySlot(inst, oldSlot, false)
	end

	local oldItem = inst._aipLanternStandDisplayItems[slot]
	if oldItem ~= item then
		unbindDisplaySlot(inst, slot, false)
	end
	local alreadyBound = item._aipLanternStand == inst

	if item.Follower == nil then
		item.entity:AddFollower()
	end

	if item._aipLanternStandScale == nil then
		item._aipLanternStandScale = { item.Transform:GetScale() }
	end

	-- 容器会把物品放进 limbo；展示时临时拉回场景并绑定到架子的挂点。
	item:ForceOutOfLimbo(false)
	item:ForceOutOfLimbo(true)
	item:ReturnToScene()
	exposeDisplayItem(item)
	item.Transform:SetPosition(inst.Transform:GetWorldPosition())
	item.Transform:SetScale(DISPLAY_SCALE, DISPLAY_SCALE, DISPLAY_SCALE)

	if item.SetLanternStandDisplay ~= nil then
		item:SetLanternStandDisplay(isLanternLit(item), showTassle, syncPercent, syncLength)
	end

	if item.AnimState ~= nil then
		item.AnimState:SetFinalOffset(getDisplayFinalOffset(slot))
	end

	item.Follower:FollowSymbol(
		inst.GUID,
		getDisplaySymbol(slot),
		0,
		0,
		getDisplayZOffset(slot)
	)
	item:AddTag("INLIMBO")
	item:AddTag("NOCLICK")

	if item.Physics ~= nil then
		item.Physics:SetActive(false)
	end

	item._aipLanternStand = inst
	item._aipLanternStandDisplaySlot = slot
	inst._aipLanternStandDisplayItems[slot] = item

	if not alreadyBound then
		inst:ListenForEvent("percentusedchange", onDisplayLanternFuelChanged, item)
	end

	return true
end

local function releaseDisplayItems(inst, leaving)
	if inst._aipLanternStandDisplayItems == nil then
		return
	end

	for slot = 1, SLOT_COUNT do
		unbindDisplaySlot(inst, slot, leaving)
	end
end

local function refreshLanternDisplays(inst)
	if inst.components.container == nil then
		return
	end

	local displaySlot = 1
	local lightCount = 0
	local displayItems = {}
	local syncPercent, syncLength = getDisplayAnimSync(inst)

	-- 容器可能有空槽，展示时按实际存在的灯笼重新压紧顺序。
	for slot = 1, SLOT_COUNT do
		local item = inst.components.container:GetItemInSlot(slot)

		if item ~= nil then
			table.insert(displayItems, item)
		end
	end

	for _, item in ipairs(displayItems) do
		if bindDisplayItem(
			inst,
			item,
			displaySlot,
			displaySlot == #displayItems,
			syncPercent,
			syncLength
		) then
			if isLanternLit(item) then
				lightCount = lightCount + 1
			end
		end

		displaySlot = displaySlot + 1
	end

	for slot = displaySlot, SLOT_COUNT do
		unbindDisplaySlot(inst, slot, false)
	end

	setLightCount(inst, lightCount)
end

queueRefreshLanternDisplays = function(inst)
	if inst._aipLanternStandRefreshTask == nil then
		-- itemget/itemlose 常常连着触发，延后一帧统一刷新挂灯和光照。
		inst._aipLanternStandRefreshTask = inst:DoTaskInTime(0, function(inst)
			inst._aipLanternStandRefreshTask = nil
			refreshLanternDisplays(inst)
		end)
	end
end

local function onhammered(inst)
	if inst.components.container ~= nil then
		inst.components.container:DropEverything()
	end

	inst.components.lootdropper:DropLoot()

	local fx = SpawnPrefab("collapse_small")
	fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
	fx:SetMaterial("wood")

	inst:Remove()
end

local function onhit(inst)
	skinner.PlayCurrent(inst, true)

	if inst._aipLanternStandHitSyncTask ~= nil then
		inst._aipLanternStandHitSyncTask:Cancel()
	end

	-- hit 动画结束后架子会重新进入 idle，需要把真实灯笼同步到新的摇摆帧。
	local hitLength = inst.AnimState:GetCurrentAnimationLength() or 0
	inst._aipLanternStandHitSyncTask = inst:DoTaskInTime(
		hitLength,
		function(inst)
			inst._aipLanternStandHitSyncTask = nil
			queueRefreshLanternDisplays(inst)
		end
	)
end

local function onbuilt(inst)
	skinner.PlayCurrent(inst)

	if inst.SoundEmitter ~= nil then
		inst.SoundEmitter:PlaySound("dontstarve/common/place_structure_wood")
	end
end

local function onload(inst, data)
	skinner.OnLoad(inst, data)
	queueRefreshLanternDisplays(inst)
end

local function onloadpostpass(inst)
	queueRefreshLanternDisplays(inst)
end

local function onitemget(inst)
	queueRefreshLanternDisplays(inst)
end

local function onitemlose(inst, data)
	if data ~= nil and data.prev_item ~= nil then
		unbindDisplayItem(inst, data.prev_item, true)
	end

	queueRefreshLanternDisplays(inst)
end

local function onremoveentity(inst)
	releaseDisplayItems(inst, false)
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddLight()
	inst.entity:AddNetwork()

	inst:AddTag("structure")
	inst:AddTag("chest")
	inst:AddTag("aip_lantern_stand")

	MakeObstaclePhysics(inst, .2)

	inst.AnimState:SetBank(BUILD)
	inst.AnimState:SetBuild(BUILD)

	setLightCount(inst, 0)
	skinner.SetupNetwork(inst)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	skinner.SetupMaster(inst)
	inst._aipLanternStandDisplayItems = {}

	inst:AddComponent("inspectable")

	inst:AddComponent("container")
	inst.components.container:WidgetSetup(PREFAB)

	inst:AddComponent("lootdropper")
	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
	inst.components.workable:SetWorkLeft(2)
	inst.components.workable:SetOnFinishCallback(onhammered)
	inst.components.workable:SetOnWorkCallback(onhit)

	inst.OnSave = skinner.OnSave
	inst.OnLoad = onload
	inst.OnLoadPostPass = onloadpostpass
	inst.OnRemoveEntity = onremoveentity

	inst:ListenForEvent("onbuilt", onbuilt)
	inst:ListenForEvent("itemget", onitemget)
	inst:ListenForEvent("itemlose", onitemlose)

	MakeHauntableWork(inst)

	return inst
end

local prefabs = {
	Prefab(PREFAB, fn, assets, { "collapse_small" }),
	MakePlacer("aip_lantern_stand_placer", BUILD, BUILD, DEFAULT_SKIN),
}

for _, skinPrefab in ipairs(skinner.CreatePrefabSkins()) do
	table.insert(prefabs, skinPrefab)
end

return unpack(prefabs)
