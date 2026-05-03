local language = aipGetModConfig("language")

require "prefabutil"

local skinUtil = require("utils/aip_skin_util")
local clockConfig = require("configurations/skin/aip_grandfather_clock")

local LANG_MAP = {
	english = {
		NAME = "Grandfather Clock",
		REC_DESC = "A stately clock for decoration",
		DESC = "It keeps time with a patient little tick.",
	},
	chinese = {
		NAME = "座钟",
		REC_DESC = "一座稳重的装饰座钟。",
		DESC = "它耐心地滴答着。",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_GRANDFATHER_CLOCK = LANG.NAME
STRINGS.RECIPE_DESC.AIP_GRANDFATHER_CLOCK = LANG.REC_DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_GRANDFATHER_CLOCK = LANG.DESC
skinUtil.RegisterBuildSkinConfig(clockConfig, language, LANG.DESC)

local assets = {
	Asset("ANIM", "anim/aip_grandfather_clock.zip"),
	Asset("ANIM", "anim/aip_grandfather_clock_hand.zip"),
}

for _, asset in ipairs(clockConfig.GetInventoryAtlasAssets(true)) do
	table.insert(assets, asset)
end

local DEFAULT_SKIN = clockConfig.DEFAULT_SKIN
local HAND_PREFAB = "aip_grandfather_clock_hand"
local HAND_SYMBOL = "clock_hand_root"
local HAND_ANIM = "idle"
local HOUR_HAND_SCALE = 0.72
local MINUTE_HAND_SCALE = 1
local HOUR_HAND_Z_OFFSET = 0.2
local MINUTE_HAND_Z_OFFSET = 0.3

local function playSkin(inst, skin, hit)
	skin = clockConfig.GetSkin(skin)

	if hit then
		inst.AnimState:PlayAnimation(skin.."_hit")
		inst.AnimState:PushAnimation(skin, true)
	else
		inst.AnimState:PlayAnimation(skin, true)
	end
end

local function setHandTime(inst)
	local time = TheWorld.state.time or 0
	local hours = time * 24

	if inst._aipHourHand ~= nil and inst._aipHourHand:IsValid() then
		inst._aipHourHand.AnimState:SetPercent(HAND_ANIM, (hours % 12) / 12)
	end

	if inst._aipMinuteHand ~= nil and inst._aipMinuteHand:IsValid() then
		inst._aipMinuteHand.AnimState:SetPercent(HAND_ANIM, hours % 1)
	end
end

local function createHand(inst, scale, zOffset, finalOffset)
	local hand = SpawnPrefab(HAND_PREFAB)
	if hand == nil then
		return nil
	end

	hand.entity:SetParent(inst.entity)
	hand.entity:AddFollower()
	hand.Follower:FollowSymbol(inst.GUID, HAND_SYMBOL, 0, 0, zOffset, true)
	hand.Transform:SetScale(scale, scale, scale)
	hand.AnimState:SetFinalOffset(finalOffset)

	hand:AddTag("NOCLICK")

	return hand
end

local function clearHands(inst)
	inst:StopWatchingWorldState("time", setHandTime)

	if inst._aipHourHand ~= nil and inst._aipHourHand:IsValid() then
		inst._aipHourHand:Remove()
	end

	if inst._aipMinuteHand ~= nil and inst._aipMinuteHand:IsValid() then
		inst._aipMinuteHand:Remove()
	end

	inst._aipHourHand = nil
	inst._aipMinuteHand = nil
end

local function setupHands(inst)
	if TheNet:IsDedicated() then
		return
	end

	inst.highlightchildren = inst.highlightchildren or {}
	inst._aipHourHand = createHand(inst, HOUR_HAND_SCALE, HOUR_HAND_Z_OFFSET, 1)
	inst._aipMinuteHand = createHand(inst, MINUTE_HAND_SCALE, MINUTE_HAND_Z_OFFSET, 2)

	if inst._aipHourHand ~= nil then
		table.insert(inst.highlightchildren, inst._aipHourHand)
	end
	if inst._aipMinuteHand ~= nil then
		table.insert(inst.highlightchildren, inst._aipMinuteHand)
	end

	inst:WatchWorldState("time", setHandTime)
	inst:ListenForEvent("onremove", clearHands)
	setHandTime(inst)
end

local skinner = skinUtil.CreatePrefabSkinner(clockConfig, {
	net_field = "_aipGrandfatherClockSkin",
	current_field = "_aipCurrentSkin",
	dirty_event = "aip_grandfather_clock_skindirty",
	set_fn_name = "SetClockSkin",
	next_fn_name = "NextClockSkin",
	play_fn = playSkin,
})

local function onhammered(inst)
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
end

local function handFn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()

	inst.AnimState:SetBank("aip_grandfather_clock_hand")
	inst.AnimState:SetBuild("aip_grandfather_clock_hand")
	inst.AnimState:PlayAnimation(HAND_ANIM)
	inst.AnimState:Pause()

	inst:AddTag("NOCLICK")
	inst:AddTag("DECOR")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst.persists = false

	return inst
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	inst:AddTag("structure")

	MakeObstaclePhysics(inst, .25)

	inst.AnimState:SetBank("aip_grandfather_clock")
	inst.AnimState:SetBuild("aip_grandfather_clock")

	skinner.SetupNetwork(inst)

	inst.entity:SetPristine()
	inst:DoTaskInTime(0, setupHands)

	if not TheWorld.ismastersim then
		return inst
	end

	skinner.SetupMaster(inst)

	inst:AddComponent("inspectable")

	inst:AddComponent("lootdropper")
	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
	inst.components.workable:SetWorkLeft(2)
	inst.components.workable:SetOnFinishCallback(onhammered)
	inst.components.workable:SetOnWorkCallback(onhit)

	inst.OnSave = skinner.OnSave
	inst.OnLoad = onload

	inst:ListenForEvent("onbuilt", onbuilt)

	MakeHauntableWork(inst)

	return inst
end

local prefabs = {
	Prefab("aip_grandfather_clock", fn, assets, { "collapse_small", HAND_PREFAB }),
	Prefab(HAND_PREFAB, handFn, { Asset("ANIM", "anim/aip_grandfather_clock_hand.zip") }),
	MakePlacer("aip_grandfather_clock_placer", "aip_grandfather_clock", "aip_grandfather_clock", DEFAULT_SKIN),
}

for _, skinPrefab in ipairs(skinner.CreatePrefabSkins()) do
	table.insert(prefabs, skinPrefab)
end

return unpack(prefabs)
