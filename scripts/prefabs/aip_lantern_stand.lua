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
local LIGHT_RADIUS_BASE = 1.05
local LIGHT_RADIUS_STEP = .55
local LIGHT_INTENSITY_BASE = .45
local LIGHT_INTENSITY_STEP = .12
local LIGHT_FALLOFF = .7
local DISPLAY_FUEL_RATE_MULT = .2
local DISPLAY_FUEL_RATE_KEY = "aip_lantern_stand"

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

-- 播放当前皮肤对应的静止或受击动画。
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

-- 取得指定槽位的灯笼挂点名。
local function getDisplaySymbol(slot)
	return DISPLAY_SYMBOL_PREFIX..slot
end

-- 计算指定槽位的跟随层级偏移。
local function getDisplayZOffset(slot)
	return DISPLAY_FOLLOW_Z_OFFSET + (SLOT_COUNT - slot) * DISPLAY_FOLLOW_Z_STEP
end

-- 计算指定槽位的最终渲染层级。
local function getDisplayFinalOffset(slot)
	return SLOT_COUNT - slot + 1
end

-- 判断灯笼是否还有可发光燃料。
local function isLanternLit(item)
	return item ~= nil
		and item.components.fueled ~= nil
		and not item.components.fueled:IsEmpty()
end

-- 读取灯笼架当前或传入的开关状态。
local function isStandTurnedOn(inst, override)
	if override ~= nil then
		return override
	end

	return inst.components.machine ~= nil and inst.components.machine:IsOn()
end

-- 移除灯笼架对灯笼耐久消耗的倍率。
local function clearDisplayItemFuelRate(item, stand)
	if item ~= nil and item.components.fueled ~= nil then
		item.components.fueled.rate_modifiers:RemoveModifier(stand, DISPLAY_FUEL_RATE_KEY)
	end
end

-- 按展示状态控制灯笼耐久消耗。
local function setDisplayItemFuelConsuming(item, stand, enabled)
	if item ~= nil and item.components.fueled ~= nil then
		local fueled = item.components.fueled

		if enabled and not fueled:IsEmpty() then
			fueled.rate_modifiers:SetModifier(stand, DISPLAY_FUEL_RATE_MULT, DISPLAY_FUEL_RATE_KEY)
			fueled:StartConsuming()
		else
			clearDisplayItemFuelRate(item, stand)
			fueled:StopConsuming()
		end
	end
end

-- 根据点亮灯笼数量更新架子光照。
local function setLightCount(inst, count)
	if inst.Light == nil then
		return
	end

	inst.Light:Enable(count > 0)

	if count > 0 then
		local level = math.min(count, SLOT_COUNT)

		inst.Light:SetRadius(LIGHT_RADIUS_BASE + LIGHT_RADIUS_STEP * level)
		inst.Light:SetIntensity(LIGHT_INTENSITY_BASE + LIGHT_INTENSITY_STEP * level)
		inst.Light:SetFalloff(LIGHT_FALLOFF)
		inst.Light:SetColour(LIGHT_COLOUR.x, LIGHT_COLOUR.y, LIGHT_COLOUR.z)
	end
end

-- 让被展示的灯笼在客户端可见。
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

-- 判断物品是否仍存放在本架子的容器里。
local function isStoredDisplayItem(inst, item)
	return item ~= nil
		and item.components.inventoryitem ~= nil
		and item.components.inventoryitem.owner == inst
		and inst.components.container ~= nil
		and inst.components.container:GetItemSlot(item) ~= nil
end

-- 从展示槽记录里忘记指定物品。
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

-- 查找物品当前占用的展示槽。
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

-- 还原灯笼展示前的缩放。
local function restoreDisplayScale(item)
	if item._aipLanternStandScale ~= nil then
		item.Transform:SetScale(unpack(item._aipLanternStandScale))
		item._aipLanternStandScale = nil
	else
		item.Transform:SetScale(1, 1, 1)
	end
end

-- 灯笼燃料变化后排队刷新展示。
local function onDisplayLanternFuelChanged(item)
	local stand = item._aipLanternStand

	if stand ~= nil and stand:IsValid() and queueRefreshLanternDisplays ~= nil then
		queueRefreshLanternDisplays(stand)
	end
end

-- 解除灯笼与架子挂点的展示绑定。
local function unbindDisplayItem(inst, item, leaving)
	if item == nil or not item:IsValid() then
		forgetDisplayItem(inst, item)
		return
	end

	forgetDisplayItem(inst, item)
	inst:RemoveEventCallback("percentusedchange", onDisplayLanternFuelChanged, item)
	if leaving then
		clearDisplayItemFuelRate(item, inst)
	else
		setDisplayItemFuelConsuming(item, inst, false)
	end

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

