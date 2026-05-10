-- 食物
local additional_food = aipGetModConfig("additional_food")
if additional_food ~= "open" then
	return nil
end

local language = aipGetModConfig("language")

local LOTUS_VARIANTS = 7
local PLANT_SCALE = 0.7
local RIPPLE_SCALE = 2

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

local lotusPrefabs = { "aip_lotus_seed", "oceanfishinghook_ripple" }
local seedPrefabs = { "aip_lotus", "spoiled_food" }

-- 切换莲花样式，读档时保持外观一致。
local function setLotusVariant(inst, variant)
	variant = tonumber(variant)
	if variant == nil or variant < 1 or variant > LOTUS_VARIANTS then
		variant = 1
	end

	inst._aip_lotus_variant = variant
	inst.AnimState:PlayAnimation("idle_"..variant, true)
end

-- 保存莲花随机到的样式。
local function onSave(inst, data)
	data.variant = inst._aip_lotus_variant
end

-- 读取莲花样式，避免读档后重新随机。
local function onLoad(inst, data)
	if data ~= nil and data.variant ~= nil then
		inst:SetAipLotusVariant(data.variant)
	end
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

-- 莲子种到海面后生成随机样式的无限之莲。
local function onSeedDeploy(inst, pt, deployer)
	local lotus = SpawnPrefab("aip_lotus")
	if lotus ~= nil then
		lotus.Transform:SetPosition(pt:Get())
		lotus:SetAipLotusVariant(math.random(LOTUS_VARIANTS))

		if deployer ~= nil and deployer.SoundEmitter ~= nil then
			deployer.SoundEmitter:PlaySound("dontstarve/common/plant")
		end

		inst.components.stackable:Get():Remove()
	end
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
	inst.AnimState:SetRayTestOnBB(true)
	inst.SetAipLotusVariant = setLotusVariant
	setLotusVariant(inst, 1)
	addWaterRipple(inst)

	inst:SetDeploySmartRadius(DEPLOYSPACING_RADIUS[DEPLOYSPACING.MEDIUM] / 2)

	inst:AddTag("plant")
	inst:AddTag("aip_lotus")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:SetAipLotusVariant(math.random(LOTUS_VARIANTS))

	inst:AddComponent("inspectable")

	inst:AddComponent("pickable")
	inst.components.pickable:SetUp("aip_lotus_seed")
	inst.components.pickable.picksound = "turnoftides/common/together/water/harvest_plant"
	inst.components.pickable.remove_when_picked = true

	inst.OnSave = onSave
	inst.OnLoad = onLoad

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
	MakePlacer("aip_lotus_seed_placer", "aip_lotus", "aip_lotus", "idle_1", false, false, false, PLANT_SCALE)
