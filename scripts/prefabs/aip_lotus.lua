-- 食物
local additional_food = aipGetModConfig("additional_food")
if additional_food ~= "open" then
	return nil
end

local dev_mode = aipGetModConfig("dev_mode") == "enabled"
local language = aipGetModConfig("language")

local MAX_FLOWERS = 3
local LEAF_VARIANTS = 6
local GROW_TIMER = "aip_lotus_grow"
local GROW_TIME = dev_mode and 8 or (TUNING.TOTAL_DAY_TIME or 480) * 0.25
local PLANT_SCALE = 0.7
local RIPPLE_SCALE = 2

local BUD_VARIANTS = { 4, 7, 11 }
local FLOWER_VARIANTS = { 1, 2, 3, 5, 6, 8, 9, 10, 12, 13, 14 }

local LEAF_SLOTS = {
	{ x = -0.65, z = 0.18, scale = 1.05, rot = -18 },
	{ x = 0.58, z = 0.18, scale = 1.00, rot = 18 },
	{ x = -0.38, z = -0.38, scale = 0.96, rot = 10 },
	{ x = 0.36, z = -0.38, scale = 0.94, rot = -12 },
	{ x = 0.00, z = 0.42, scale = 0.82, rot = 0 },
	{ x = 0.00, z = -0.02, scale = 0.72, rot = 24 },
}

local FLOWER_SLOTS = {
	{ x = -0.38, z = -0.05, scale = 0.98 },
	{ x = 0.38, z = 0.08, scale = 0.94 },
	{ x = 0.02, z = -0.42, scale = 0.88 },
	{ x = -0.10, z = 0.36, scale = 0.82 },
}

