------------------------------------ 配置 ------------------------------------
-- 体验关闭
local additional_experiment = aipGetModConfig("additional_experiment")
if additional_experiment ~= "open" then
	return nil
end

-- 建筑关闭
local additional_building = aipGetModConfig("additional_building")
if additional_building ~= "open" then
	return nil
end

local language = aipGetModConfig("language")

local LANG_MAP = {
	["english"] = {
		["NAME"] = "Woodener",
		["DESC"] = "a shy totem pole",
		["DESCRIBE"] = "You can give, but not ask for.",
	},
	["chinese"] = {
		["NAME"] = "木图腾",
		["DESC"] = "一根害羞的图腾柱",
		["DESCRIBE"] = "你可以给予，却不该索取。",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

-- 文字描述
STRINGS.NAMES.INCINERATOR = LANG.NAME
STRINGS.RECIPE_DESC.INCINERATOR = LANG.DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.INCINERATOR = LANG.DESCRIBE

-- 配方
local incinerator = Recipe("aip_woodener", {Ingredient("rocks", 5), Ingredient("twigs", 2), Ingredient("ash", 1)}, RECIPETABS.LIGHT, TECH.SCIENCE_ONE, "aip_woodener_placer")
incinerator.atlas = "images/inventoryimages/incinerator.xml"

-----------------------------------------------------------------------
require "prefabutil"

local assets =
{
	Asset("ANIM", "anim/incinerator.zip"),
	Asset("ATLAS", "images/inventoryimages/incinerator.xml"),
	Asset("IMAGE", "images/inventoryimages/incinerator.tex"),
}

local prefabs =
{
	"campfirefire",
	"collapse_small",
	"ash",
}

local function onBurnItems(inst)
	local hasItems = false
	local returnItems = {}

	-- 计算生产的物料
	if inst.components.aipc_action and inst.components.container then
		local ings = {}
		for k, item in pairs(inst.components.container.slots) do
			local stackSize = item.components.stackable and item.components.stackable:StackSize() or 1
			local lootItem = "ash"

			-- 根据马头剩余耐久度概率提供谜之声帽
			if item.prefab == "aip_horse_head" and item.components.fueled then
				local ptg = item.components.fueled:GetPercent()
				ptg = ptg * ptg * 0.9
				if ptg >= math.random() then
					lootItem = "aip_som"
				end
			end

			returnItems[lootItem] = (returnItems[lootItem] or 0) + stackSize
			hasItems = true
		end
	end

	-- 掉东西咯
	if hasItems then
		inst.AnimState:PlayAnimation("consume")
		inst.AnimState:PushAnimation("idle", false)
		inst.SoundEmitter:PlaySound("dontstarve/common/fireAddFuel")

		for prefab, prefabCount in pairs(returnItems) do
			local currentCount = prefabCount
			local loot = inst.components.lootdropper:SpawnLootPrefab(prefab)
			local lootMaxSize = 1

			if loot.components.stackable then
				lootMaxSize = loot.components.stackable.maxsize
			end
			loot:Remove()

			-- 批量掉落
			while(currentCount > 0)
			do
				local dropCount = math.min(currentCount, lootMaxSize)
				local dropLootItem = inst.components.lootdropper:SpawnLootPrefab(prefab)
				if dropLootItem.components.stackable then
					dropLootItem.components.stackable:SetStackSize(dropCount)
				end

				currentCount = currentCount - dropCount
			end
		end

		inst.components.container:Close()
		inst.components.container:DestroyContents()

		inst.components.burnable:Extinguish()
		inst:DoTaskInTime(0, function ()
			inst.components.burnable:Ignite()
			inst.components.burnable:SetFXLevel(1)
		end)
	end
end

-- 火焰者
local function onextinguish(inst)
end

-- 建筑
local function onhammered(inst, worker)
	inst.components.lootdropper:DropLoot()
	local x, y, z = inst.Transform:GetWorldPosition()
	SpawnPrefab("ash").Transform:SetPosition(x, y, z)
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
	inst.SoundEmitter:PlaySound("dontstarve/common/fireAddFuel")
end

local function OnInit(inst)
	if inst.components.burnable ~= nil then
		inst.components.burnable:FixFX()
	end
end

local function fn()
	local inst = CreateEntity()
	
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	-- 碰撞体积
	MakeObstaclePhysics(inst, .3)

	-- 动画
	inst.AnimState:SetBank("incinerator")
	inst.AnimState:SetBuild("incinerator")
	inst.AnimState:PlayAnimation("idle", false)

	-- 标签
	inst:AddTag("structure")

	MakeSnowCoveredPristine(inst)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	-- 可燃烧
	inst:AddComponent("burnable")
	inst.components.burnable:AddBurnFX("fire", Vector3(0, 0.3, 0) )
	inst.components.burnable:SetBurnTime(10)
	inst:ListenForEvent("onextinguish", onextinguish)

	-- 容器
	inst:AddComponent("container")
	inst.components.container:WidgetSetup("incinerator")

	-- 烹饪
	inst:AddComponent("aipc_action")
	inst.components.aipc_action.onDoAction = onBurnItems


	-- 掉东西
	inst:AddComponent("lootdropper")

	-- 被锤子
	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
	inst.components.workable:SetWorkLeft(4)
	inst.components.workable:SetOnFinishCallback(onhammered)
	inst.components.workable:SetOnWorkCallback(onhit)

	-- 可伤害
	inst:AddComponent("hauntable")
	inst.components.hauntable.cooldown = TUNING.HAUNT_COOLDOWN_HUGE

	-- 可检查
	inst:AddComponent("inspectable")

	inst:ListenForEvent("onbuilt", onbuilt)
	inst:DoTaskInTime(0, OnInit)

	return inst
end

return Prefab("incinerator", fn, assets, prefabs),
	MakePlacer("incinerator_placer", "incinerator", "incinerator", "idle")