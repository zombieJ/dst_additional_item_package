local foldername = KnownModIndex:GetModActualName(TUNING.ZOMBIEJ_ADDTIONAL_PACKAGE)

------------------------------------ 配置 ------------------------------------
-- 建筑关闭
local additional_building = GetModConfigData("additional_building", foldername)
if additional_building ~= "open" then
	return nil
end

local language = GetModConfigData("language", foldername)

local function RGB(r, g, b, a)
	return { r / 255, g / 255, b / 255, (a or 255) / 255 }
end

local QUALITY_COLORS = {
	quality_0 = RGB(165,  42,  42),
	quality_1 = nil,
	quality_2 = RGB( 59, 222,  99),
	quality_3 = RGB( 80, 143, 244),
	quality_4 = RGB(128,   0, 128),
	quality_5 = RGB(208, 120,  86),
}

local LANG_MAP = {
	["english"] = {
		["NAME"] = "Nectar",
		["DESC"] = "Made by nectar maker",
		["DESCRIBE"] = "Smell wonderful",

		["contains"] = "Contains",
		["littleOf"] = "Little of",
		["lotsOf"] = "Lots of",
		["fullOf"] = "Full of",
		
		["health"] = "Health",
		["hunger"] = "Hunger",
		["sanity"] = "Sanity",
	},
	["chinese"] = {
		["NAME"] = "花蜜饮",
		["DESC"] = "由花蜜制造机制作",
		["DESCRIBE"] = "有种独特的香气",

		["contains"] = "含有",
		["littleOf"] = "少量的",
		["lotsOf"] = "富含",
		["fullOf"] = "充满了",

		["health"] = "生命力",
		["hunger"] = "饱腹欲",
		["sanity"] = "理智",
	},
}

