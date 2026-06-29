require "prefabutil"

local language = aipGetModConfig("language")

local skinUtil = require("utils/aip_skin_util")
local wallSkinConfig = require("configurations/skin/aip_crayon_wall")

local BUILD = "aip_crayon_wall"
local ITEM = "aip_crayon_wall_item"
local BLUE_BUILD = "aip_crayon_wall_blue"
local GREEN_BUILD = "aip_crayon_wall_green"

local LANG_MAP = {
	english = {
		NAME = "Crayon Wall",
		DESC = "Bright, waxy, and surprisingly stubborn.",
	},
	chinese = {
		NAME = "蜡笔墙",
		DESC = "看起来很鲜艳，也很结实。",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_CRAYON_WALL = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_CRAYON_WALL = LANG.DESC
STRINGS.NAMES.AIP_CRAYON_WALL_ITEM = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_CRAYON_WALL_ITEM = LANG.DESC
skinUtil.RegisterBuildSkinConfig(wallSkinConfig, language, LANG.DESC)

local assets = {
	Asset("ANIM", "anim/aip_crayon_wall.zip"),
	Asset("ANIM", "anim/aip_crayon_wall_blue.zip"),
	Asset("ANIM", "anim/aip_crayon_wall_green.zip"),
	Asset("ATLAS", "images/inventoryimages/aip_crayon_wall_item.xml"),
}

for _, asset in ipairs(wallSkinConfig.GetInventoryAtlasAssets(false)) do
	table.insert(assets, asset)
end

local prefabs = {
	"collapse_small",
}

local MAX_HEALTH = TUNING.WOODWALL_HEALTH
local MAX_LOOTS = 2
local REPAIR_MATERIAL = "aip_crayon_wall"
local PLAYER_TAGS = { "player" }

local WALL_ANIMS = {
	{ threshold = 0, anim = "broken" },
	{ threshold = 0.4, anim = "onequarter" },
	{ threshold = 0.5, anim = "half" },
	{ threshold = 0.99, anim = "threequarter" },
	{ threshold = 1, anim = "full" },
}

local SKIN_BUILDS = {
	blue = BLUE_BUILD,
	green = GREEN_BUILD,
}

-- 根据墙体血量选择展示阶段。
local function ResolveAnim(percent)
	for _, data in ipairs(WALL_ANIMS) do
		if percent <= data.threshold then
			return data.anim
		end
	end

	return "full"
end

-- 取得皮肤对应的动画 build。
local function GetSkinBuild(skin)
	skin = wallSkinConfig.GetSkin(skin)

	return SKIN_BUILDS[skin] or BUILD
end

-- 取得皮肤对应的物品栏贴图名。
local function GetSkinInventoryImage(skin)
	return wallSkinConfig.GetSkinPrefab(skin) or ITEM
end

-- 规范化部署时继承的皮肤名，默认皮肤不需要额外传递。
local function NormalizeDeploySkin(skin)
	skin = wallSkinConfig.GetSkin(skin)

	return skin ~= wallSkinConfig.DEFAULT_SKIN and skin or nil
end

-- 读取部署时应继承的皮肤名，优先使用原版制作系统写入的 skinname。
local function GetDeploySkin(inst)
	return NormalizeDeploySkin(inst.skinname)
		or NormalizeDeploySkin(inst.linked_skinname)
		or NormalizeDeploySkin(inst._aipDeploySkin)
		or NormalizeDeploySkin(inst._aipCurrentSkin)
		or (inst._aipCrayonWallSkin ~= nil and NormalizeDeploySkin(inst._aipCrayonWallSkin:value()) or nil)
end

-- 拆分蜡笔墙堆叠时继承源堆的皮肤。
local function OnDeStackWallItem(item, source)
	local skin = source ~= nil and GetDeploySkin(source) or nil

	if skin ~= nil and item ~= nil and item.SetAipSkin ~= nil then
		item:SetAipSkin(skin)
	end
end

-- 按当前皮肤刷新动画 build 和物品栏贴图。
local function PlaySkin(inst, skin)
	inst._aipDeploySkin = wallSkinConfig.GetSkin(skin)
	inst.AnimState:SetBuild(GetSkinBuild(skin))

	if inst._aipCrayonWallAnim ~= nil then
		inst.AnimState:PlayAnimation(inst._aipCrayonWallAnim)
	end

	if inst.components ~= nil and inst.components.inventoryitem ~= nil then
		local image = GetSkinInventoryImage(skin)
		inst.components.inventoryitem.atlasname = "images/inventoryimages/"..image..".xml"
		inst.components.inventoryitem:ChangeImageName(image)
	end
end

local skinner = skinUtil.CreatePrefabSkinner(wallSkinConfig, {
	net_field = "_aipCrayonWallSkin",
	current_field = "_aipCurrentSkin",
	dirty_event = "aip_crayon_wall_skindirty",
	play_fn = PlaySkin,
})

-- 播放墙体当前血量阶段的静态动画。
local function PlayWallAnim(inst, anim)
	inst._aipCrayonWallAnim = anim
	inst.AnimState:PlayAnimation(anim)
end

-- 播放墙体受击动画并回到当前血量阶段。
local function PlayWallHitAnim(inst, anim)
	inst._aipCrayonWallAnim = anim
	inst.AnimState:PlayAnimation(anim.."_hit")
	inst.AnimState:PushAnimation(anim, false)
end

-- 放置预览读取手上物品的皮肤，避免蓝色墙预览仍显示默认墙。
local function OnPlacerBuilderSet(inst)
	local placer = inst.components.placer
	local invobject = placer ~= nil and placer.invobject or nil

	if invobject ~= nil then
		inst.AnimState:SetBuild(GetSkinBuild(GetDeploySkin(invobject)))
	end
end

-- 初始化放置预览的皮肤同步回调。
local function PlacerPostInit(inst)
	inst.components.placer.onbuilderset = OnPlacerBuilderSet
end

-- 同步路径墙状态，避免玩家和生物穿过实体。
local function OnIsPathFindingDirty(inst)
	if inst._ispathfinding:value() then
		if inst._pfpos == nil and inst:GetCurrentPlatform() == nil then
			inst._pfpos = inst:GetPosition()
			TheWorld.Pathfinder:AddWall(inst._pfpos:Get())
		end
	elseif inst._pfpos ~= nil then
		TheWorld.Pathfinder:RemoveWall(inst._pfpos:Get())
		inst._pfpos = nil
	end
end

-- 延后初始化路径墙，等待部署位置稳定。
local function InitializePathFinding(inst)
	inst:ListenForEvent("onispathfindingdirty", OnIsPathFindingDirty)
	OnIsPathFindingDirty(inst)
end

-- 激活碰撞和寻路阻挡。
local function MakeObstacle(inst)
	inst.Physics:SetActive(true)
	inst._ispathfinding:set(true)
end

-- 关闭碰撞和寻路阻挡。
local function ClearObstacle(inst)
	inst.Physics:SetActive(false)
	inst._ispathfinding:set(false)
end

-- 移除实体时清理路径墙。
local function OnRemove(inst)
	inst._ispathfinding:set_local(false)
	OnIsPathFindingDirty(inst)
end

-- 被修复到有血量时恢复阻挡。
local function OnRepaired(inst)
	MakeObstacle(inst)
	inst.SoundEmitter:PlaySound("dontstarve/common/place_structure_wood")
end

-- 校验破损墙修复时不会把玩家卡在墙内。
local function CanRepair(inst)
	if inst.Physics:IsActive() then
		return true
	end

	local x, y, z = inst.Transform:GetWorldPosition()
	if TheWorld.Map:IsAboveGroundAtPoint(x, y, z) then
		return true
	end

	if TheWorld.Map:IsVisualGroundAtPoint(x, y, z) then
		for _, player in ipairs(TheSim:FindEntities(x, 0, z, 1, PLAYER_TAGS)) do
			if player ~= inst and player.entity:IsVisible() and player.components.placer == nil and player.entity:GetParent() == nil then
				local px, _, pz = player.Transform:GetWorldPosition()
				if math.floor(x) == math.floor(px) and math.floor(z) == math.floor(pz) then
					return false
				end
			end
		end
	end

	return true
end

-- 部署墙物品时在网格中心生成墙体。
local function OnDeployWall(inst, pt)
	local skin = GetDeploySkin(inst)
	local wall = SpawnPrefab(BUILD)

	if wall ~= nil then
		if wall.SetAipSkin ~= nil then
			wall:SetAipSkin(skin)
		end

		local x = math.floor(pt.x) + .5
		local z = math.floor(pt.z) + .5
		wall.Physics:SetCollides(false)
		wall.Physics:Teleport(x, 0, z)
		wall.Physics:SetCollides(true)
		inst.components.stackable:Get():Remove()

		wall.SoundEmitter:PlaySound("dontstarve/common/place_structure_wood")
	end
end

-- 受击时播放当前血量阶段的轻微晃动。
local function OnHit(inst)
	inst.SoundEmitter:PlaySound("dontstarve/common/destroy_wood")

	if not inst.components.health:IsDead() then
		local anim = ResolveAnim(inst.components.health:GetPercent())
		PlayWallHitAnim(inst, anim)
	end
end

-- 血量变化时更新墙体阶段。
local function OnHealthChange(inst, old_percent, new_percent)
	local anim = ResolveAnim(new_percent)

	if new_percent > 0 then
		if old_percent <= 0 then
			MakeObstacle(inst)
		end

		PlayWallHitAnim(inst, anim)
	else
		if old_percent > 0 then
			ClearObstacle(inst)
		end

		PlayWallAnim(inst, anim)
	end
end

-- 锤掉时按剩余血量返回少量材料。
local function OnHammered(inst)
	local loot_count = math.max(1, math.floor(MAX_LOOTS * inst.components.health:GetPercent()))

	for _ = 1, loot_count do
		inst.components.lootdropper:SpawnLootPrefab("log")
	end

	local fx = SpawnPrefab("collapse_small")
	fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
	fx:SetMaterial("wood")

	inst:Remove()
end

-- 阻止墙主动保持攻击目标。
local function KeepTarget()
	return false
end

-- 读档时修正死亡墙的碰撞状态。
local function OnLoad(inst, data)
	skinner.OnLoad(inst, data)
	PlayWallAnim(inst, ResolveAnim(inst.components.health:GetPercent()))

	if inst.components.health:IsDead() then
		ClearObstacle(inst)
	end
end

-- 创建可部署的蜡笔墙物品。
local function ItemFn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)

	inst:AddTag("wallbuilder")

	inst.AnimState:SetBank(BUILD)
	inst.AnimState:SetBuild(BUILD)
	inst._aipCrayonWallAnim = "item"
	skinner.SetupNetwork(inst)

	MakeInventoryFloatable(inst)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	skinner.SetupMaster(inst)

	inst:AddComponent("stackable")
	inst.components.stackable.maxsize = TUNING.STACK_SIZE_MEDITEM
	inst.components.stackable:SetOnDeStack(OnDeStackWallItem)

	inst:AddComponent("inspectable")
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_crayon_wall_item.xml"

	inst:AddComponent("repairer")
	inst.components.repairer.repairmaterial = REPAIR_MATERIAL
	inst.components.repairer.healthrepairvalue = MAX_HEALTH / 6

	-- 掉落物可以被点燃，但不会作为火源向周围传播。
	MakeSmallBurnable(inst, TUNING.MED_BURNTIME)

	inst:AddComponent("fuel")
	inst.components.fuel.fuelvalue = TUNING.SMALL_FUEL

	inst:AddComponent("deployable")
	inst.components.deployable.ondeploy = OnDeployWall
	inst.components.deployable:SetDeployMode(DEPLOYMODE.WALL)

	inst.OnSave = skinner.OnSave
	inst.OnLoad = skinner.OnLoad

	MakeHauntableLaunch(inst)

	return inst
end

-- 创建部署后的蜡笔墙实体。
local function WallFn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	-- 参考原版墙体，根据视角切换到对应方向动画。
	inst.Transform:SetEightFaced()

	inst:SetDeploySmartRadius(0.5)

	MakeObstaclePhysics(inst, .5)
	inst.Physics:SetDontRemoveOnSleep(true)

	inst:AddTag("wall")
	inst:AddTag("wood")
	inst:AddTag("noauradamage")
	inst:AddTag("electricdamageimmune")

	inst.AnimState:SetBank(BUILD)
	inst.AnimState:SetBuild(BUILD)
	inst._aipCrayonWallAnim = "half"
	skinner.SetupNetwork(inst)

	inst._pfpos = nil
	inst._ispathfinding = net_bool(inst.GUID, "_ispathfinding", "onispathfindingdirty")
	MakeObstacle(inst)
	inst:DoTaskInTime(0, InitializePathFinding)
	inst.OnRemoveEntity = OnRemove

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	skinner.SetupMaster(inst)

	inst.scrapbook_specialinfo = "WALLS"
	inst.scrapbook_anim = "half"

	inst:AddComponent("inspectable")
	inst:AddComponent("lootdropper")

	inst:AddComponent("repairable")
	inst.components.repairable.repairmaterial = REPAIR_MATERIAL
	inst.components.repairable.onrepaired = OnRepaired
	inst.components.repairable.testvalidrepairfn = CanRepair

	inst:AddComponent("combat")
	inst.components.combat:SetKeepTargetFunction(KeepTarget)
	inst.components.combat.onhitfn = OnHit

	inst:AddComponent("health")
	inst.components.health:SetMaxHealth(MAX_HEALTH)
	inst.components.health:SetCurrentHealth(MAX_HEALTH * .5)
	inst.components.health.ondelta = OnHealthChange
	inst.components.health.nofadeout = true
	inst.components.health.canheal = false

	-- 蜡笔墙可以被点燃，但不会作为火源向周围传播。
	MakeMediumBurnable(inst)
	inst.components.burnable.flammability = .5
	inst.components.burnable.nocharring = true

	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
	inst.components.workable:SetWorkLeft(3)
	inst.components.workable:SetOnFinishCallback(OnHammered)
	inst.components.workable:SetOnWorkCallback(OnHit)

	MakeHauntableWork(inst)

	inst.OnLoad = OnLoad
	inst.OnSave = skinner.OnSave

	return inst
end

local prefabList = {
	Prefab(BUILD, WallFn, assets, prefabs),
	Prefab(ITEM, ItemFn, assets, { BUILD, ITEM.."_placer" }),
	MakePlacer(ITEM.."_placer", BUILD, BUILD, "half", false, false, true, nil, nil, "eight", PlacerPostInit),
}

for _, skinPrefab in ipairs(skinner.CreatePrefabSkins()) do
	table.insert(prefabList, skinPrefab)
end

return unpack(prefabList)