local LANG_MAP = {
	english = {
		LOTUS_NAME = "Infinite Lotus",
		LOTUS_DESC = "It remembers the shape it bloomed in.",
		SEED_NAME = "Lotus Seed",
		SEED_DESC = "It is waiting for the sea.",
	},
	chinese = {
		LOTUS_NAME = "无限之莲",
		LOTUS_DESC = "这次会开成什么样子？",
		SEED_NAME = "莲子",
		SEED_DESC = "似乎要种在海里。",
	},
	russian = {
		LOTUS_NAME = "Бесконечный лотос",
		LOTUS_DESC = "Он помнит форму своего цветения.",
		SEED_NAME = "Семя лотоса",
		SEED_DESC = "Оно ждет моря.",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_LOTUS = LANG.LOTUS_NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_LOTUS = LANG.LOTUS_DESC

STRINGS.NAMES.AIP_LOTUS_SEED = LANG.SEED_NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_LOTUS_SEED = LANG.SEED_DESC

local assets = {
	Asset("ANIM", "anim/aip_lotus.zip"),
	Asset("ANIM", "anim/aip_lotus_seed.zip"),
	Asset("ATLAS", "images/inventoryimages/aip_lotus_seed.xml"),
}

local lotusPrefabs = { "aip_lotus_seed", "aip_lotus_part", "oceanfishinghook_ripple" }
local seedPrefabs = { "aip_lotus", "spoiled_food" }

-- 返回随机列表项。
local function randomItem(list)
	return list[math.random(#list)]
end

-- 复制坐标表，避免直接改动模板。
local function cloneSlot(slot)
	local data = {}
	for k, v in pairs(slot) do
		data[k] = v
	end
	return data
end

-- 打乱列表，用于生成每株固定但不同的花位。
local function shuffledSlots(slots)
	local list = {}
	for i, slot in ipairs(slots) do
		list[i] = cloneSlot(slot)
	end

	for i = #list, 2, -1 do
		local j = math.random(i)
		list[i], list[j] = list[j], list[i]
	end

	return list
end

-- 轻微扰动位置，保证不同植株不会完全一致。
local function randomOffset(value, range)
	return value + (math.random() * 2 - 1) * range
end

-- 生成一株无限之莲的固定组合数据。
local function createLotusStyle()
	local leafSlots = shuffledSlots(LEAF_SLOTS)
	local flowerSlots = shuffledSlots(FLOWER_SLOTS)
	local style = {
		leaves = {},
		flowers = {},
	}

	for i = 1, math.random(4, 5) do
		local slot = leafSlots[i]
		table.insert(style.leaves, {
			anim = "leaf_"..math.random(LEAF_VARIANTS),
			x = randomOffset(slot.x, 0.06),
			z = randomOffset(slot.z, 0.04),
			scale = slot.scale * (0.92 + math.random() * 0.16),
			rot = slot.rot + math.random(-12, 12),
		})
	end

	for i = 1, MAX_FLOWERS do
		local slot = flowerSlots[i]
		table.insert(style.flowers, {
			bud = "flower_"..randomItem(BUD_VARIANTS),
			flower = "flower_"..randomItem(FLOWER_VARIANTS),
			x = randomOffset(slot.x, 0.04),
			z = randomOffset(slot.z, 0.03),
			scale = slot.scale * (0.94 + math.random() * 0.12),
		})
	end

	return style
end

-- 清理旧散件，刷新外观时会重新生成。
local function clearLotusParts(inst)
	if inst._aip_lotus_parts ~= nil then
		for _, part in ipairs(inst._aip_lotus_parts) do
			if part:IsValid() then
				part:Remove()
			end
		end
	end

	inst._aip_lotus_parts = {}
	inst.highlightchildren = nil
end

-- 让采摘状态和当前开花数量保持一致。
local function refreshPickable(inst)
	if inst.components.pickable ~= nil then
		inst.components.pickable.canbepicked = (inst._aip_lotus_bloom_count or 0) > 0
	end
end

-- 根据保存的组合和生长阶段重建可见散件。
local function refreshLotusParts(inst)
	if not TheWorld.ismastersim then
		return
	end

	clearLotusParts(inst)

	local style = inst._aip_lotus_style or createLotusStyle()
	inst._aip_lotus_style = style

	for _, leaf in ipairs(style.leaves or {}) do
		local part = SpawnPrefab("aip_lotus_part")
		if part ~= nil then
			inst:AddChild(part)
			part:SetAipLotusPart({
				kind = "leaf",
				anim = leaf.anim,
				x = leaf.x,
				z = leaf.z,
				scale = leaf.scale,
				rot = leaf.rot,
			})
			table.insert(inst._aip_lotus_parts, part)
		end
	end

	local bloomCount = inst._aip_lotus_bloom_count or 0
	for i, flower in ipairs(style.flowers or {}) do
		local anim = nil
		if i <= bloomCount then
			anim = flower.flower
		elseif i == bloomCount + 1 then
			anim = flower.bud
		end

		if anim ~= nil then
			local part = SpawnPrefab("aip_lotus_part")
			if part ~= nil then
				inst:AddChild(part)
				part:SetAipLotusPart({
					kind = "flower",
					anim = anim,
					x = flower.x,
					z = flower.z,
					scale = flower.scale,
				})
				table.insert(inst._aip_lotus_parts, part)
			end
		end
	end

	inst.highlightchildren = inst._aip_lotus_parts
	refreshPickable(inst)
end

-- 安排当前花苞开花。
local function startGrowTimer(inst, restart)
	if inst.components.timer == nil or (inst._aip_lotus_bloom_count or 0) >= MAX_FLOWERS then
		return
	end

	if restart and inst.components.timer:TimerExists(GROW_TIMER) then
		inst.components.timer:StopTimer(GROW_TIMER)
	end

	if not inst.components.timer:TimerExists(GROW_TIMER) then
		inst.components.timer:StartTimer(GROW_TIMER, GROW_TIME)
	end
end

-- 花苞成熟时推进到下一朵花。
local function onGrowTimerDone(inst, data)
	if data == nil or data.name ~= GROW_TIMER then
		return
	end

	inst._aip_lotus_bloom_count = math.min(MAX_FLOWERS, (inst._aip_lotus_bloom_count or 0) + 1)
	refreshLotusParts(inst)
	startGrowTimer(inst, false)
end

-- 采摘一朵已经开放的花，并让对应花位重新排队生长。
local function onPicked(inst)
	if (inst._aip_lotus_bloom_count or 0) > 0 then
		inst._aip_lotus_bloom_count = inst._aip_lotus_bloom_count - 1
	end

	refreshLotusParts(inst)
	startGrowTimer(inst, true)

	inst:DoTaskInTime(0, refreshPickable)
end

-- 保存莲花固定组合和当前开花数量。
local function onSave(inst, data)
	data.style = inst._aip_lotus_style
	data.bloom_count = inst._aip_lotus_bloom_count
end

-- 读取莲花组合，避免读档后重新随机。
local function onLoad(inst, data)
	if data ~= nil then
		inst._aip_lotus_style = data.style or inst._aip_lotus_style
		inst._aip_lotus_bloom_count = math.min(MAX_FLOWERS, math.max(0, data.bloom_count or 0))
	end

	if inst._aip_lotus_style == nil then
		inst._aip_lotus_style = createLotusStyle()
	end

	refreshLotusParts(inst)
	inst:DoTaskInTime(0, function(inst)
		refreshPickable(inst)
		startGrowTimer(inst, false)
	end)
end

-- 在莲花下方挂载原版水面波纹。
local function addWaterRipple(inst)
	if TheNet:IsDedicated() then
		return
	end

	local ripple = SpawnPrefab("oceanfishinghook_ripple")
	if ripple ~= nil then
		inst:AddChild(ripple)
		ripple.Transform:SetPosition(0, 0, 0)
		ripple.Transform:SetScale(RIPPLE_SCALE, RIPPLE_SCALE, RIPPLE_SCALE)
	end
end

-- 莲子种到海面后生成随机组合的无限之莲。
local function onSeedDeploy(inst, pt, deployer)
	local lotus = SpawnPrefab("aip_lotus")
	if lotus ~= nil then
		lotus.Transform:SetPosition(pt:Get())
		lotus:RandomAipLotusStyle(true)

		if deployer ~= nil and deployer.SoundEmitter ~= nil then
			deployer.SoundEmitter:PlaySound("dontstarve/common/plant")
		end

		inst.components.stackable:Get():Remove()
	end
end

-- 配置散件实体的动画和摆放方式。
local function setLotusPart(inst, data)
	if data == nil then
		return
	end

	local scale = data.scale or 1
	inst.AnimState:PlayAnimation(data.anim or "clickbox", true)
	inst.Transform:SetPosition(data.x or 0, 0, data.z or 0)
	inst.Transform:SetScale(scale, scale, scale)

	if data.kind == "leaf" then
		inst.Transform:SetRotation(data.rot or 0)
		inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
		inst.AnimState:SetLayer(LAYER_BACKGROUND)
		inst.AnimState:SetSortOrder(3)
	else
		inst.AnimState:SetFinalOffset(1)
	end
end

-- 创建莲花散件，用于荷叶平铺和荷花直立显示。
local function lotusPartFn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	inst.AnimState:SetBank("aip_lotus")
	inst.AnimState:SetBuild("aip_lotus")
	inst.AnimState:PlayAnimation("clickbox")

	inst:AddTag("FX")
	inst:AddTag("NOCLICK")
	inst:AddTag("DECOR")

	inst.SetAipLotusPart = setLotusPart

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst.persists = false

	return inst
end

-- 创建海面上的无限之莲。
local function lotusFn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	inst.Transform:SetScale(PLANT_SCALE, PLANT_SCALE, PLANT_SCALE)
	inst.AnimState:SetBank("aip_lotus")
	inst.AnimState:SetBuild("aip_lotus")
	inst.AnimState:PlayAnimation("clickbox")
	inst.AnimState:SetRayTestOnBB(true)
	addWaterRipple(inst)

	inst:SetDeploySmartRadius(DEPLOYSPACING_RADIUS[DEPLOYSPACING.MEDIUM] / 2)

	inst:AddTag("plant")
	inst:AddTag("aip_lotus")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst._aip_lotus_style = createLotusStyle()
	inst._aip_lotus_bloom_count = 0

	inst.RandomAipLotusStyle = function(inst, resetGrow)
		inst._aip_lotus_style = createLotusStyle()
		if resetGrow then
			inst._aip_lotus_bloom_count = 0
		end
		refreshLotusParts(inst)
		startGrowTimer(inst, resetGrow == true)
	end

	inst:AddComponent("inspectable")

	inst:AddComponent("pickable")
	inst.components.pickable:SetUp("aip_lotus_seed")
	inst.components.pickable.picksound = "turnoftides/common/together/water/harvest_plant"
	inst.components.pickable.onpickedfn = onPicked

	inst:AddComponent("timer")
	inst:ListenForEvent("timerdone", onGrowTimerDone)

	inst.OnSave = onSave
	inst.OnLoad = onLoad
	inst.OnRemoveEntity = clearLotusParts

	refreshLotusParts(inst)
	startGrowTimer(inst, true)

	return inst
end

-- 创建可食用、可下海种植的莲子。
local function seedFn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)
	MakeInventoryFloatable(inst, "small", 0.15, 0.9)

	inst.AnimState:SetBank("aip_lotus_seed")
	inst.AnimState:SetBuild("aip_lotus_seed")
	inst.AnimState:PlayAnimation("idle")
	inst.AnimState:SetRayTestOnBB(true)

	inst:AddTag("deployedplant")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("edible")
	inst.components.edible.healthvalue = TUNING.HEALING_TINY
	inst.components.edible.hungervalue = 12.5
	inst.components.edible.sanityvalue = 0
	inst.components.edible.foodtype = FOODTYPE.VEGGIE

	inst:AddComponent("stackable")
	inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

	inst:AddComponent("tradable")
	inst:AddComponent("inspectable")
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_lotus_seed.xml"

	inst:AddComponent("perishable")
	inst.components.perishable:SetPerishTime(TUNING.PERISH_SUPERSLOW)
	inst.components.perishable:StartPerishing()
	inst.components.perishable.onperishreplacement = "spoiled_food"

	inst:AddComponent("bait")

	inst:AddComponent("deployable")
	inst.components.deployable:SetDeployMode(DEPLOYMODE.WATER)
	inst.components.deployable:SetDeploySpacing(DEPLOYSPACING.MEDIUM)
	inst.components.deployable.ondeploy = onSeedDeploy

	MakeSmallBurnable(inst)
	MakeSmallPropagator(inst)
	MakeHauntableLaunchAndPerish(inst)

	return inst
end

return Prefab("aip_lotus", lotusFn, assets, lotusPrefabs),
	Prefab("aip_lotus_seed", seedFn, assets, seedPrefabs),
	Prefab("aip_lotus_part", lotusPartFn, assets),
	MakePlacer("aip_lotus_seed_placer", "aip_lotus", "aip_lotus", "flower_4", false, false, false, PLANT_SCALE)
