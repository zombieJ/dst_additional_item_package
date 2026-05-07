local language = aipGetModConfig("language")

local skinUtil = require("utils/aip_skin_util")
local lanternConfig = require("configurations/skin/aip_lantern")

local PREFAB = "aip_lantern"
local BUILD = "aip_lantern"
local LIGHT_PREFAB = "aip_lantern_light"
local BODY_PREFAB = "aip_lantern_body"
local SWAP_BUILD = "swap_redlantern"
local SWAP_FULL_SYMBOL = "swap_redlantern"
local SWAP_STICK_SYMBOL = "swap_redlantern_stick"
local BODY_SKIN_DIRTY = "aip_lantern_body_skindirty"

local LANG_MAP = {
	english = {
		NAME = "Lantern",
		REC_DESC = "A festive lantern for the road",
		DESC = "A warm light dressed in red.",
	},
	chinese = {
		NAME = "灯笼",
		REC_DESC = "一盏适合远行的喜庆灯笼",
		DESC = "暖暖的红光摇晃着。",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_LANTERN = LANG.NAME
STRINGS.RECIPE_DESC.AIP_LANTERN = LANG.REC_DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_LANTERN = LANG.DESC
skinUtil.RegisterBuildSkinConfig(lanternConfig, language, LANG.DESC)

local assets = {
	Asset("ANIM", "anim/aip_lantern.zip"),
	Asset("ANIM", "anim/swap_redlantern.zip"),
}

for _, asset in ipairs(lanternConfig.GetInventoryAtlasAssets(true)) do
	table.insert(assets, asset)
end

local prefabs = {
	LIGHT_PREFAB,
	BODY_PREFAB,
}

local LIGHT_RADIUS = 1.2
local LIGHT_COLOUR = Vector3(200 / 255, 100 / 255, 100 / 255)
local LIGHT_INTENSITY = .8
local LIGHT_FALLOFF = .5
local ANIM_IDLE_SUFFIX = "_idle_loop"
local ANIM_BODY_SUFFIX = "_idle_body_loop"
local ANIM_FLOAT_SUFFIX = "_float"
local TASSLE_SYMBOL = "Tassle"

local function getSkinAnim(skin, suffix)
	return lanternConfig.GetSkin(skin)..suffix
end

local function setVisualLight(inst, enabled)
	if enabled then
		inst.AnimState:Show("LIGHT")
	else
		inst.AnimState:Hide("LIGHT")
	end

	if inst._body ~= nil then
		if enabled then
			inst._body.AnimState:Show("LIGHT")
		else
			inst._body.AnimState:Hide("LIGHT")
		end
	end
end

local function setDisplayTassle(inst, enabled)
	if enabled then
		inst.AnimState:Show(TASSLE_SYMBOL)
	else
		inst.AnimState:Hide(TASSLE_SYMBOL)
	end
end

local function playDisplaySkin(inst, skin, lit, showTassle)
	inst.AnimState:SetDeltaTimeMultiplier(1)
	inst.AnimState:PlayAnimation(getSkinAnim(skin, ANIM_BODY_SUFFIX), true)
	setDisplayTassle(inst, showTassle == true)
	setVisualLight(inst, lit == true)
end

local function onUpdateFlicker(inst, starttime)
	local time = starttime ~= nil and (GetTime() - starttime) * 15 or 0
	local flicker = (math.sin(time) + math.sin(time + 2) + math.sin(time + 0.7777)) * .5
	flicker = (1 + flicker) * .5

	inst.Light:SetRadius(LIGHT_RADIUS + .1 * flicker)
	flicker = flicker * 2 / 255
	inst.Light:SetColour(LIGHT_COLOUR.x + flicker, LIGHT_COLOUR.y + flicker, LIGHT_COLOUR.z + flicker)
end

local function playBodySkin(inst, skin)
	skin = lanternConfig.GetSkin(skin)
	inst.AnimState:PlayAnimation(getSkinAnim(skin, ANIM_BODY_SUFFIX), true)
end

local function setBodySkin(inst, skin)
	skin = lanternConfig.GetSkin(skin)

	if TheWorld.ismastersim and inst._aipLanternBodySkin ~= nil then
		inst._aipLanternBodySkin:set(skin)
	end

	playBodySkin(inst, skin)
end

local function getSkinImage(skin)
	return lanternConfig.GetSkinPrefab(skin) or PREFAB
end

local function applyInventoryImage(inst, skin)
	if inst.components.inventoryitem ~= nil then
		local image = getSkinImage(skin)
		inst.components.inventoryitem.atlasname = "images/inventoryimages/"..image..".xml"
		inst.components.inventoryitem:ChangeImageName(image)
	end
end

local function playSkin(inst, skin)
	skin = lanternConfig.GetSkin(skin)
	if inst._aipLanternStandDisplay then
		playDisplaySkin(
			inst,
			skin,
			inst._aipLanternStandDisplayLit,
			inst._aipLanternStandDisplayTassle
		)
	else
		inst.AnimState:SetDeltaTimeMultiplier(1)
		inst.AnimState:PlayAnimation(getSkinAnim(skin, ANIM_IDLE_SUFFIX), true)
		setDisplayTassle(inst, true)
	end
	applyInventoryImage(inst, skin)

	if inst._body ~= nil and inst._body:IsValid() and inst._body.SetLanternSkin ~= nil then
		inst._body:SetLanternSkin(skin)
	end
end

local skinner = skinUtil.CreatePrefabSkinner(lanternConfig, {
	net_field = "_aipLanternSkin",
	current_field = "_aipCurrentSkin",
	dirty_event = "aip_lantern_skindirty",
	set_fn_name = "SetLanternSkin",
	next_fn_name = "NextLanternSkin",
	play_fn = playSkin,
})

local function onRemoveLight(light)
	light._lantern._light = nil
end

local function stopTrackingOwner(inst)
	if inst._owner ~= nil then
		inst:RemoveEventCallback("equip", inst._onownerequip, inst._owner)
		inst._owner = nil
	end
end

local function startTrackingOwner(inst, owner)
	if owner ~= inst._owner then
		stopTrackingOwner(inst)

		if owner ~= nil and owner.components.inventory ~= nil then
			inst._owner = owner
			inst:ListenForEvent("equip", inst._onownerequip, owner)
		end
	end
end

local function turnOn(inst)
	if inst.components.fueled:IsEmpty() then
		return
	end

	inst.components.fueled:StartConsuming()

	if inst._light == nil then
		inst._light = SpawnPrefab(LIGHT_PREFAB)
		inst._light._lantern = inst
		inst:ListenForEvent("onremove", onRemoveLight, inst._light)
	end

	inst._light.entity:SetParent((inst.components.inventoryitem.owner or inst._body or inst).entity)

	setVisualLight(inst, true)

	if not (inst._body ~= nil and inst._body.entity:IsVisible())
		and inst.components.equippable:IsEquipped()
		and inst.components.inventoryitem.owner ~= nil then
		inst.components.inventoryitem.owner.AnimState:Hide("LANTERN_OVERLAY")
	end
end

local function turnOff(inst)
	stopTrackingOwner(inst)
	inst.components.fueled:StopConsuming()

	if inst._light ~= nil then
		inst._light:Remove()
	end

	setVisualLight(inst, false)

	if inst.components.equippable:IsEquipped() then
		inst.components.inventoryitem.owner.AnimState:Hide("LANTERN_OVERLAY")
	end
end

local function setLanternStandDisplay(inst, lit, showTassle)
	stopTrackingOwner(inst)

	if inst.components.fueled ~= nil then
		inst.components.fueled:StopConsuming()
	end

	if inst._light ~= nil then
		inst._light:Remove()
	end
	if inst._body ~= nil then
		inst._body:Remove()
	end

	-- 灯笼架展示真实灯笼实体时，只播放无棍灯体动画，由架子负责挂点和整体光照。
	inst._aipLanternStandDisplay = true
	inst._aipLanternStandDisplayLit = lit == true
	inst._aipLanternStandDisplayTassle = showTassle == true
	playDisplaySkin(
		inst,
		inst._aipCurrentSkin,
		inst._aipLanternStandDisplayLit,
		inst._aipLanternStandDisplayTassle
	)
end

local function clearLanternStandDisplay(inst)
	if not inst._aipLanternStandDisplay then
		return
	end

	inst._aipLanternStandDisplay = nil
	inst._aipLanternStandDisplayLit = nil
	inst._aipLanternStandDisplayTassle = nil
	skinner.PlayCurrent(inst)

	if inst.components.fueled ~= nil and inst.components.fueled:IsEmpty() then
		setVisualLight(inst, false)
	end
end

local function onRemove(inst)
	if inst._light ~= nil then
		inst._light:Remove()
	end
	if inst._body ~= nil then
		inst._body:Remove()
	end
end

local function onDropped(inst)
	clearLanternStandDisplay(inst)
	turnOff(inst)
	turnOn(inst)
end

local function shouldHideBody(owner)
	return owner.sg ~= nil
		and owner.components.rider ~= nil
		and owner.components.rider:IsRiding()
		and not owner.sg:HasStateTag("forcedangle")
end

local function toggleOverrideSymbols(inst, owner)
	owner.AnimState:Hide("LANTERN_OVERLAY")

	if shouldHideBody(owner) then
		owner.AnimState:OverrideSymbol("swap_object", SWAP_BUILD, SWAP_FULL_SYMBOL)
		inst._body:Hide()
	else
		-- 装备切换时玩家会短暂进入 nodangle，仍保持自定义灯体可见，避免先空手再出现。
		owner.AnimState:OverrideSymbol("swap_object", SWAP_BUILD, SWAP_STICK_SYMBOL)
		inst._body:Show()
	end
end

local function onRemoveBody(body)
	body._lantern._body = nil
end

local function onequip(inst, owner)
	owner.AnimState:Show("ARM_carry")
	owner.AnimState:Hide("ARM_normal")
	owner.AnimState:Hide("LANTERN_OVERLAY")
	owner.AnimState:OverrideSymbol("swap_object", SWAP_BUILD, SWAP_STICK_SYMBOL)

	if inst._body ~= nil then
		inst._body:Remove()
	end

	inst._body = SpawnPrefab(BODY_PREFAB)
	inst._body._lantern = inst
	inst._body:SetLanternSkin(inst._aipCurrentSkin)
	inst:ListenForEvent("onremove", onRemoveBody, inst._body)

	inst._body.entity:SetParent(owner.entity)
	inst._body.entity:AddFollower()
	inst._body.Follower:FollowSymbol(owner.GUID, "swap_object", 68, -126, 0)
	inst._body:ListenForEvent("newstate", function(owner)
		toggleOverrideSymbols(inst, owner)
	end, owner)

	toggleOverrideSymbols(inst, owner)

	if owner.components.bloomer ~= nil then
		owner.components.bloomer:AttachChild(inst._body)
	end
	if owner.components.colouradder ~= nil then
		owner.components.colouradder:AttachChild(inst._body)
	end

	if inst.components.fueled:IsEmpty() then
		inst._body.AnimState:Hide("LIGHT")
		owner.AnimState:Hide("LANTERN_OVERLAY")
	else
		owner.AnimState:Hide("LANTERN_OVERLAY")
		turnOn(inst)
	end
end

local function onunequip(inst, owner)
	if inst._body ~= nil then
		if inst._body.entity:IsVisible() then
			owner.AnimState:OverrideSymbol("swap_object", SWAP_BUILD, SWAP_FULL_SYMBOL)
		end
		if inst._light ~= nil then
			inst._light.entity:SetParent((inst.components.inventoryitem.owner or inst).entity)
		end
		inst._body:Remove()
	end

	owner.AnimState:Hide("ARM_carry")
	owner.AnimState:Show("ARM_normal")
	owner.AnimState:ClearOverrideSymbol("lantern_overlay")
	owner.AnimState:Hide("LANTERN_OVERLAY")

	if inst.components.fueled.consuming then
		startTrackingOwner(inst, owner)
	end
end

local function onequiptomodel(inst, owner)
	if inst._body ~= nil then
		if inst._body.entity:IsVisible() then
			owner.AnimState:OverrideSymbol("swap_object", SWAP_BUILD, SWAP_FULL_SYMBOL)
		end
		if inst._light ~= nil then
			inst._light.entity:SetParent((inst.components.inventoryitem.owner or inst).entity)
		end
		inst._body:Remove()
	end

	if inst.components.fueled.consuming then
		startTrackingOwner(inst, owner)
	end

	turnOff(inst)
end

local function noFuel(inst)
	if inst.components.equippable:IsEquipped() and inst.components.inventoryitem.owner ~= nil then
		local data = {
			prefab = inst.prefab,
			equipslot = inst.components.equippable.equipslot,
		}

		turnOff(inst)
		inst.components.inventoryitem.owner:PushEvent("torchranout", data)
	else
		turnOff(inst)
	end
end

local function onTakeFuel(inst)
	local owner = inst.components.inventoryitem.owner

	if owner == nil or inst.components.equippable:IsEquipped() then
		turnOn(inst)
	end
end

local function onLoad(inst, data)
	skinner.OnLoad(inst, data)

	if inst.components.fueled:IsEmpty() then
		noFuel(inst)
	end
end

local function startFloating(inst)
	inst.AnimState:PlayAnimation(getSkinAnim(inst._aipCurrentSkin, ANIM_FLOAT_SUFFIX))
end

local function stopFloating(inst)
	skinner.PlayCurrent(inst)
end

local function lightFn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddLight()
	inst.entity:AddNetwork()

	inst:AddTag("FX")

	inst.Light:SetIntensity(LIGHT_INTENSITY)
	inst.Light:SetFalloff(LIGHT_FALLOFF)
	inst.Light:EnableClientModulation(true)

	inst:DoPeriodicTask(.1, onUpdateFlicker, nil, GetTime())
	onUpdateFlicker(inst)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst.persists = false

	return inst
end

local function bodyFn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	inst.AnimState:SetBank(BUILD)
	inst.AnimState:SetBuild(BUILD)

	inst:AddTag("FX")

	inst._aipLanternBodySkin = net_string(inst.GUID, "aip_lantern.bodyskin", BODY_SKIN_DIRTY)
	inst:ListenForEvent(BODY_SKIN_DIRTY, function(inst)
		local skin = inst._aipLanternBodySkin:value()

		if skin ~= nil and skin ~= "" then
			playBodySkin(inst, skin)
		end
	end)

	inst.SetLanternSkin = setBodySkin

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

	MakeInventoryPhysics(inst)

	inst.AnimState:SetBank(BUILD)
	inst.AnimState:SetBuild(BUILD)

	inst:AddTag("light")
	inst:AddTag("redlantern")
	inst:AddTag("aip_lantern")

	inst.SetLanternStandDisplay = setLanternStandDisplay
	inst.ClearLanternStandDisplay = clearLanternStandDisplay

	MakeInventoryFloatable(inst, "med", nil, { .775, .5, .775 })

	skinner.SetupNetwork(inst)
	inst.scrapbook_anim = getSkinAnim(lanternConfig.DEFAULT_SKIN, ANIM_IDLE_SUFFIX)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("inspectable")

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem:SetOnDroppedFn(onDropped)
	inst.components.inventoryitem:SetOnPutInInventoryFn(turnOff)
	skinner.PlayCurrent(inst)

	inst:AddComponent("equippable")
	inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)
	inst.components.equippable:SetOnEquipToModel(onequiptomodel)

	inst:AddComponent("fueled")
	inst.components.fueled.fueltype = FUELTYPE.CAVE
	inst.components.fueled:InitializeFuelLevel(TUNING.LANTERN_LIGHTTIME)
	inst.components.fueled:SetDepletedFn(noFuel)
	inst.components.fueled:SetTakeFuelFn(onTakeFuel)
	inst.components.fueled:SetFirstPeriod(TUNING.TURNON_FUELED_CONSUMPTION, TUNING.TURNON_FULL_FUELED_CONSUMPTION)
	inst.components.fueled.accepting = true

	inst:AddComponent("fuel")
	inst.components.fuel.fuelvalue = TUNING.SMALL_FUEL

	inst:ListenForEvent("floater_startfloating", startFloating)
	inst:ListenForEvent("floater_stopfloating", stopFloating)

	MakeSmallBurnable(inst, TUNING.TINY_BURNTIME)
	MakeSmallPropagator(inst)
	MakeHauntableLaunch(inst)

	inst.components.burnable.ignorefuel = true
	inst.OnRemoveEntity = onRemove
	inst.OnSave = skinner.OnSave
	inst.OnLoad = onLoad

	turnOn(inst)

	inst._onownerequip = function(owner, data)
		if data.item ~= inst and
			(data.eslot == EQUIPSLOTS.HANDS or
			(data.eslot == EQUIPSLOTS.BODY and data.item:HasTag("heavy"))) then
			turnOff(inst)
		end
	end

	return inst
end

local prefabList = {
	Prefab(PREFAB, fn, assets, prefabs),
	Prefab(LIGHT_PREFAB, lightFn),
	Prefab(BODY_PREFAB, bodyFn, { Asset("ANIM", "anim/aip_lantern.zip") }),
}

for _, skinPrefab in ipairs(skinner.CreatePrefabSkins()) do
	table.insert(prefabList, skinPrefab)
end

return unpack(prefabList)
