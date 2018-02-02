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
		["NAME"] = "Nectar",
		["DESC"] = "Made by nectar maker",
		["DESCRIBE"] = "Smell wonderful",
	},
	["chinese"] = {
		["NAME"] = "花蜜饮",
		["DESC"] = "由花蜜制造机制作",
		["DESCRIBE"] = "有种独特的香气",
	},
}

local LANG_RECIPE = {
	["english"] = {
		["tasteless"] = "Tasteless",
		["fruit"] = "Fruit",
		["sweetener"] = "Honey",
		["frozen"] = "Frozen",
		["Exquisite"] = "Exquisite",
	},
	["chinese"] = {
		["tasteless"] = "平淡",
		["fruit"] = "果香",
		["sweetener"] = "甜蜜",
		["frozen"] = "冰镇",
		["exquisite"] = "精酿",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

-- 文字描述
STRINGS.NAMES.AIP_NECTAR = LANG.NAME
STRINGS.RECIPE_DESC.AIP_NECTAR = LANG.DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_NECTAR = LANG.DESCRIBE

-----------------------------------------------------------


-----------------------------------------------------------

local assets =
{
	Asset("ANIM", "anim/aip_nectar.zip"),
	Asset("ATLAS", "images/inventoryimages/aip_nectar.xml"),
	Asset("IMAGE", "images/inventoryimages/aip_nectar.tex"),
}

local prefabs = {}

local function onRefreshName(inst)
	inst.components.named:SetName(LANG.NAME)
end

-- 存储
local function onSave(inst, data)
	data.nectarValues = inst.nectarValues
end

local function onLoad(inst, data)
	if data ~= nil and data.nectarValues then
		inst.nectarValues = data.nectarValues
		inst.refreshName()
	end
end

function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)

	inst.AnimState:SetBank("aip_nectar")
	inst.AnimState:SetBuild("aip_nectar")
	inst.AnimState:PlayAnimation("BUILD")

	inst:AddTag("aip_nectar")
	inst:AddTag("aip_nectar_material")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	-----------------------------------------------------
	inst.nectarValues = {}
	inst.refreshName = function()
		onRefreshName(inst)
	end
	-----------------------------------------------------

	inst:AddComponent("named")

	inst:AddComponent("inspectable")

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_nectar.xml"

	MakeHauntableLaunch(inst)

	inst.OnSave = onSave 
	inst.OnLoad = onLoad

	return inst
end

return Prefab("aip_nectar", fn, assets) 
