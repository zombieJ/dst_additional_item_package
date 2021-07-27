require "prefabutil"

local foldername = KnownModIndex:GetModActualName(TUNING.ZOMBIEJ_ADDTIONAL_PACKAGE)

------------------------------------ 配置 ------------------------------------
-- 魔法关闭
local additional_magic = aipGetModConfig("additional_magic")
if additional_magic ~= "open" then
	return nil
end

local language = aipGetModConfig("language")

local LANG_MAP = {
	english = {
		NAME = "Shadow Chest",
		DESC = "Pick item on the group or other shadow chest",
		DESCRIBE = "It's magic for automation",
	},
	chinese = {
		NAME = "暗影宝箱",
		DESC = "可以获取地上和其他暗影宝箱内的物品",
		DESCRIBE = "这个魔法正适合自动化",
	},
	russian = {
		NAME = "Теневой сундук",
		DESC = "Поднимает предметы стаками или из другого теневого сундука",
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
local aip_shadow_chest = Recipe("aip_shadow_chest", {Ingredient("boards", 3), Ingredient("aip_shadow_paper_package", 1, "images/inventoryimages/frozen_heart.xml")}, RECIPETABS.MAGIC, TECH.MAGIC_TWO)
aip_shadow_chest.atlas = "images/inventoryimages/aip_shadow_chest.xml"

-----------------------------------------------------------
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

local function onhammered(inst, worker)
	if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
		inst.components.burnable:Extinguish()
	end
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
	if not inst:HasTag("burnt") then
		inst.AnimState:PlayAnimation("hit")
		inst.AnimState:PushAnimation("closed", false)
		if inst.components.container ~= nil then
			inst.components.container:DropEverything()
			inst.components.container:Close()
		end
	end
end

local function onbuilt(inst)
	inst.AnimState:PlayAnimation("place")
	inst.AnimState:PushAnimation("closed", false)
	inst.SoundEmitter:PlaySound("dontstarve/common/chest_craft")
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

local function MakeChest(name, custom_postinit, prefabs)
	local assets =
	{
		Asset("ATLAS", "images/inventoryimages/"..name..".xml"),
		Asset("ANIM", "anim/"..name..".zip"),
		Asset("ANIM", "anim/ui_chest_3x2.zip"),
	}

	local function fn()
		local inst = CreateEntity()

		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddSoundEmitter()
		inst.entity:AddMiniMapEntity()
		inst.entity:AddNetwork()

		-- TODO: Draw a map icon
		inst.MiniMapEntity:SetIcon(name..".png")

		inst:AddTag("structure")
		inst:AddTag("chest")

		inst.AnimState:SetBank(name)
		inst.AnimState:SetBuild(name)
		inst.AnimState:PlayAnimation("closed")

		MakeSnowCoveredPristine(inst)

		inst.entity:SetPristine()

		if not TheWorld.ismastersim then
			return inst
		end

		inst:AddComponent("inspectable")
		inst:AddComponent("container")
		inst.components.container:WidgetSetup("treasurechest")
		inst.components.container.onopenfn = onopen
		inst.components.container.onclosefn = onclose

		inst:AddComponent("lootdropper")
		inst:AddComponent("workable")
		inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
		inst.components.workable:SetWorkLeft(3)
		inst.components.workable:SetOnFinishCallback(onhammered)
		inst.components.workable:SetOnWorkCallback(onhit)

		MakeSmallBurnable(inst, nil, nil, true)
		MakeMediumPropagator(inst)

		inst:AddComponent("hauntable")
		inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

		inst:ListenForEvent("onbuilt", onbuilt)
		MakeSnowCovered(inst)

		inst.OnSave = onsave 
		inst.OnLoad = onload

		if custom_postinit ~= nil then
			custom_postinit(inst)
		end

		return inst
	end

	return Prefab(name, fn, assets, prefabs)
end

return MakeChest("aip_shadow_chest", nil, { "collapse_small" }),
		MakePlacer("aip_shadow_chest_placer", "chest", "aip_shadow_chest", "closed")
