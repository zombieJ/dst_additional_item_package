local foldername = KnownModIndex:GetModActualName(TUNING.ZOMBIEJ_ADDTIONAL_PACKAGE)

------------------------------------ 配置 ------------------------------------
-- 建筑关闭
local additional_building = GetModConfigData("additional_building", foldername)
if additional_building ~= "open" then
	return nil
end

local language = GetModConfigData("language", foldername)

local LANG_MAP = {
	["english"] = {
		["NAME"] = "Nectar Maker",
		["DESC"] = "Make your own nectar",
		["DESCRIBE"] = "Making with fruits",
	},
	["chinese"] = {
		["NAME"] = "花蜜酿造桶",
		["DESC"] = "制造你自己的独特饮品",
		["DESCRIBE"] = "用水果填充它吧",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

-- 开发模式
local dev_mode = GetModConfigData("dev_mode", foldername) == "enabled"

-- 文字描述
STRINGS.NAMES.AIP_NECTAR_MAKER = LANG.NAME
STRINGS.RECIPE_DESC.AIP_NECTAR_MAKER = LANG.DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_NECTAR_MAKER = LANG.DESCRIBE

TUNING.AIP_NECTAR_COOKTIME = dev_mode and 3 or 60

-- 配方
local aip_nectar_maker = Recipe("aip_nectar_maker", {Ingredient("boards", 4), Ingredient("goldnugget", 3), Ingredient("rope", 2)}, RECIPETABS.FARM, TECH.SCIENCE_TWO, "aip_nectar_maker_placer")
aip_nectar_maker.atlas = "images/inventoryimages/aip_nectar_maker.xml"

------------------------------------ 配方 ------------------------------------
local cooking = require("cooking")
local function getItemValue(item)
	local tagVals = {}
	if not item then
		return tagVals
	end

	local ingredient = cooking.ingredients[item.prefab]

	if ingredient and ingredient.tags then
		-- 原料
		tagVals = ingredient.tags
	elseif item:HasTag("aip_nectar_material") then
		-- 标签
		if item:HasTag("frozen") then
			tagVals["frozen"] = 3
		end
		if item:HasTag("honeyed") then
			tagVals["sweetener"] = 3
		end
		if item:HasTag("aip_exquisite") then
			tagVals["exquisite"] = 1
		end
	end

	return tagVals
end

--------------------------------- 花蜜酿造机 ---------------------------------
require "prefabutil"

local assets =
{
	Asset("ANIM", "anim/aip_nectar_maker.zip"),
	Asset("ATLAS", "images/inventoryimages/aip_nectar_maker.xml"),
	Asset("IMAGE", "images/inventoryimages/aip_nectar_maker.tex"),
}

local prefabs =
{
	"collapse_small",
	"aip_nectar",
}

-- 动画+延时
local function startCook(inst, tagVals)
	inst.AnimState:PlayAnimation("cooking", true)

	if inst.task ~= nil then
		inst.task:Cancel()
	end

	inst.making = true
	inst.task = inst:DoTaskInTime(TUNING.AIP_NECTAR_COOKTIME, function()
		inst.AnimState:PlayAnimation("idle", false)
		if inst.components.container then
			inst.components.container.canbeopened = true
			inst.making = false
		end
	end)
end

-- 制造花蜜
local function onMakeNectar(inst, doer)
	local tagVals = {}

	-- 空物品栏就不干事
	if inst.components.container:NumItems() == 0 or inst.making then
		return
	end

	-- 价值分析
	for k, item in pairs (inst.components.container.slots) do
		local itemTagVals = getItemValue(item)

		for tag, tagVal in pairs (itemTagVals) do
			tagVals[tag] = (tagVals[tag] or 0) + tagVal
		end
	end

	-- 清空容器
	inst.components.container.canbeopened = false
	inst.components.container:Close()
	inst.components.container:DestroyContents()

	-- 创造花蜜
	local nectar = SpawnPrefab("aip_nectar")
	nectar.nectarValues = tagVals
	nectar.refreshName()
	inst.components.container:GiveItem(nectar)

	startCook(inst, tagVals)
end

-- 建筑
local function onhammered(inst, worker)
	inst.components.lootdropper:DropLoot()
	local x, y, z = inst.Transform:GetWorldPosition()
	local fx = SpawnPrefab("collapse_small")
	fx.Transform:SetPosition(x, y, z)
	fx:SetMaterial("stone")
	inst:Remove()
end

local function onhit(inst, worker)
	inst.AnimState:PlayAnimation("hit")
	inst.AnimState:PushAnimation("idle")
end

local function onbuilt(inst)
	inst.AnimState:PlayAnimation("place")
	inst.AnimState:PushAnimation("idle", false)
	inst.SoundEmitter:PlaySound("dontstarve/common/chest_craft")
end

local function fn()
	local inst = CreateEntity()
	
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	-- 碰撞体积
	MakeObstaclePhysics(inst, .5)

	-- 动画
	inst.AnimState:SetBank("aip_nectar_maker")
	inst.AnimState:SetBuild("aip_nectar_maker")
	inst.AnimState:PlayAnimation("idle", false)

	-- 标签
	inst:AddTag("structure")

	MakeSnowCoveredPristine(inst)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	-----------------------------------------------------
	inst.making = false
	inst.task = nil
	-----------------------------------------------------

	-- 容器
	inst:AddComponent("container")
	inst.components.container:WidgetSetup("nectar_maker")

	-- 操作
	inst:AddComponent("aipc_action")
	inst.components.aipc_action.onDoAction = onMakeNectar


	-- 掉东西
	inst:AddComponent("lootdropper")

	-- 被锤子
	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
	inst.components.workable:SetWorkLeft(4)
	inst.components.workable:SetOnFinishCallback(onhammered)
	inst.components.workable:SetOnWorkCallback(onhit)

	-- 可作祟
	inst:AddComponent("hauntable")
	inst.components.hauntable.cooldown = TUNING.HAUNT_COOLDOWN_HUGE

	-- 可检查
	inst:AddComponent("inspectable")
	inst:ListenForEvent("onbuilt", onbuilt)

	MakeMediumBurnable(inst)

	return inst
end

return Prefab("aip_nectar_maker", fn, assets, prefabs),
	MakePlacer("aip_nectar_maker_placer", "aip_nectar_maker", "aip_nectar_maker", "idle")