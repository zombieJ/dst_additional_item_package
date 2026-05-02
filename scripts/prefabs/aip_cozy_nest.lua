local language = aipGetModConfig("language")

require "prefabutil"

local skinUtil = require("utils/aip_skin_util")
local cozyNestConfig = require("configurations/skin/aip_cozy_nest")

local LANG_MAP = {
	english = {
		NAME = "Cozy Nest",
		REC_DESC = "A soft little nest for decoration",
		DESC = "It looks wonderfully soft.",
	},
	chinese = {
		NAME = "温馨小窝",
		REC_DESC = "一个柔软温馨的小窝，用作装饰",
		DESC = "看起来软乎乎的。",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_COZY_NEST = LANG.NAME
STRINGS.RECIPE_DESC.AIP_COZY_NEST = LANG.REC_DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_COZY_NEST = LANG.DESC
skinUtil.RegisterBuildSkinConfig(cozyNestConfig, language, LANG.DESC)

local assets = {
	Asset("ANIM", "anim/aip_cozy_nest.zip"),
	Asset("ATLAS_BUILD", "images/inventoryimages1.xml", 256),
	Asset("ATLAS_BUILD", "images/inventoryimages2.xml", 256),
	Asset("ATLAS_BUILD", "images/inventoryimages3.xml", 256),
	Asset("ATLAS_BUILD", "images/inventoryimages4.xml", 256),
}

for _, asset in ipairs(cozyNestConfig.GetInventoryAtlasAssets(true)) do
	table.insert(assets, asset)
end

local DEFAULT_SKIN = cozyNestConfig.DEFAULT_SKIN
local GUEST_ANIM_SUFFIX = "_guest"
local applyDisplayImage
local hasSleepingGuest

local function playSkin(inst, skin, hit)
	skin = cozyNestConfig.GetSkin(skin)
	local idleAnim = hasSleepingGuest ~= nil and hasSleepingGuest(inst) and skin..GUEST_ANIM_SUFFIX or skin

	if hit and idleAnim == skin then
		inst.AnimState:PlayAnimation(skin.."_hit")
		inst.AnimState:PushAnimation(idleAnim, true)
	else
		inst.AnimState:PlayAnimation(idleAnim, true)
	end

	if applyDisplayImage ~= nil and inst._aipDisplayImage ~= nil then
		applyDisplayImage(inst)
	end
end

local skinner = skinUtil.CreatePrefabSkinner(cozyNestConfig, {
	net_field = "_aipCozyNestSkin",
	current_field = "_aipCurrentSkin",
	dirty_event = "aip_cozy_nest_skindirty",
	set_fn_name = "SetNestSkin",
	next_fn_name = "NextNestSkin",
	play_fn = playSkin,
})

local DISPLAY_DIRTY = "aip_cozy_nest_display_dirty"
local DISPLAY_SYMBOL = "swap_item"
local GUEST_DIRTY = "aip_cozy_nest_guest_dirty"
local SPECIAL_GUESTS = {
	chester_eyebone = {
		prefab = "chester",
		x = 0,
		z = .35,
		face_x = 1,
		face_z = .35,
	},
	glommerflower = {
		prefab = "glommer",
		x = 0,
		z = .25,
		face_x = 1,
		face_z = .25,
	},
}

local function getStoredItem(inst)
	return inst.components.container ~= nil and inst.components.container:GetItemInSlot(1) or nil
end

local function getItemImage(item)
	if item == nil or item.components.inventoryitem == nil then
		return nil, nil
	end

	return item.components.inventoryitem.imagename or item.prefab, item.components.inventoryitem.atlasname
end

local function normalizeTex(image)
	return string.sub(image, -4) == ".tex" and image or image..".tex"
end

hasSleepingGuest = function(inst)
	return inst._aipCozyNestHasGuest ~= nil and inst._aipCozyNestHasGuest:value()
end

applyDisplayImage = function(inst)
	local image = inst._aipDisplayImage:value()
	if image == "" or hasSleepingGuest(inst) then
		inst.AnimState:ClearOverrideSymbol(DISPLAY_SYMBOL)
		inst.AnimState:HideSymbol(DISPLAY_SYMBOL)
		return
	end

	local tex = normalizeTex(image)
	local atlas = inst._aipDisplayAtlas:value()
	atlas = atlas ~= "" and atlas or GetInventoryItemAtlas(tex)

	if atlas ~= nil then
		inst.AnimState:OverrideSymbol(DISPLAY_SYMBOL, atlas, tex)
		inst.AnimState:ShowSymbol(DISPLAY_SYMBOL)
	else
		inst.AnimState:ClearOverrideSymbol(DISPLAY_SYMBOL)
		inst.AnimState:HideSymbol(DISPLAY_SYMBOL)
	end
end

local function setDisplayImage(inst, image, atlas)
	inst._aipDisplayAtlas:set(atlas or "")
	inst._aipDisplayImage:set(image or "")
	applyDisplayImage(inst)
end

local function clearDisplay(inst)
	inst._aipDisplayItemImage = nil
	inst._aipDisplayItemAtlas = nil
	setDisplayImage(inst)
end

local function syncDisplay(inst)
	local item = getStoredItem(inst)
	local image, atlas = getItemImage(item)

	if image == nil then
		clearDisplay(inst)
		return
	end

	if image ~= inst._aipDisplayItemImage or atlas ~= inst._aipDisplayItemAtlas then
		inst._aipDisplayItemImage = image
		inst._aipDisplayItemAtlas = atlas
		setDisplayImage(inst, image, atlas)
	end
end

local function refreshGuestVisual(inst)
	skinner.PlayCurrent(inst)
	applyDisplayImage(inst)
end

local function setSleepingGuestVisual(inst, enabled)
	if inst._aipCozyNestHasGuest ~= nil then
		inst._aipCozyNestHasGuest:set(enabled == true)
	end

	refreshGuestVisual(inst)
end

local function releaseSpecialGuest(inst)
	local follower = inst._aipCozyNestGuest
	setSleepingGuestVisual(inst, false)

	if follower ~= nil then
		inst._aipCozyNestGuest = nil

		if follower:IsValid() and follower._aipCozyNest == inst then
			follower._aipCozyNest = nil

			if follower.components.sleeper ~= nil and follower.components.sleeper:IsAsleep() then
				follower.components.sleeper:WakeUp()
			end
		end
	end
end

local function getGuestPoint(inst, config)
	local x, y, z = inst.Transform:GetWorldPosition()
	return x + (config.x or 0), y, z + (config.z or 0)
end

local function setSpecialGuestPose(inst, follower, config)
	if follower._aipCozyNest ~= inst then
		if follower._aipCozyNest ~= nil and follower._aipCozyNest:IsValid() then
			releaseSpecialGuest(follower._aipCozyNest)
		end

		releaseSpecialGuest(inst)
		inst._aipCozyNestGuest = follower
		follower._aipCozyNest = inst
	end

	local x, y, z = getGuestPoint(inst, config)
	if follower.Physics ~= nil then
		follower.Physics:Teleport(x, y, z)
	else
		follower.Transform:SetPosition(x, y, z)
	end

	if config.face_x ~= nil or config.face_z ~= nil then
		follower:FacePoint(x + (config.face_x or 0), y, z + (config.face_z or 0))
	end
end

local function syncSpecialGuest(inst)
	local item = getStoredItem(inst)
	local guestConfig = item ~= nil and SPECIAL_GUESTS[item.prefab] or nil

	if guestConfig == nil or item.components.leader == nil then
		releaseSpecialGuest(inst)
		return
	elseif item.prefab == "glommerflower" and not item:HasTag("glommerflower") then
		releaseSpecialGuest(inst)
		return
	end

	for follower in pairs(item.components.leader.followers) do
		if follower:IsValid() and follower.prefab == guestConfig.prefab then
			local x, y, z = getGuestPoint(inst, guestConfig)

			if follower.components.knownlocations ~= nil then
				follower.components.knownlocations:RememberLocation("home", Point(x, y, z))
			end

			if follower.components.sleeper ~= nil then
				if follower:IsNear(inst, 2.5) then
					setSpecialGuestPose(inst, follower, guestConfig)
					follower.components.sleeper:GoToSleep()
					setSleepingGuestVisual(inst, follower.components.sleeper:IsAsleep())
				else
					releaseSpecialGuest(inst)

					if follower.components.sleeper:IsAsleep() then
						follower.components.sleeper:WakeUp()
					end

					if follower.components.locomotor ~= nil and
						(follower.components.combat == nil or follower.components.combat.target == nil)
					then
						follower.components.locomotor:GoToPoint(Point(x, y, z), nil, true)
					end
				end
			end

			return
		end
	end

	releaseSpecialGuest(inst)
end

local refreshNest

local function stopRefreshTask(inst)
	if inst._aipCozyNestRefreshTask ~= nil then
		inst._aipCozyNestRefreshTask:Cancel()
		inst._aipCozyNestRefreshTask = nil
	end
end

local function startRefreshTask(inst)
	if inst._aipCozyNestRefreshTask == nil then
		inst._aipCozyNestRefreshTask = inst:DoPeriodicTask(2, refreshNest, 0)
	end
end

refreshNest = function(inst)
	syncDisplay(inst)
	syncSpecialGuest(inst)

	if getStoredItem(inst) == nil then
		stopRefreshTask(inst)
	end
end

local function onhammered(inst)
	inst.components.lootdropper:DropLoot()
	clearDisplay(inst)
	releaseSpecialGuest(inst)

	if inst.components.container ~= nil then
		inst.components.container:DropEverything()
	end

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
	startRefreshTask(inst)
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	inst:AddTag("structure")
	inst:AddTag("chest")

	inst.AnimState:SetBank("aip_cozy_nest")
	inst.AnimState:SetBuild("aip_cozy_nest")
	inst.AnimState:HideSymbol(DISPLAY_SYMBOL)

	skinner.SetupNetwork(inst)

	inst._aipDisplayImage = net_string(inst.GUID, "aip_cozy_nest.display_image", DISPLAY_DIRTY)
	inst._aipDisplayAtlas = net_string(inst.GUID, "aip_cozy_nest.display_atlas", DISPLAY_DIRTY)
	inst._aipCozyNestHasGuest = net_bool(inst.GUID, "aip_cozy_nest.has_guest", GUEST_DIRTY)
	inst:ListenForEvent(DISPLAY_DIRTY, applyDisplayImage)
	inst:ListenForEvent(GUEST_DIRTY, refreshGuestVisual)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	skinner.SetupMaster(inst)

	inst:AddComponent("inspectable")

	inst:AddComponent("container")
	inst.components.container:WidgetSetup("aip_cozy_nest")

	inst:AddComponent("lootdropper")
	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
	inst.components.workable:SetWorkLeft(2)
	inst.components.workable:SetOnFinishCallback(onhammered)
	inst.components.workable:SetOnWorkCallback(onhit)

	inst.OnSave = skinner.OnSave
	inst.OnLoad = onload

	inst:ListenForEvent("onbuilt", onbuilt)
	inst:ListenForEvent("itemget", startRefreshTask)
	inst:ListenForEvent("itemlose", startRefreshTask)

	MakeHauntableWork(inst)

	return inst
end

local prefabs = {
	Prefab("aip_cozy_nest", fn, assets),
	MakePlacer("aip_cozy_nest_placer", "aip_cozy_nest", "aip_cozy_nest", DEFAULT_SKIN),
}

for _, skinPrefab in ipairs(skinner.CreatePrefabSkins()) do
	table.insert(prefabs, skinPrefab)
end

return unpack(prefabs)
