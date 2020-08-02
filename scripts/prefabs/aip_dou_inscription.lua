------------------------------------ 配置 ------------------------------------
-- 雕塑关闭
local additional_chesspieces = aipGetModConfig("additional_chesspieces")
if additional_chesspieces ~= "open" then
	return nil
end

local language = aipGetModConfig("language")

local LANG_MAP = {
	["english"] = {
		["NAME"] = "Inscription",
		["REC_DESC"] = "Alien from the sky",
		["DESC"] = "Decorate your Walking Cane",
	},
	["chinese"] = {
		["NAME"] = "铭文",
		["REC_DESC"] = "火元素效果",
		["DESC"] = "用它来进行附魔",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

-- 资源
local assets =
{
	Asset("ATLAS", "images/inventoryimages/aip_dou_opal.xml"),
	Asset("ANIM", "anim/aip_dou_opal.zip"),
}

local prefabs =
{
}

-- 文字描述
STRINGS.NAMES.AIP_DOU_INSCRIPTION = LANG.NAME
STRINGS.RECIPE_DESC.AIP_DOU_INSCRIPTION = LANG.REC_DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_DOU_INSCRIPTION = LANG.DESC

------------------------------------ 配方 ------------------------------------
local aip_dou_inscription = Recipe("aip_dou_inscription", {Ingredient("log", 1)}, RECIPETABS.AIP_DOU_SCEPTER, TECH.AIP_DOU_SCEPTER_ONE, nil, nil, true)
aip_dou_inscription.atlas = "images/inventoryimages/aip_dou_opal.xml"
aip_dou_inscription.image = "aip_dou_opal.tex"

------------------------------------ 功能 ------------------------------------
function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()
	
	MakeInventoryPhysics(inst)

	inst.AnimState:SetBank("aip_dou_opal")
	inst.AnimState:SetBuild("aip_dou_opal")
	inst.AnimState:PlayAnimation("idle")

	MakeInventoryFloatable(inst, "med", 0.1, 0.75)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	-- 如果被雷击
	inst:AddComponent("inspectable")

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_dou_opal.xml"
	inst.components.inventoryitem.imagename = "aip_dou_opal"

	MakeSmallBurnable(inst, TUNING.LARGE_BURNTIME)
	MakeSmallPropagator(inst)

	MakeHauntableLaunchAndIgnite(inst)

	return inst
end

return Prefab("aip_dou_inscription", fn, assets, prefabs)
