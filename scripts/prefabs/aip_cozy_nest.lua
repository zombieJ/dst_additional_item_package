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
	Asset("ANIM", "anim/aip_showcase.zip"),
	Asset("ATLAS_BUILD", "images/inventoryimages1.xml", 256),
	Asset("ATLAS_BUILD", "images/inventoryimages2.xml", 256),
	Asset("ATLAS_BUILD", "images/inventoryimages3.xml", 256),
	Asset("ATLAS_BUILD", "images/inventoryimages4.xml", 256),
}

for _, asset in ipairs(cozyNestConfig.GetInventoryAtlasAssets(true)) do
	table.insert(assets, asset)
end

local DEFAULT_SKIN = cozyNestConfig.DEFAULT_SKIN

local function playSkin(inst, skin, hit)
	skin = cozyNestConfig.GetSkin(skin)

	if hit then
		inst.AnimState:PlayAnimation(skin.."_hit")
		inst.AnimState:PushAnimation(skin, true)
	else
		inst.AnimState:PlayAnimation(skin, true)
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
local SPECIAL_GUESTS = {
	chester_eyebone = "chester",
	glommerflower = "glommer",
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

local function applyDisplayImage(inst)
	local image = inst._aipDisplayImage:value()
	if image == "" then
		inst.AnimState:HideSymbol("swap_item")
		return
	end

	local tex = normalizeTex(image)
	local atlas = inst._aipDisplayAtlas:value()
	atlas = atlas ~= "" and atlas or GetInventoryItemAtlas(tex)

	if atlas ~= nil then
		inst.AnimState:ShowSymbol("swap_item")
		inst.AnimState:OverrideSymbol("swap_item", atlas, tex)
	else
		inst.AnimState:HideSymbol("swap_item")
	end
end

local function setDisplayImage(inst, image, atlas)
	inst._aipDisplayAtlas:set(atlas or "")
	inst._aipDisplayImage:set(image or "")
	applyDisplayImage(inst)
end

local function clearDisplay(inst)
	if inst._aipCozyNestDisplay ~= nil then
		if inst._aipCozyNestDisplay:IsValid() then
			inst._aipCozyNestDisplay:Remove()
		end
		inst._aipCozyNestDisplay = nil
	end

	inst._aipDisplayItemImage = nil
	inst._aipDisplayItemAtlas = nil
end

local function syncDisplay(inst)
	local item = getStoredItem(inst)
	local image, atlas = getItemImage(item)

	if image == nil then
		clearDisplay(inst)
		return
	end

	if inst._aipCozyNestDisplay == nil or not inst._aipCozyNestDisplay:IsValid() then
		inst._aipCozyNestDisplay = SpawnPrefab("aip_cozy_nest_display")
		inst._aipCozyNestDisplay.entity:SetParent(inst.entity)
		inst._aipCozyNestDisplay.Transform:SetPosition(0, 0, 0)
	end

	if image ~= inst._aipDisplayItemImage or atlas ~= inst._aipDisplayItemAtlas then
		inst._aipDisplayItemImage = image
		inst._aipDisplayItemAtlas = atlas
		inst._aipCozyNestDisplay:SetItemImage(image, atlas)
	end
end

local function syncSpecialGuest(inst)
	local item = getStoredItem(inst)
	local guestPrefab = item ~= nil and SPECIAL_GUESTS[item.prefab] or nil

	if guestPrefab == nil or item.components.leader == nil then
		return
	elseif item.prefab == "glommerflower" and not item:HasTag("glommerflower") then
		return
	end

	for follower in pairs(item.components.leader.followers) do
		if follower:IsValid() and follower.prefab == guestPrefab then
			if follower.components.knownlocations ~= nil then
				follower.components.knownlocations:RememberLocation("home", inst:GetPosition())
			end

			if follower.components.sleeper ~= nil then
				if follower:IsNear(inst, 2.5) then
					follower.components.sleeper:GoToSleep()
				else
					if follower.components.sleeper:IsAsleep() then
						follower.components.sleeper:WakeUp()
					end

					if follower.components.locomotor ~= nil and
						(follower.components.combat == nil or follower.components.combat.target == nil)
					then
						follower.components.locomotor:GoToPoint(inst:GetPosition(), nil, true)
					end
				end
			end
		end
	end
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

local function displayFn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	inst:AddTag("FX")
	inst:AddTag("NOCLICK")
	inst:AddTag("CLASSIFIED")

	inst.Transform:SetScale(.35, .35, .35)
	inst.AnimState:SetBank("aip_showcase")
	inst.AnimState:SetBuild("aip_showcase")
	inst.AnimState:PlayAnimation("stone")
	inst.AnimState:HideSymbol("stone")
	inst.AnimState:HideSymbol("swap_item")
	inst.AnimState:SetFinalOffset(1)

	inst._aipDisplayImage = net_string(inst.GUID, "aip_cozy_nest_display.image", DISPLAY_DIRTY)
	inst._aipDisplayAtlas = net_string(inst.GUID, "aip_cozy_nest_display.atlas", DISPLAY_DIRTY)
	inst:ListenForEvent(DISPLAY_DIRTY, applyDisplayImage)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst.persists = false
	inst.SetItemImage = setDisplayImage

	return inst
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	MakeObstaclePhysics(inst, .45)

	inst:AddTag("structure")
	inst:AddTag("chest")

	inst.AnimState:SetBank("aip_cozy_nest")
	inst.AnimState:SetBuild("aip_cozy_nest")

	skinner.SetupNetwork(inst)

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
	inst:ListenForEvent("onremove", clearDisplay)

	MakeHauntableWork(inst)

	return inst
end

local prefabs = {
	Prefab("aip_cozy_nest", fn, assets),
	Prefab("aip_cozy_nest_display", displayFn, assets),
	MakePlacer("aip_cozy_nest_placer", "aip_cozy_nest", "aip_cozy_nest", DEFAULT_SKIN),
}

for _, skinPrefab in ipairs(skinner.CreatePrefabSkins()) do
	table.insert(prefabs, skinPrefab)
end

return unpack(prefabs)
