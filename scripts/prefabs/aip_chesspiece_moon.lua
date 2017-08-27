local foldername = KnownModIndex:GetModActualName(TUNING.ZOMBIEJ_ADDTIONAL_PACKAGE)

------------------------------------ 配置 ------------------------------------
-- 体验关闭
local additional_experiment = GetModConfigData("additional_experiment", foldername)
if additional_experiment ~= "open" then
	return nil
end

-- 食物关闭
local additional_food = GetModConfigData("additional_food", foldername)
if additional_food ~= "open" then
	return nil
end

-- 雕塑关闭
local additional_chesspieces = GetModConfigData("additional_chesspieces", foldername)
if additional_chesspieces ~= "open" then
	return nil
end

local language = GetModConfigData("language", foldername)

-- 语言
local LANG_MAP = {
	["english"] = {
		["NAME"] = "Moon Star",
		["REC_DESC"] = "Provide weak light",
		["DESC"] = "Is that Contemporary Art?",
	},
	["chinese"] = {
		["NAME"] = "月光星尘",
		["REC_DESC"] = "可以提供微弱的光芒",
		["DESC"] = "这是当代艺术吗？",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

-- 资源
local assets =
{
	Asset("ATLAS", "images/inventoryimages/aip_chesspiece_moon.xml"),
	Asset("ANIM", "anim/aip_chesspiece_moon.zip"),
}

local prefabs =
{
	"collapse_small",
}

-- 文字描述
STRINGS.NAMES.AIP_CHESSPIECE_MOON = LANG.NAME
STRINGS.RECIPE_DESC.AIP_CHESSPIECE_MOON = LANG.REC_DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_CHESSPIECE_MOON = LANG.DESC

-- 配方
local PHYSICS_RADIUS = .45

local aip_chesspiece_moon = Recipe("aip_chesspiece_moon_builder", {Ingredient(TECH_INGREDIENT.SCULPTING, 1), Ingredient("moonrocknugget", 9), Ingredient("frozen_heart", 1, "images/inventoryimages/frozen_heart.xml")}, RECIPETABS.SCULPTING, TECH.SCULPTING_ONE, nil, nil, true, nil, nil, nil, "aip_chesspiece_moon.tex")
aip_chesspiece_moon.atlas = "images/inventoryimages/aip_chesspiece_moon.xml"

-----------------------------------------------------------

local function onequip(inst, owner)
	owner.AnimState:OverrideSymbol("swap_body", "aip_chesspiece_moon", "swap_body")
end

local function onunequip(inst, owner)
	owner.AnimState:ClearOverrideSymbol("swap_body")
end

local function onworkfinished(inst)
	inst.components.lootdropper:DropLoot()
	local fx = SpawnPrefab("collapse_small")
	fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
	fx:SetMaterial("stone")
	inst:Remove()
end

local function onload(inst, data)
	if data ~= nil then
		-- inst.pieceid = data.pieceid
	end
end

local function onsave(inst, data)
	-- data.pieceid = inst.pieceid
end

function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()
	
	MakeHeavyObstaclePhysics(inst, PHYSICS_RADIUS)
	
	inst.AnimState:SetBank("chesspiece")
	inst.AnimState:SetBuild("aip_chesspiece_moon")
	inst.AnimState:PlayAnimation("idle")

	inst:AddTag("heavy")

	inst:SetPrefabName("aip_chesspiece_moon")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("heavyobstaclephysics")
	inst.components.heavyobstaclephysics:SetRadius(PHYSICS_RADIUS)

	inst:AddComponent("inspectable")

	inst:AddComponent("lootdropper")

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.cangoincontainer = false
	inst.components.inventoryitem:ChangeImageName("aip_chesspiece_moon")
	
	inst:AddComponent("equippable")
	inst.components.equippable.equipslot = EQUIPSLOTS.BODY
	inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)
	inst.components.equippable.walkspeedmult = TUNING.HEAVY_SPEED_MULT

	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
	inst.components.workable:SetWorkLeft(1)
	inst.components.workable:SetOnFinishCallback(onworkfinished)

	inst:AddComponent("hauntable")
	inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

	-- inst.OnLoad = onload
	-- inst.OnSave = onsave

	-- inst.pieceid = pieceid

	return inst
end

local prefab_aip_chesspiece_moon = Prefab("aip_chesspiece_moon", fn, assets) 


--------------------------------------------------------------------------

local function builderonbuilt(inst, builder)
	local prototyper = builder.components.builder.current_prototyper
	if prototyper ~= nil and prototyper.CreateItem ~= nil then
		prototyper:CreateItem("aip_chesspiece_moon")
	else
		local piece = SpawnPrefab("aip_chesspiece_moon")
		piece.Transform:SetPosition(builder.Transform:GetWorldPosition())
	end

	inst:Remove()
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()

	inst:AddTag("CLASSIFIED")

	--[[Non-networked entity]]
	inst.persists = false

	--Auto-remove if not spawned by builder
	inst:DoTaskInTime(0, inst.Remove)

	if not TheWorld.ismastersim then
		return inst
	end

	-- inst.pieceid = pieceid
	inst.OnBuiltFn = builderonbuilt

	return inst
end

local prefab_aip_chesspiece_moon_builder = Prefab("aip_chesspiece_moon_builder", fn, nil, { "aip_chesspiece_moon" })

return prefab_aip_chesspiece_moon, prefab_aip_chesspiece_moon_builder