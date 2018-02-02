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

local LANG_VALUE_MAP = {
	["english"] = {
		["tasteless"] = "Tasteless",
		["fruit"] = "Fruit",
		["sweetener"] = "Honey",
		["frozen"] = "Frozen",
		["Exquisite"] = "Exquisite",
		["nectar"] = "Mixed",
		["balance"] = "Balance",
		["absolute"] = "absolute",
	},
	["chinese"] = {
		["tasteless"] = "平淡",
		["fruit"] = "果香",
		["sweetener"] = "香甜",
		["frozen"] = "冰镇",
		["exquisite"] = "精酿",
		["nectar"] = "混合",
		["balance"] = "平衡",
		["absolute"] = "纯酿",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english
local LANG_VALUE = LANG_VALUE_MAP[language] or LANG_VALUE_MAP.english

-- 文字描述
STRINGS.NAMES.AIP_NECTAR = LANG.NAME
STRINGS.RECIPE_DESC.AIP_NECTAR = LANG.DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_NECTAR = LANG.DESCRIBE

-----------------------------------------------------------
local BASE_COLOR = .25
local COLOR_WEIGHT = {
	["tasteless"] =		{1.0, 1.0, 1.0, 1.0},
	["fruit"] =			{1.0, 0.1, 0.1, 1.0},
	["sweetener"] =		{0.1, 1.0, 1.0, 1.0},
	["frozen"] =		{1.0, 1.0, 1.0, 0.0},
	["exquisite"] =		{1.0, 1.0, 1.0, 1.0},
	["nectar"] =		{0.1, 0.1, 0.1, 1.0},
}

-----------------------------------------------------------

local assets =
{
	Asset("ANIM", "anim/aip_nectar.zip"),
	Asset("ATLAS", "images/inventoryimages/aip_nectar.xml"),
	Asset("IMAGE", "images/inventoryimages/aip_nectar.tex"),
}

local prefabs = {}

local function onRefreshName(inst)
	local changeColor = 1 - BASE_COLOR

	local name = LANG.NAME
	local nectarValues = inst.nectarValues or {}

	local nectarR = 0
	local nectarG = 0
	local nectarB = 0
	local nectarA = 0

	local topTag = "tasteless"
	local topTagVal = 0
	local totalTagVal = 0
	local tagBalance = false

	for tag, tagVal in pairs (nectarValues) do
		if tag ~= "exquisite" then
			totalTagVal = totalTagVal + tagVal

			-- 选取最高位
			if topTagVal == tagVal then
				tagBalance = true
			elseif topTagVal < tagVal then
				topTag = tag
				topTagVal = tagVal
				tagBalance = false
			end

			-- 颜色统计
			local color = COLOR_WEIGHT[tag]
			nectarR = nectarR + color[1] * tagVal
			nectarG = nectarG + color[2] * tagVal
			nectarB = nectarB + color[3] * tagVal
			nectarA = nectarA + color[4] * tagVal
		end
	end

	inst.AnimState:SetMultColour(
		BASE_COLOR + nectarR / totalTagVal * changeColor,
		BASE_COLOR + nectarG / totalTagVal * changeColor,
		BASE_COLOR + nectarB / totalTagVal * changeColor,
		BASE_COLOR + nectarA / totalTagVal * changeColor
	)

	name = LANG_VALUE[topTag]..name

	-- 精酿
	if nectarValues.exquisite then
		name = LANG_VALUE.exquisite..name
	elseif topTagVal == totalTagVal then
		name = LANG_VALUE.absolute..name
	else
		name = tostring(math.ceil(topTagVal / totalTagVal * 100)).."%"..name
	end

	-- 平衡
	if tagBalance then
		name = LANG_VALUE.balance..name
	end

	inst.components.named:SetName(name)
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
