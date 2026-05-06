local language = aipGetModConfig("language")

require "prefabutil"

local skinUtil = require("utils/aip_skin_util")
local standConfig = require("configurations/skin/aip_lantern_stand")
local lanternConfig = require("configurations/skin/aip_lantern")

local PREFAB = "aip_lantern_stand"
local BUILD = "aip_lantern_stand"
local SLOT_COUNT = 3
local DISPLAY_DIRTY_PREFIX = "aip_lantern_stand_display_dirty_"
local LIGHT_COLOUR = Vector3(200 / 255, 100 / 255, 100 / 255)
local DISPLAY_BODY_PREFIX = "lantern_body_"
local DISPLAY_TASSLE_PREFIX = "lantern_tassle_"
local DISPLAY_LIGHT_PREFIX = "lantern_light_"
local DISPLAY_LIGHT_SOURCE = "lantern_light_source"

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
local refreshDisplaySymbols

local function playSkin(inst, skin, hit)
	skin = standConfig.GetSkin(skin)

	if hit then
		inst.AnimState:PlayAnimation(skin.."_hit")
		inst.AnimState:PushAnimation(skin, true)
	else
		inst.AnimState:PlayAnimation(skin, true)
	end

	if refreshDisplaySymbols ~= nil then
		refreshDisplaySymbols(inst)
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

local function parseLanternDisplay(value)
	if value == nil or value == "" then
		return nil, false
	end

	local skin, lit = string.match(value, "^([^|]+)|(%d)$")
	return skin, lit == "1"
end

local function packLanternDisplay(skin, lit)
	return skin ~= nil and skin ~= "" and skin.."|"..(lit and "1" or "0") or ""
end

local function getLanternSkin(item)
	if item == nil then
		return nil
	end

	if item._aipCurrentSkin ~= nil then
		return lanternConfig.GetSkin(item._aipCurrentSkin)
	end

	if item.skinname ~= nil then
		return lanternConfig.GetSkin(item.skinname)
	end

	if lanternConfig.SKIN_ID_BY_PREFAB[item.prefab] ~= nil then
		return lanternConfig.GetSkin(item.prefab)
	end

	return lanternConfig.DEFAULT_SKIN
end

local function isLanternLit(item)
	return item ~= nil
		and item.components.fueled ~= nil
		and not item.components.fueled:IsEmpty()
end

-- 挂灯直接复用灯笼架自己的动画符号，避免客户端创建额外跟随 FX 导致渲染层崩溃。
local function clearDisplaySlotSymbols(inst, slot)
	local bodySymbol = DISPLAY_BODY_PREFIX..slot
	local tassleSymbol = DISPLAY_TASSLE_PREFIX..slot
	local lightSymbol = DISPLAY_LIGHT_PREFIX..slot

	inst.AnimState:HideSymbol(bodySymbol)
	inst.AnimState:HideSymbol(tassleSymbol)
	inst.AnimState:HideSymbol(lightSymbol)
	inst.AnimState:ClearOverrideSymbol(bodySymbol)
	inst.AnimState:ClearOverrideSymbol(tassleSymbol)
	inst.AnimState:ClearOverrideSymbol(lightSymbol)
end

local function applyDisplaySlotSymbols(inst, slot)
	if TheNet:IsDedicated() or inst._aipLanternStandDisplays == nil then
		return
	end

	local skin, lit = parseLanternDisplay(inst._aipLanternStandDisplays[slot]:value())

	clearDisplaySlotSymbols(inst, slot)

	if skin == nil then
		return
	end

	skin = lanternConfig.GetSkin(skin)

	local bodySymbol = DISPLAY_BODY_PREFIX..slot
	local tassleSymbol = DISPLAY_TASSLE_PREFIX..slot

	inst.AnimState:OverrideSymbol(bodySymbol, BUILD, DISPLAY_BODY_PREFIX..skin)
	inst.AnimState:OverrideSymbol(tassleSymbol, BUILD, DISPLAY_TASSLE_PREFIX..skin)
	inst.AnimState:ShowSymbol(bodySymbol)
	inst.AnimState:ShowSymbol(tassleSymbol)

	if lit then
		local lightSymbol = DISPLAY_LIGHT_PREFIX..slot

		inst.AnimState:OverrideSymbol(lightSymbol, BUILD, DISPLAY_LIGHT_SOURCE)
		inst.AnimState:ShowSymbol(lightSymbol)
	end
end

refreshDisplaySymbols = function(inst)
	for slot = 1, SLOT_COUNT do
		applyDisplaySlotSymbols(inst, slot)
	end
end

local function hideDisplaySymbols(inst)
	for slot = 1, SLOT_COUNT do
		clearDisplaySlotSymbols(inst, slot)
	end
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

local function setDisplaySlot(inst, slot, value)
	inst._aipLanternStandDisplays[slot]:set(value or "")

	if not TheNet:IsDedicated() then
		applyDisplaySlotSymbols(inst, slot)
	end
end

local function refreshLanternDisplays(inst)
	if inst.components.container == nil then
		return
	end

	local displaySlot = 1
	local lightCount = 0

	-- 容器可能有空槽，展示时按实际存在的灯笼重新压紧顺序。
	for slot = 1, SLOT_COUNT do
		local item = inst.components.container:GetItemInSlot(slot)

		if item ~= nil then
			local lit = isLanternLit(item)
			setDisplaySlot(inst, displaySlot, packLanternDisplay(getLanternSkin(item), lit))
			displaySlot = displaySlot + 1

			if lit then
				lightCount = lightCount + 1
			end
		end
	end

	for slot = displaySlot, SLOT_COUNT do
		setDisplaySlot(inst, slot, "")
	end

	setLightCount(inst, lightCount)
end

local function queueRefreshLanternDisplays(inst)
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

local OnDisplayDirty = {}
for slot = 1, SLOT_COUNT do
	OnDisplayDirty[slot] = function(inst)
		applyDisplaySlotSymbols(inst, slot)
	end
end

local function setupDisplayNetVars(inst)
	inst._aipLanternStandDisplays = {}

	for slot = 1, SLOT_COUNT do
		local event = DISPLAY_DIRTY_PREFIX..slot
		inst._aipLanternStandDisplays[slot] = net_string(inst.GUID, "aip_lantern_stand.display_"..slot, event)
		inst:ListenForEvent(event, OnDisplayDirty[slot])
	end
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
	hideDisplaySymbols(inst)

	setLightCount(inst, 0)
	setupDisplayNetVars(inst)
	skinner.SetupNetwork(inst)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	skinner.SetupMaster(inst)

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

	inst:ListenForEvent("onbuilt", onbuilt)
	inst:ListenForEvent("itemget", queueRefreshLanternDisplays)
	inst:ListenForEvent("itemlose", queueRefreshLanternDisplays)

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
