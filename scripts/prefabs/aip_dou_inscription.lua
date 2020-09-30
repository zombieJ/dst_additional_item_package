-- 公测开启
local open_beta = aipGetModConfig("open_beta")
if open_beta ~= "open" then
	return nil
end

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
			NAME = "Element: Fire",
			DESC = "40% chance to ignite the target",
		},
		aip_dou_ice_inscription = {
			NAME = "Element: Ice",
			DESC = "Freeze the target",
		},
		aip_dou_sand_inscription = {
			NAME = "Element: Sand",
			DESC = "Summon sand pillar",
		},
		aip_dou_heal_inscription = {
			NAME = "Element: Heal",
			DESC = "Heal the target",
		},
		aip_dou_follow_inscription = {
			NAME = "Inscription: Follow",
			DESC = "Your magic can follow target",
		},
		aip_dou_through_inscription = {
			NAME = "Inscription: Through",
			DESC = "Fire a throughable magic",
		},
		aip_dou_area_inscription = {
			NAME = "Inscription: Area",
			DESC = "Effect on a area",
		},
		aip_dou_split_inscription = {
			NAME = "Enchant: Split",
			DESC = "Split your magic",
		},
	},
	chinese = {
		aip_dou_fire_inscription = {
			NAME = "元素：火",
			DESC = "有 40% 概率点燃目标",
		},
		aip_dou_ice_inscription = {
			NAME = "元素：冰",
			DESC = "降低目标温度以冰冻目标",
		},
		aip_dou_sand_inscription = {
			NAME = "元素：沙",
			DESC = "命中时产生一根沙柱",
		},
		aip_dou_heal_inscription = {
			NAME = "元素：春",
			DESC = "生效时治疗目标",
		},
		aip_dou_follow_inscription = {
			NAME = "铭文：追",
			DESC = "使魔法可以追随目标",
		},
		aip_dou_through_inscription = {
			NAME = "铭文：透",
			DESC = "朝一个方向发射魔法",
		},
		aip_dou_area_inscription = {
			NAME = "铭文：环",
			DESC = "直接在目标点释放魔法",
		},
		aip_dou_split_inscription = {
			NAME = "附魔：裂",
			DESC = "分裂你的魔法",
		},
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

------------------------------------ 元素 ------------------------------------
local IngredientLeafNote = Ingredient("aip_leaf_note", 1, "images/inventoryimages/aip_leaf_note.xml")

local INSCRIPTIONS = {
	aip_dou_fire_inscription =		{ tag = "FIRE",		recipes = { IngredientLeafNote, Ingredient("log", 1), } },
	aip_dou_ice_inscription =		{ tag = "ICE",		recipes = { IngredientLeafNote, Ingredient("log", 1), } },
	aip_dou_sand_inscription =		{ tag = "SAND",		recipes = { IngredientLeafNote, Ingredient("log", 1), } },
	aip_dou_heal_inscription =		{ tag = "HEAL",		recipes = { IngredientLeafNote, Ingredient("log", 1), } },
	aip_dou_follow_inscription =	{ tag = "FOLLOW",	recipes = { IngredientLeafNote, Ingredient("log", 1), } },
	aip_dou_through_inscription =	{ tag = "THROUGH",	recipes = { IngredientLeafNote, Ingredient("log", 1), } },
	aip_dou_area_inscription =		{ tag = "AREA",		recipes = { IngredientLeafNote, Ingredient("log", 1), } },
	aip_dou_split_inscription =		{ tag = "SPLIT",	recipes = { IngredientLeafNote, Ingredient("log", 1), } },
}

------------------------------------ 功能 ------------------------------------
local function makeInscription(name, info)
	-- 资源
	local assets =
	{
		Asset("ATLAS", "images/inventoryimages/"..name..".xml"),
		-- Asset("ATLAS", "images/inventoryimages/aip_dou_fire_inscription.xml"),
		Asset("ANIM", "anim/aip_dou_inscription.zip"),
	}

	-- 文字
	local upperName = string.upper(name)
	local PREFAB_LANG = LANG[name] or LANG_MAP.english[name]

	STRINGS.NAMES[upperName] = PREFAB_LANG.NAME
	STRINGS.RECIPE_DESC[upperName] = PREFAB_LANG.DESC
	STRINGS.CHARACTERS.GENERIC.DESCRIBE[upperName] = PREFAB_LANG.DESC

	-- 生成配方
	local aip_dou_inscription = Recipe(name, info.recipes, RECIPETABS.AIP_DOU_SCEPTER, TECH.AIP_DOU_SCEPTER_ONE, nil, nil, true)
	aip_dou_inscription.atlas = "images/inventoryimages/"..name..".xml"
	aip_dou_inscription.image = name..".tex"
	-- aip_dou_inscription.atlas = "images/inventoryimages/aip_dou_fire_inscription.xml"
	-- aip_dou_inscription.image = "aip_dou_fire_inscription.tex"

	local function fn()
		local inst = CreateEntity()

		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddNetwork()
		
		MakeInventoryPhysics(inst)

		inst:AddTag("aip_dou_inscription")
		inst._douTag = info.tag

		inst.AnimState:SetBank("aip_dou_inscription")
		inst.AnimState:SetBuild("aip_dou_inscription")
		inst.AnimState:PlayAnimation("idle")

		MakeInventoryFloatable(inst, "med", 0.1, 0.75)

		inst.entity:SetPristine()

		if not TheWorld.ismastersim then
			return inst
		end

		inst:AddComponent("inspectable")

		inst:AddComponent("inventoryitem")
		inst.components.inventoryitem.atlasname = "images/inventoryimages/"..name..".xml"
		inst.components.inventoryitem.imagename = name
		-- inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_dou_fire_inscription.xml"
		-- inst.components.inventoryitem.imagename = "aip_dou_fire_inscription"

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