local LANG_VALUE_MAP = {
	["english"] = {
		["fruit"] = "Fruit",
		["sweetener"] = "Honey",
		["frozen"] = "Frozen",
		["Exquisite"] = "Exquisite",
		["nectar"] = "Mixed",

		["tasteless"] = "Tasteless",
		["balance"] = "Balance",
		["absolute"] = "Absolute",
		["impurity"] = "Impurity",
		["generation"] = "L",

		quality_0 = "Bad Quality",
		quality_1 = "Normal Quality",
		quality_2 = "Nice Quality",
		quality_3 = "Great Quality",
		quality_4 = "Outstanding Quality",
		quality_5 = "Perfect Quality",
	},
	["chinese"] = {
		["fruit"] = "果香",
		["sweetener"] = "香甜",
		["frozen"] = "冰镇",
		["exquisite"] = "精酿",
		["nectar"] = "混合",

		["tasteless"] = "平淡",
		["balance"] = "平衡",
		["absolute"] = "极纯",
		["impurity"] = "混杂",
		["generation"] = "代",

		quality_0 = "糟糕品质",
		quality_1 = "普通品质",
		quality_2 = "良好品质",
		quality_3 = "优秀品质",
		quality_4 = "杰出品质",
		quality_5 = "完美品质",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english
local LANG_VALUE = LANG_VALUE_MAP[language] or LANG_VALUE_MAP.english

-- 文字描述
STRINGS.NAMES.AIP_NECTAR = LANG.NAME
STRINGS.RECIPE_DESC.AIP_NECTAR = LANG.DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_NECTAR = LANG.DESCRIBE

-----------------------------------------------------------
local HP = TUNING.HEALING_TINY -- 1 healing
local HU = TUNING.CALORIES_HUGE / 75 -- 1 hunger
local SAN = TUNING.SANITY_SUPERTINY -- 1 sanity
local PER = TUNING.PERISH_ONE_DAY -- 1 day
local TT = TUNING.FOOD_TEMP_AVERAGE / 10 -- 1 second

local BASE_COLOR = .25
local GENERATION_AFFECT = .95

local VALUE_WEIGHT = {
	["fruit"] =			{1.0, 0.1, 0.1, 1.0},
	["sweetener"] =		{0.1, 1.0, 1.0, 1.0},
	["frozen"] =		{1.0, 1.0, 1.0, 0.0},
	["exquisite"] =		{1.0, 1.0, 1.0, 1.0},
	["nectar"] =		{0.1, 0.1, 0.1, 1.0},
	
	["tasteless"] =		{1.0, 1.0, 1.0, 1.0},
	["balance"] =		{1.0, 1.0, 1.0, 1.0},
	["absolute"] =		{1.0, 1.0, 1.0, 1.0},
	["generation"] =	{1.0, 1.0, 1.0, 1.0},
}

local VALUE_EAT_BONUS = {
	["fruit"] = {
		health = HP * 5,
		hunger = HU * 5,
		sanity = SAN * 5,
	},
	["sweetener"] = {
		health = HP * 10,
		hunger = HU * 2,
		sanity = SAN * 0,
	},
	["frozen"] = {
		health = HP * 0,
		hunger = HU * 0,
		sanity = SAN * 5,
		temperature = TUNING.COLD_FOOD_BONUS_TEMP,
		temperatureduration = TT * 2,
	},
	["exquisite"] = {
		health = HP * 0,
		hunger = HU * 0,
		sanity = SAN * 10,
	},
	["nectar"] = {
		health = HP * 0,
		hunger = HU * 5,
		sanity = SAN * 0,
	},
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

	-- 颜色
	local nectarR = 0
	local nectarG = 0
	local nectarB = 0
	local nectarA = 0

	-- 食物
	local health = 0
	local hunger = 0
	local sanity = 0
	local temperature = 0
	local temperatureduration = 0

	--------------- 配比统计 ---------------
	local topTag = "tasteless"
	local topTagVal = 0
	local totalTagVal = 0
	local tagBalance = false

	for tag, tagVal in pairs (nectarValues) do
		if tag ~= "exquisite" and tag ~= "generation" then
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
			local color = VALUE_WEIGHT[tag] or {1,1,1,1}
			nectarR = nectarR + color[1] * tagVal
			nectarG = nectarG + color[2] * tagVal
			nectarB = nectarB + color[3] * tagVal
			nectarA = nectarA + color[4] * tagVal

			-- 食物统计
			local eatBonus = VALUE_EAT_BONUS[tag] or {}
			health = health + (eatBonus.health or 0) * tagVal
			hunger = hunger + (eatBonus.hunger or 0) * tagVal
			sanity = sanity + (eatBonus.sanity or 0) * tagVal
			temperatureduration = temperatureduration + (eatBonus.temperatureduration or 0)

			if eatBonus.temperature then
				temperature = eatBonus.temperature
			end
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
	end

	-- 平衡
	if tagBalance then
		name = LANG_VALUE.balance..name
	end

	-- 世代
	if nectarValues.generation > 1 then
		name = name..tostring(nectarValues.generation)..LANG_VALUE.generation
	end

	inst.components.named:SetName(name)

	-------------- 浮动提示框 --------------
	-- 纯度
	local aipInfo = ""
	local purePTG = topTagVal / totalTagVal
	if topTagVal == totalTagVal then
		aipInfo = aipInfo..LANG_VALUE.absolute
	elseif purePTG < 0.5 then
		aipInfo = aipInfo..LANG_VALUE.impurity
	else
		aipInfo = tostring(math.ceil(purePTG * 100)).."%"
	end

	-- 品质范围
	local currentQuality = 1.5
	local minQuality = 1
	local maxQuality = 1

	--> 随着世代增加，最高品质也会增加
	if nectarValues.generation <= 1 then
		minQuality = 1
		maxQuality = 2
	elseif nectarValues.generation <= 2 then
		minQuality = 0
		maxQuality = 3
	elseif nectarValues.generation <= 3 then
		minQuality = 0
		maxQuality = 4
	elseif nectarValues.generation <= 4 then
		minQuality = 0
		maxQuality = 5
	end

	-- 品质计算
	--> 纯度
	if purePTG <= 0.3 then
		currentQuality = currentQuality - 0.3
	elseif purePTG <= 0.4 then
		currentQuality = currentQuality - 0.2
	elseif purePTG <= 0.5 then
		currentQuality = currentQuality - 0.1
	elseif purePTG > 0.8 then
		currentQuality = currentQuality + 0.3
	end

	--> 精酿
	if nectarValues.exquisite then
		currentQuality  = currentQuality + 1
	end

	--> 世代
	currentQuality  = currentQuality + (nectarValues.generation or 1) * 0.2

	currentQuality = math.min(maxQuality, currentQuality)
	currentQuality = math.max(minQuality, currentQuality)
	currentQuality = math.floor(currentQuality)
	local qualityName = "quality_"..tostring(currentQuality)
	
	inst._aip_info = "["..aipInfo.." - "..LANG_VALUE[qualityName].."]"
	inst._aip_info_color = QUALITY_COLORS[qualityName]

	--------------- 食用价值 ---------------
	health = health * math.floor(math.pow(GENERATION_AFFECT, (nectarValues.generation or 1) - 1))
	hunger = hunger * math.floor(math.pow(GENERATION_AFFECT, (nectarValues.generation or 1) - 1))
	sanity = sanity * math.floor(math.pow(GENERATION_AFFECT, (nectarValues.generation or 1) - 1))

	if inst.components.edible then
		inst.components.edible.healthvalue = health
		inst.components.edible.hungervalue = hunger
		inst.components.edible.sanityvalue = sanity
		inst.components.edible.temperaturedelta = temperature
		inst.components.edible.temperatureduration = temperatureduration
		-- inst.components.edible:SetOnEatenFn(data.oneatenfn)
	end

	----------------- 检查 -----------------
	local topEatName = "health"
	local topEatValue = health
	local eatData = {
		["health"] = health,
		["hunger"] = hunger,
		["sanity"] = sanity,
	}
	for eatName, eatValue in pairs(eatData) do
		if eatValue > topEatValue then
			topEatName = eatName
			topEatValue = eatValue
		end
	end

	local checkStatus = ""
	if topEatValue <= 10 then
		checkStatus = LANG.littleOf
	elseif topEatValue <= 30 then
		checkStatus = LANG.contains
	elseif topEatValue <= 60 then
		checkStatus = LANG.lotsOf
	else
		checkStatus = LANG.fullOf
	end


	inst.components.inspectable:SetDescription(
		STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_NECTAR.."\n"..
		checkStatus.." "..LANG[topEatName]
	)
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

	-- 食物
	inst:AddComponent("edible")
	inst.components.edible.foodtype = FOODTYPE.MEAT -- 女武神也可以喝
	inst.components.edible.healthvalue = 0
	inst.components.edible.hungervalue = 0
	inst.components.edible.sanityvalue = 0

	MakeHauntableLaunch(inst)

	inst.OnSave = onSave 
	inst.OnLoad = onLoad

	return inst
end

return Prefab("aip_nectar", fn, assets) 
