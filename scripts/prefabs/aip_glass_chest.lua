-- 配置
local additional_building = aipGetModConfig("additional_building")
if additional_building ~= "open" then
	return nil
end

local language = aipGetModConfig("language")

local LANG_MAP = {
	english = {
		NAME = "Jade Chest",
		RECDESC = "Boxes that share items and will also steal items from nearby lureplant when opened",
		DESC = "They seem to be a unity",
		DISABLED = "Some chest is opened by other player",
	},
	chinese = {
		NAME = "翡翠箱",
		RECDESC = "共享物品的箱子，打开时也会窃取附近食人花中的物品。",
		DESC = "它们似乎是一个整体",
		DISABLED = "有玩家正在使用这套箱子",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

-- 文字描述
STRINGS.NAMES.AIP_GLASS_CHEST = LANG.NAME
STRINGS.RECIPE_DESC.AIP_GLASS_CHEST = LANG.RECDESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_GLASS_CHEST = LANG.DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_GLASS_CHEST_DISABLED = LANG.DISABLED

-- 配方
local aip_glass_chest = Recipe("aip_glass_chest", {Ingredient("log", 1)}, RECIPETABS.MAGIC, TECH.MAGIC_TWO, "aip_glass_chest_placer")
aip_glass_chest.atlas = "images/inventoryimages/aip_glass_chest.xml"

---------------------------------- 资源 ----------------------------------
require "prefabutil"

local assets = {
	Asset("ANIM", "anim/aip_glass_chest.zip"),
	Asset("ATLAS", "images/inventoryimages/aip_glass_chest.xml"),
}

local prefabs = {}

---------------------------------- 事件 ----------------------------------
local function onopen(inst)
	inst.AnimState:PlayAnimation("open")
	inst.SoundEmitter:PlaySound("dontstarve/wilson/chest_open")

	inst.components.aipc_unity_container:LockOthers()
end

local function onclose(inst)
	inst.AnimState:PlayAnimation("close")
	inst.AnimState:PushAnimation("closed", false)
	inst.SoundEmitter:PlaySound("dontstarve/wilson/chest_close")

	inst.components.aipc_unity_container:UnlockOthers()
end

local function onhammered(inst, worker)
	inst.components.lootdropper:DropLoot()
	if inst.components.container ~= nil then
		inst.components.container:DropEverything()
	end
	local fx = SpawnPrefab("collapse_small")
	fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
	fx:SetMaterial("wood")
	inst:Remove()
end

local function onhit(inst, worker)
	inst.AnimState:PlayAnimation("hit")
	inst.AnimState:PushAnimation("closed", false)
	if inst.components.container ~= nil then
		inst.components.container:DropEverything()
		inst.components.container:Close()
	end

	inst.components.aipc_unity_container:UnlockOthers()
end

local function onbuilt(inst)
	inst.AnimState:PlayAnimation("place")
	inst.AnimState:PushAnimation("closed", false)
	inst.SoundEmitter:PlaySound("dontstarve/common/chest_craft")
end

---------------------------------- 实体 ----------------------------------
local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddMiniMapEntity()
	inst.entity:AddNetwork()

	inst.MiniMapEntity:SetIcon("treasurechest.png")

	inst:AddTag("structure")
	inst:AddTag("chest")

	inst.AnimState:SetBank("aip_glass_chest")
	inst.AnimState:SetBuild("aip_glass_chest")
	inst.AnimState:PlayAnimation("closed")

	MakeSnowCoveredPristine(inst)
	
	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("inspectable")

	inst:AddComponent("container")
	inst.components.container:WidgetSetup("aip_glass_chest")
	inst.components.container.onopenfn = onopen
	inst.components.container.onclosefn = onclose
	inst.components.container.skipclosesnd = true
	inst.components.container.skipopensnd = true
	inst.components.container.canbeopened = true

	inst:AddComponent("aipc_unity_container")

	inst:AddComponent("lootdropper")

	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
	inst.components.workable:SetWorkLeft(2)
	inst.components.workable:SetOnFinishCallback(onhammered)
	inst.components.workable:SetOnWorkCallback(onhit)

	inst:AddComponent("hauntable")
	inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

	inst:ListenForEvent("onbuilt", onbuilt)
	MakeSnowCovered(inst)

	return inst
end

return Prefab("aip_glass_chest", fn, assets, prefabs),
	MakePlacer("aip_glass_chest_placer", "aip_glass_chest", "aip_glass_chest", "closed")