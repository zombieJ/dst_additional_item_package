local language = aipGetModConfig("language")
local dev_mode = aipGetModConfig("dev_mode") == "enabled"

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
local GUEST_FOLLOW_Z_OFFSET = .1
local hasSleepingGuest
local syncDisplay

-- 播放当前皮肤动画，客人睡觉时切到对应的 _guest 动画。
local function playSkin(inst, skin, hit)
	skin = cozyNestConfig.GetSkin(skin)
	local idleAnim = hasSleepingGuest ~= nil and hasSleepingGuest(inst) and skin..GUEST_ANIM_SUFFIX or skin

	if hit and idleAnim == skin then
		inst.AnimState:PlayAnimation(skin.."_hit")
		inst.AnimState:PushAnimation(idleAnim, true)
	else
		inst.AnimState:PlayAnimation(idleAnim, true)
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

local DISPLAY_SYMBOL = "swap_item"
local DISPLAY_FOLLOW_Z_OFFSET = .1
local GUEST_DIRTY = "aip_cozy_nest_guest_dirty"
local SPECIAL_GUESTS = {
	chester_eyebone = {
		prefab = "chester",
		x = 0,
		z = .35,
		face_x = 1,
		face_z = .35,
	},
	hutch_fishbowl = {
		prefab = "hutch",
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

local function debugDisplayLog(inst, ...)
	if not dev_mode then
		return
	end

	local side = TheWorld ~= nil and (TheWorld.ismastersim and "server" or "client") or "unknown"
	aipPrint("[cozy_nest_display]", side, inst ~= nil and inst.GUID or "nil", ...)
end

-- 只有带 leader 的有效道具才能驱动对应客人进入小窝。
local function getSpecialGuestConfig(item)
	if item == nil or item.components.leader == nil then
		return nil
	end

	local config = SPECIAL_GUESTS[item.prefab]
	if config == nil then
		return nil
	end

	if item.prefab == "glommerflower" and not item:HasTag("glommerflower") then
		return nil
	end

	return config
end

-- 读取小窝容器里当前展示或驱动客人的唯一物品。
local function getStoredItem(inst)
	return inst.components.container ~= nil and inst.components.container:GetItemInSlot(1) or nil
end

-- 判断当前是否处在客人睡觉展示状态。
hasSleepingGuest = function(inst)
	return inst._aipCozyNestHasGuest ~= nil and inst._aipCozyNestHasGuest:value()
end

local function isStoredDisplayItem(inst, item)
	return item ~= nil and item:IsValid() and
		item.components.inventoryitem ~= nil and
		item.components.inventoryitem.owner == inst and
		inst.components.container ~= nil and
		inst.components.container:GetItemInSlot(1) == item
end

-- 展示物需要像容器被多人打开时一样对所有客户端可见，否则关箱后会被收回到 owner 可见范围。
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

-- 容器会把物品放进 limbo；展示时把原物品临时拉回场景并挂到小窝锚点。
local function bindDisplayItem(inst, item)
	if item == nil or not item:IsValid() or hasSleepingGuest(inst) then
		return false
	end

	if item.Follower == nil then
		item.entity:AddFollower()
	end

	-- 关闭容器流程会把库存物品重新压回 limbo；这里先降后升，强制重发展示状态。
	item:ForceOutOfLimbo(false)
	item:ForceOutOfLimbo(true)
	item:ReturnToScene()
	exposeDisplayItem(item)
	item.Transform:SetPosition(inst.Transform:GetWorldPosition())
	item.Follower:FollowSymbol(inst.GUID, DISPLAY_SYMBOL, 0, 0, DISPLAY_FOLLOW_Z_OFFSET)
	item:AddTag("INLIMBO")
	item:AddTag("NOCLICK")

	if item.Physics ~= nil then
		item.Physics:SetActive(false)
	end

	if item.StopBrain ~= nil then
		item:StopBrain()
	end

	inst._aipDisplayItem = item
	inst.AnimState:ShowSymbol(DISPLAY_SYMBOL)
	debugDisplayLog(inst, "display_bind", "prefab="..tostring(item.prefab), "guid="..tostring(item.GUID))

	return true
end

-- 释放展示绑定；如果物品仍在小窝容器里，就重新隐藏回容器状态。
local function unbindDisplayItem(inst)
	local item = inst._aipDisplayItem
	inst._aipDisplayItem = nil

	if item == nil or not item:IsValid() then
		return
	end

	if item.Follower ~= nil then
		item.Follower:StopFollowing()
	end

	item:RemoveTag("NOCLICK")
	item:ForceOutOfLimbo(false)

	if isStoredDisplayItem(inst, item) then
		item:RemoveFromScene()
		item.Transform:SetPosition(0, 0, 0)
	elseif item.components.inventoryitem == nil or item.components.inventoryitem.owner == nil then
		item:RemoveTag("INLIMBO")
		item:ReturnToScene()
	end

	debugDisplayLog(inst, "display_unbind", "prefab="..tostring(item.prefab), "guid="..tostring(item.GUID))
end

-- 同步小窝容器里的原物品展示状态。
syncDisplay = function(inst, item)
	debugDisplayLog(inst, "syncDisplay", "item="..tostring(item ~= nil and item.prefab or nil))

	if item == nil or not item:IsValid() or hasSleepingGuest(inst) then
		unbindDisplayItem(inst)
		inst.AnimState:HideSymbol(DISPLAY_SYMBOL)
		return
	end

	if inst._aipDisplayItem ~= item then
		unbindDisplayItem(inst)
	end

	bindDisplayItem(inst, item)
end

local function clearDisplay(inst)
	unbindDisplayItem(inst)
	inst.AnimState:HideSymbol(DISPLAY_SYMBOL)
end

-- 重新播放小窝外观动画，并重新同步展示物品。
local function refreshGuestVisual(inst)
	skinner.PlayCurrent(inst)

	if TheWorld.ismastersim then
		syncDisplay(inst, getStoredItem(inst))
	end
end

-- 切换客人睡觉标记，让客户端也播放对应的 guest 动画。
local function setSleepingGuestVisual(inst, enabled)
	if inst._aipCozyNestHasGuest ~= nil then
		inst._aipCozyNestHasGuest:set(enabled == true)
	end

	refreshGuestVisual(inst)
end
-- 将睡着的客人绑定到小窝动画里的 swap_item 锚点上。
local function bindSpecialGuest(inst, follower)
	if follower.Follower == nil then
		follower.entity:AddFollower()
	end

	follower.Follower:FollowSymbol(
		inst.GUID,
		DISPLAY_SYMBOL,
		0,
		0,
		GUEST_FOLLOW_Z_OFFSET
	)
end

-- 客人离开小窝时停止跟随小窝动画锚点。
local function unbindSpecialGuest(follower)
	if follower ~= nil and follower:IsValid() then
		if follower.Follower ~= nil then
			follower.Follower:StopFollowing()
		end
	end
end

-- 更换物品或移除小窝前，完整释放当前绑定的客人。
local function releaseSpecialGuest(inst)
	local follower = inst._aipCozyNestGuest
	setSleepingGuestVisual(inst, false)

	if follower ~= nil then
		inst._aipCozyNestGuest = nil

		if follower:IsValid() and follower._aipCozyNest == inst then
			follower._aipCozyNest = nil
			unbindSpecialGuest(follower)

			if follower.components.sleeper ~= nil and follower.components.sleeper:IsAsleep() then
				follower.components.sleeper:WakeUp()
			end
		end
	end
end

-- 根据配置计算客人在小窝旁的目标站位。
local function getGuestPoint(inst, config)
	local x, y, z = inst.Transform:GetWorldPosition()
	return x + (config.x or 0), y, z + (config.z or 0)
end

-- 把客人移动到足够接近小窝的位置，让原版 sleeper 测试可以成功。
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

-- 周期性同步特殊客人：靠近时入睡，太远时引导它走向小窝。
local function syncSpecialGuest(inst, item)
	local guestConfig = getSpecialGuestConfig(item)

	if guestConfig == nil then
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
					local isAsleep = follower.components.sleeper:IsAsleep()
					setSleepingGuestVisual(inst, isAsleep)

					if isAsleep then
						bindSpecialGuest(inst, follower)
					else
						unbindSpecialGuest(follower)
					end
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

-- 停止特殊客人的周期刷新任务。
local function stopRefreshTask(inst)
	if inst._aipCozyNestRefreshTask ~= nil then
		inst._aipCozyNestRefreshTask:Cancel()
		inst._aipCozyNestRefreshTask = nil
	end
end

-- 启动特殊客人的周期刷新任务，用来持续拉近客人直到入睡。
local function startRefreshTask(inst)
	if inst._aipCozyNestRefreshTask == nil then
		inst._aipCozyNestRefreshTask = inst:DoPeriodicTask(2, refreshNest)
	end
end

-- 只有当前物品能驱动特殊客人时，才保留周期刷新。
local function updateRefreshTask(inst, item)
	if getSpecialGuestConfig(item) ~= nil then
		startRefreshTask(inst)
	else
		stopRefreshTask(inst)
	end
end

-- 统一刷新展示贴图、特殊客人状态和周期任务开关。
refreshNest = function(inst)
	local item = getStoredItem(inst)

	syncDisplay(inst, item)
	syncSpecialGuest(inst, item)
	updateRefreshTask(inst, item)
end

-- 物品替换会连续触发 itemlose/itemget，这里合并到下一帧刷新一次。
local function queueRefreshNest(inst)
	if inst._aipCozyNestRefreshQueued == nil then
		inst._aipCozyNestRefreshQueued = inst:DoTaskInTime(0, function(inst)
			inst._aipCozyNestRefreshQueued = nil
			refreshNest(inst)
		end)
	end
end

-- 敲毁小窝时释放客人、掉落容器内容并清理展示。
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

-- 受击时播放当前皮肤的 hit 动画。
local function onhit(inst)
	skinner.PlayCurrent(inst, true)
end

-- 建造完成后播放当前皮肤并补放放置音效。
local function onbuilt(inst)
	skinner.PlayCurrent(inst)

	if inst.SoundEmitter ~= nil then
		inst.SoundEmitter:PlaySound("dontstarve/common/place_structure_wood")
	end
end

-- 读档后恢复皮肤，并排队刷新容器展示和客人状态。
local function onload(inst, data)
	skinner.OnLoad(inst, data)
	queueRefreshNest(inst)
end

-- 读档后所有实体引用恢复完毕时，再刷新一次，确保容器里已有物品也能重新展示。
local function onloadpostpass(inst)
	queueRefreshNest(inst)
end

-- 创建温馨小窝实体，挂载网络字段、容器和可锤毁逻辑。
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

	inst._aipCozyNestHasGuest = net_bool(inst.GUID, "aip_cozy_nest.has_guest", GUEST_DIRTY)
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
	inst.OnLoadPostPass = onloadpostpass

	inst:ListenForEvent("onbuilt", onbuilt)
	inst:ListenForEvent("itemget", queueRefreshNest)
	inst:ListenForEvent("itemlose", queueRefreshNest)
	inst:ListenForEvent("onopen", queueRefreshNest)
	inst:ListenForEvent("onclose", queueRefreshNest)

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
