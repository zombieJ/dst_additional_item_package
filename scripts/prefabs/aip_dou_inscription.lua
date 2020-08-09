------------------------------------ 配置 ------------------------------------
-- 雕塑关闭
local additional_chesspieces = aipGetModConfig("additional_chesspieces")
if additional_chesspieces ~= "open" then
	return nil
end

local language = aipGetModConfig("language")

local LANG_MAP = {
	english = {
		aip_dou_fire_inscription = {
			NAME = "铭文",
			REC_DESC = "火元素效果",
			DESC = "用它来进行附魔",
		},
		aip_dou_ice_inscription = {
			NAME = "铭文：火",
			REC_DESC = "附魔火元素",
			DESC = "它能够召唤火元素",
		},
		aip_dou_follow_inscription = {
			NAME = "铭文：追",
			REC_DESC = "使魔法可以追随目标",
			DESC = "使魔法可以追随目标",
		},
		aip_dou_trough_inscription = {
			NAME = "铭文：透",
			REC_DESC = "朝一个方向发射魔法",
			DESC = "朝一个方向发射魔法",
		},
		aip_dou_area_inscription = {
			NAME = "铭文：环",
			REC_DESC = "直接在目标点释放魔法",
			DESC = "直接在目标点释放魔法",
		},
	},
	chinese = {
		aip_dou_fire_inscription = {
			NAME = "铭文：火",
			REC_DESC = "附魔火元素",
			DESC = "它能够召唤火元素",
		},
		aip_dou_ice_inscription = {
			NAME = "铭文：冰",
			REC_DESC = "附魔冰元素",
			DESC = "它能够召唤冰元素",
		},
		aip_dou_follow_inscription = {
			NAME = "铭文：追",
			REC_DESC = "使魔法可以追随目标",
			DESC = "使魔法可以追随目标",
		},
		aip_dou_trough_inscription = {
			NAME = "铭文：透",
			REC_DESC = "朝一个方向发射魔法",
			DESC = "朝一个方向发射魔法",
		},
		aip_dou_area_inscription = {
			NAME = "铭文：环",
			REC_DESC = "直接在目标点释放魔法",
			DESC = "直接在目标点释放魔法",
		},
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

------------------------------------ 元素 ------------------------------------
local IngredientLeafNote = Ingredient("aip_leaf_note", 1, "images/inventoryimages/aip_leaf_note.xml")

local INSCRIPTIONS = {
	aip_dou_fire_inscription =		{ tag = "FIRE",		recipes = { IngredientLeafNote, } },
	aip_dou_ice_inscription =		{ tag = "ICE",		recipes = { IngredientLeafNote, Ingredient("log", 1), } },
	aip_dou_follow_inscription =	{ tag = "FOLLOW",	recipes = { IngredientLeafNote, } },
	aip_dou_trough_inscription =	{ tag = "THROUGH",	recipes = { IngredientLeafNote, } },
	aip_dou_area_inscription =		{ tag = "AREA",		recipes = { IngredientLeafNote, } },
}

------------------------------------ 功能 ------------------------------------
local function makeInscription(name, info)
	-- 资源
	local assets =
	{
		Asset("ATLAS", "images/inventoryimages/aip_dou_opal.xml"),
		Asset("ANIM", "anim/aip_dou_opal.zip"),
	}

	-- 文字
	local upperName = string.upper(name)
	local PREFAB_LANG = LANG[name] or LANG_MAP.english[name]

	STRINGS.NAMES[upperName] = PREFAB_LANG.NAME
	STRINGS.RECIPE_DESC[upperName] = PREFAB_LANG.REC_DESC
	STRINGS.CHARACTERS.GENERIC.DESCRIBE[upperName] = PREFAB_LANG.DESC

	-- 生成配方
	local aip_dou_inscription = Recipe(name, info.recipes, RECIPETABS.AIP_DOU_SCEPTER, TECH.AIP_DOU_SCEPTER_ONE, nil, nil, true)
	aip_dou_inscription.atlas = "images/inventoryimages/aip_dou_opal.xml"
	aip_dou_inscription.image = "aip_dou_opal.tex"

	local function fn()
		local inst = CreateEntity()

		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddNetwork()
		
		MakeInventoryPhysics(inst)

		inst:AddTag("aip_dou_inscription")
		inst._douTag = info.tag

		inst.AnimState:SetBank("aip_dou_opal")
		inst.AnimState:SetBuild("aip_dou_opal")
		inst.AnimState:PlayAnimation("idle")

		MakeInventoryFloatable(inst, "med", 0.1, 0.75)

		inst.entity:SetPristine()

		if not TheWorld.ismastersim then
			return inst
		end

		inst:AddComponent("inspectable")

		inst:AddComponent("inventoryitem")
		inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_dou_opal.xml"
		inst.components.inventoryitem.imagename = "aip_dou_opal"

		MakeSmallBurnable(inst, TUNING.LARGE_BURNTIME)
		MakeSmallPropagator(inst)

		MakeHauntableLaunchAndIgnite(inst)

		return inst
	end

	return Prefab(name, fn, assets)
end

-- 生成配方
local inscriptions = {}

for name, info in pairs(INSCRIPTIONS) do
	table.insert(inscriptions, makeInscription(name, info))
end

return unpack(inscriptions)