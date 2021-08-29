require "prefabutil"

local foldername = KnownModIndex:GetModActualName(TUNING.ZOMBIEJ_ADDTIONAL_PACKAGE)

------------------------------------ 配置 ------------------------------------
-- 魔法关闭
local additional_magic = aipGetModConfig("additional_magic")
if additional_magic ~= "open" then
	return nil
end

-- 仅限开发模式
local dev_mode = aipGetModConfig("dev_mode")
if dev_mode ~= "enabled" then
	return nil
end

local language = aipGetModConfig("language")

local LANG_MAP = {
	english = {
		NAME = "Shadow Chest",
		DESC = "Greed collect items",
		DESCRIBE = "It's magic for automation",
	},
	chinese = {
		NAME = "暗影宝箱",
		DESC = "贪婪地收集物品",
		DESCRIBE = "这个魔法正适合自动化",
	},
	russian = {
		NAME = "Теневой сундук",
		DESC = "Жадность собирает предметы",
		DESCRIBE = "Это волшебство для автоматизации",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english
local LANG_ENG = LANG_MAP.english

-- 文字描述
STRINGS.NAMES.AIP_SHADOW_CHEST = LANG.NAME or LANG_ENG.NAME
STRINGS.RECIPE_DESC.AIP_SHADOW_CHEST = LANG.DESC or LANG_ENG.DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_SHADOW_CHEST = LANG.DESCRIBE or LANG_ENG.DESCRIBE

-- 配方
local aip_shadow_chest = Recipe("aip_shadow_chest", {Ingredient("aip_shadow_paper_package", 1, "images/inventoryimages/aip_shadow_paper_package.xml"), Ingredient("boards", 3)}, RECIPETABS.MAGIC, TECH.MAGIC_TWO, "aip_shadow_chest_placer")
aip_shadow_chest.atlas = "images/inventoryimages/aip_shadow_package.xml" -- TODO 修改图标

------------------------------------ 实例 ------------------------------------
local assets =
{
	Asset("ANIM", "anim/treasure_chest.zip"),
	Asset("ANIM", "anim/ui_chest_3x2.zip"),
}

local prefabs = { "collapse_small" }

local function onbuilt(inst)
	inst.AnimState:PlayAnimation("place")
	inst.AnimState:PushAnimation("closed", false)
	inst.SoundEmitter:PlaySound("dontstarve/common/chest_craft")
end

local function onopen(inst)
	if not inst:HasTag("burnt") then
		inst.AnimState:PlayAnimation("open")
		inst.SoundEmitter:PlaySound("dontstarve/wilson/chest_open")
	end
end 

local function onclose(inst)
	if not inst:HasTag("burnt") then
		inst.AnimState:PlayAnimation("close")
		inst.SoundEmitter:PlaySound("dontstarve/wilson/chest_close")
	end
end

local function onsave(inst, data)
	if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() or inst:HasTag("burnt") then
		data.burnt = true
	end
end

local function onload(inst, data)
	if data ~= nil and data.burnt and inst.components.burnable ~= nil then
		inst.components.burnable.onburnt(inst)
	end
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddMiniMapEntity()
	inst.entity:AddNetwork()

	-- MakeObstaclePhysics(inst, .1) 不用碰撞

	inst.MiniMapEntity:SetIcon("treasurechest.png")

	inst:AddTag("structure")
	inst:AddTag("chest")

	inst.AnimState:SetBank("chest")
	inst.AnimState:SetBuild("treasure_chest")
	inst.AnimState:PlayAnimation("closed")

	MakeSnowCoveredPristine(inst)

	inst.entity:SetPristine()

	inst.AnimState:SetMultColour(0, 0, 0, 0.8)

	inst:AddComponent("aipc_info_client")

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("inspectable")
	inst:AddComponent("container")
	inst.components.container:WidgetSetup("aip_shadow_chest")
	inst.components.container.onopenfn = onopen
	inst.components.container.onclosefn = onclose

	--[[if not indestructible then
		inst:AddComponent("lootdropper")
		inst:AddComponent("workable")
		inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
		inst.components.workable:SetWorkLeft(2)
		inst.components.workable:SetOnFinishCallback(onhammered)
		inst.components.workable:SetOnWorkCallback(onhit)

		MakeSmallBurnable(inst, nil, nil, true)
		MakeMediumPropagator(inst)
	end]]

	inst:AddComponent("hauntable")
	inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

	inst:ListenForEvent("onbuilt", onbuilt)
	MakeSnowCovered(inst)

	inst.OnSave = onsaveЖадность собирать предметы
	inst.OnLoad = onload

	return inst
end

return Prefab("aip_shadow_chest", fn, assets, prefabs),
		MakePlacer("aip_shadow_chest_placer", "chest", "treasure_chest", "closed")