-- 解除指定展示槽的灯笼绑定。
local function unbindDisplaySlot(inst, slot, leaving)
	local item = inst._aipLanternStandDisplayItems ~= nil and
		inst._aipLanternStandDisplayItems[slot] or nil

	unbindDisplayItem(inst, item, leaving)
end

-- 把容器灯笼绑定到指定挂点展示。
local function bindDisplayItem(inst, item, slot, showTassle, standOn)
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

	local lit = isStandTurnedOn(inst, standOn) and isLanternLit(item)
	local displayTassle = showTassle == true
	if item.SetLanternStandDisplay ~= nil and (
		not alreadyBound or
		item._aipLanternStandDisplay ~= true or
		item._aipLanternStandDisplayLit ~= lit or
		item._aipLanternStandDisplayTassle ~= displayTassle
	) then
		item:SetLanternStandDisplay(lit, displayTassle)
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

	setDisplayItemFuelConsuming(item, inst, lit)

	return true
end

-- 释放所有正在展示的灯笼。
local function releaseDisplayItems(inst, leaving)
	if inst._aipLanternStandDisplayItems == nil then
		return
	end

	for slot = 1, SLOT_COUNT do
		unbindDisplaySlot(inst, slot, leaving)
	end
end

-- 重新排列灯笼展示并同步光照。
local function refreshLanternDisplays(inst, standOn)
	if inst.components.container == nil then
		return
	end

	local displaySlot = 1
	local lightCount = 0
	standOn = isStandTurnedOn(inst, standOn)
	local displayItems = {}

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
			standOn
		) then
			if standOn and isLanternLit(item) then
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

-- 开启灯笼架光照与灯笼消耗。
local function onTurnOn(inst)
	refreshLanternDisplays(inst, true)
end

-- 关闭灯笼架光照与灯笼消耗。
local function onTurnOff(inst)
	refreshLanternDisplays(inst, false)
end

-- 延后一帧合并刷新灯笼展示。
queueRefreshLanternDisplays = function(inst)
	if inst._aipLanternStandRefreshTask == nil then
		-- itemget/itemlose 常常连着触发，延后一帧统一刷新挂灯和光照。
		inst._aipLanternStandRefreshTask = inst:DoTaskInTime(0, function(inst)
			inst._aipLanternStandRefreshTask = nil
			refreshLanternDisplays(inst)
		end)
	end
end

-- 拆掉或受击时释放所有灯笼。
local function dropLanterns(inst)
	if inst.components.container ~= nil then
		-- 灯笼架被敲击时不再保持展示绑定，直接把挂着的灯笼全部掉落。
		inst.components.container:DropEverything()
	end

	setLightCount(inst, 0)
end

-- 锤毁灯笼架并掉落内容。
local function onhammered(inst)
	dropLanterns(inst)

	inst.components.lootdropper:DropLoot()

	local fx = SpawnPrefab("collapse_small")
	fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
	fx:SetMaterial("wood")

	inst:Remove()
end

-- 被击中时掉落灯笼并播放受击动画。
local function onhit(inst)
	dropLanterns(inst)
	skinner.PlayCurrent(inst, true)
end

-- 建造完成后播放皮肤和放置音效。
local function onbuilt(inst)
	skinner.PlayCurrent(inst)

	if inst.SoundEmitter ~= nil then
		inst.SoundEmitter:PlaySound("dontstarve/common/place_structure_wood")
	end
end

-- 载入存档后恢复皮肤并刷新灯笼。
local function onload(inst, data)
	skinner.OnLoad(inst, data)
	queueRefreshLanternDisplays(inst)
end

-- 后载入阶段再次刷新灯笼展示。
local function onloadpostpass(inst)
	queueRefreshLanternDisplays(inst)
end

-- 获得灯笼后排队刷新展示。
local function onitemget(inst)
	queueRefreshLanternDisplays(inst)
end

-- 失去灯笼后清理旧绑定并刷新。
local function onitemlose(inst, data)
	if data ~= nil and data.prev_item ~= nil then
		unbindDisplayItem(inst, data.prev_item, true)
	end

	queueRefreshLanternDisplays(inst)
end

-- 移除实体前释放展示灯笼。
local function onremoveentity(inst)
	releaseDisplayItems(inst, false)
end

-- 创建灯笼架实体与组件。
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

	inst.Light:EnableClientModulation(true)
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

	inst:AddComponent("machine")
	inst.components.machine.turnonfn = onTurnOn
	inst.components.machine.turnofffn = onTurnOff
	inst.components.machine.cooldowntime = 0
	inst.components.machine:TurnOn()

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
