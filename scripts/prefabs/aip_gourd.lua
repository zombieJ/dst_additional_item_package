local dev_mode = aipGetModConfig("dev_mode") == "enabled"

local additional_food = aipGetModConfig("additional_food")
if additional_food ~= "open" then
	return nil
end

local aip_nectar_config = require("prefabs/aip_nectar_config")
local QUALITY_COLORS = aip_nectar_config.QUALITY_COLORS
local LANG_VALUE_MAP = aip_nectar_config.LANG_VALUE_MAP

-- 默认参数
local survival_effect = aipGetModConfig("survival_effect")
local HEAL_MAP = {
	less = .5,
	normal = 1,
	large = 3,
}

local HEAL_VALUES = {
	[0] = -10,
	[1] = 10,
	[2] = 20,
	[3] = 30,
	[4] = 40,
	[5] = 50,
}

local healMulti = HEAL_MAP[survival_effect]

-- 语言
local language = aipGetModConfig("language")
local LANG_MAP = {
	english = {
		LAO_NAME = "Old Gourd",
		LAO_DESC = "Drink a little",
		ZHENGXIANHONG_NAME = "Trailblazer's Scarlet Gourd",
		ZHENGXIANHONG_DESC = "First drink first get",
		WUGUI_NAME = "Plaguebane Gourd",
		WUGUI_DESC = "Garner rich boon with slight bane",
		WUGUI_BUFF = "Painful",
		BAOLIANUI_NAME = "Jade Lotus Gourd",
		BAOLIANUI_DESC = "Not suitable for alone",
		QINGTIAN_NAME = "Qing-Tian Gourd",
		QINGTIAN_DESC = "Heavenly fate is not resentful",
	},
	chinese = {
		LAO_NAME = "老葫芦",
		LAO_DESC = "人间纵有珍羞味，怎比山猴乐更宁？",
		ZHENGXIANHONG_NAME = "争先红葫芦",
		ZHENGXIANHONG_DESC = "强者为尊该让我，英雄只此敢争先",
		WUGUI_NAME = "五鬼葫芦",
		WUGUI_DESC = "杀人一万，自损三千",
		WUGUI_BUFF = "打得生疼",
		BAOLIANUI_NAME = "宝莲玉葫芦",
		BAOLIANUI_DESC = "完名美节，不宜独任",
		QINGTIAN_NAME = "青田葫芦",
		QINGTIAN_DESC = "天命无怨色，人生有素风",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english
local LANG_VALUE = LANG_VALUE_MAP[language] or LANG_VALUE_MAP.english

-- 文字描述
STRINGS.NAMES.AIP_GOURD_LAO = LANG.LAO_NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_GOURD_LAO = LANG.LAO_DESC
STRINGS.NAMES.AIP_GOURD_ZHENGXIANHONG = LANG.ZHENGXIANHONG_NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_GOURD_ZHENGXIANHONG = LANG.ZHENGXIANHONG_DESC
STRINGS.NAMES.AIP_GOURD_WUGUI = LANG.WUGUI_NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_GOURD_WUGUI = LANG.WUGUI_DESC
STRINGS.NAMES.AIP_GOURD_BAOLIANYU = LANG.BAOLIANUI_NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_GOURD_BAOLIANYU = LANG.BAOLIANUI_DESC
STRINGS.NAMES.AIP_GOURD_QINGTIAN = LANG.QINGTIAN_NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_GOURD_QINGTIAN = LANG.QINGTIAN_DESC

------------------------------- 数据 -------------------------------
-- 添加攻击 Buffer
aipBufferRegister("aip_gourd_wugui", {
    name = LANG.WUGUI_BUFF,
    showFX = true,
})

local data = {
	lao = {
		times = 4,
		heal = healMulti,
		wineBonus = 1,
	},

	-- 争先红，第一口满血
	zhengxianhong = {
		times = 5,
		heal = healMulti,
		sanity = -5,
		onEat = function(inst, doer)
			if doer.components.health ~= nil and inst.components.finiteuses:GetPercent() == 1 then
				doer.components.health:SetPercent(1, false, inst.prefab)
			end
		end,
	},

	-- 五鬼
	wugui = {
		times = 5,
		heal = healMulti / 2,
		sanity = -10,
		onEat = function(inst, doer)
			aipBufferPatch(inst, doer, "aip_gourd_wugui", 30)
		end,
	},

	-- 宝莲玉
	baolianyu = {
		times = 6,
		heal = healMulti,
		sanity = -10,
		onEat = function(inst, doer, healVal)
			local pos = doer:GetPosition()
			local ents = TheSim:FindEntities(
				pos.x, 0, pos.z,
				10,
				{ "_combat", "_health" },
				{ "INLIMBO", "NOCLICK", "ghost" }
			)

			for i, v in ipairs(ents) do
				if v ~= doer and v.components.health then
					v.components.health:DoDelta(healVal * 0.5, false, inst.prefab)
					aipSpawnPrefab(v, "farm_plant_happy")
				end
			end
		end,
	},

	-- 青田
	qingtian = {
		times = 1,
		heal = healMulti,
		sanity = -15,
		chargeCD = dev_mode and 5 or 30,
		onCharged = function(inst)
			aipPrint("charged", inst.components.finiteuses:GetUses())
			if inst.components.finiteuses then
				inst.components.finiteuses:SetPercent(1)
			end
		end
	},
}

------------------------------- 存储 -------------------------------
-- 同步状态
local function syncEatable(inst)
	local canEat = inst._aipQuality ~= nil and
		inst.components.finiteuses:GetUses() > 0 and
		inst.components.rechargeable:IsCharged()

	if canEat then
		inst:AddTag("aip_canEat")
	else
		inst:RemoveTag("aip_canEat")
	end

	if inst._aipQuality == nil then
		if inst.components.finiteuses then
			inst.components.finiteuses:SetPercent(0)
		end
	end
end

local function onRefreshName(inst)
	syncEatable(inst)

	if inst._aipQuality == nil then
		return
	end

	local qualityName = "quality_"..inst._aipQuality

	if inst.components.aipc_info_client then
		inst.components.aipc_info_client:SetString("aip_info", LANG_VALUE[qualityName])
		inst.components.aipc_info_client:SetByteArray("aip_info_color", QUALITY_COLORS[qualityName])
	end
end

local function onSave(inst, data)
	data._aipQuality = inst._aipQuality
end

local function onLoad(inst, data)
	if data ~= nil and data._aipQuality then
		inst._aipQuality = data._aipQuality
	end

	onRefreshName(inst)
end

------------------------------- 方法 -------------------------------
-- 添加果饮，如果是酒就额外加一个等级
local function onFueled(inst, item, doer)
	if inst.components.finiteuses ~= nil then
		inst.components.finiteuses:SetPercent(1)
	end

	-- 调配等级，如果是有 wineBouns 则额外添加对应等级
	local nextQuality = item.currentQuality
	local nextBounusQuality = nextQuality + (inst._aipInfo.wineBonus or 0)
	if item.nectarValues.wine and HEAL_VALUES[nextBounusQuality] then
		nextQuality =nextBounusQuality
	end

	-- 取最大值
	inst._aipQuality = math.max(inst._aipQuality or 0, nextQuality)

	onRefreshName(inst)
end

-- 可以吃
local function canBeEat(inst, doer)
	return inst:HasTag("aip_canEat")
end


-- 开始享用
local function onDoEat(inst, doer)
	if
		inst.components.finiteuses == nil or
		inst.components.finiteuses:GetUses() == 0 or
		not inst.components.rechargeable:IsCharged() or
		inst._aipQuality == nil
	then
		return
	end

	-- 如果有 CD 就执行一下
	if inst._aipInfo.chargeCD then
		inst.components.rechargeable:Discharge(inst._aipInfo.chargeCD)
	end

	-- 恢复生命值
	local baseHealVal = HEAL_VALUES[inst._aipQuality] or 0
	local healVal = inst._aipInfo.heal * baseHealVal

	if doer.components.health ~= nil then
		doer.components.health:DoDelta(healVal, false, inst.prefab)
		aipSpawnPrefab(doer, "farm_plant_happy")
	end

	-- 是否掉理智
	if doer.components.sanity and inst._aipInfo.sanity then
		doer.components.sanity:DoDelta(inst._aipInfo.sanity)
	end

	if inst._aipInfo.onEat then
		inst._aipInfo.onEat(inst, doer, healVal)
	end

	inst.components.finiteuses:Use()
	syncEatable(inst)
end

-------------------------------- 充能 --------------------------------
local function onCharged(inst)
	aipPrint("charged", inst._aipInfo.onCharged~=nil)
	if inst._aipInfo.onCharged then
		inst._aipInfo.onCharged(inst)
	end

	syncEatable(inst)
end

-- 添加到展台就自动恢复，我们不用清理，因为老的会删除并重新创建一个复制品
local function onShowCase(inst, data)
	local animName = aipGet(data, "showcase|_aipAnim")
	if animName == "stone_lotus" or animName == "ice_lotus" then
		aipSpawnPrefab(inst, "farm_plant_happy")
	end
end

------------------------------- 实体 -------------------------------
local function commonFn(name, info)
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)
	MakeInventoryFloatable(inst, "small", 0.1, 1)

	inst.AnimState:SetBank("aip_gourd")
	inst.AnimState:SetBuild("aip_gourd")
	inst.AnimState:PlayAnimation(name)

	inst.entity:SetPristine()

	inst:AddComponent("aipc_action_client")
	inst.components.aipc_action_client.canBeEat = canBeEat

	-- 双端通用的匹配
	inst:AddComponent("aipc_fueled")
	inst.components.aipc_fueled.prefab = "aip_nectar"
	inst.components.aipc_fueled.onFueled = onFueled

	-- 额外信息
	inst:AddComponent("aipc_info_client")
	inst.components.aipc_info_client:SetString("aip_info", nil, true)
	inst.components.aipc_info_client:SetByteArray("aip_info_color", nil, true)

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("finiteuses")
	inst.components.finiteuses:SetMaxUses(info.times)
	inst.components.finiteuses:SetUses(info.times)

	inst:AddComponent("rechargeable")
	inst.components.rechargeable:SetOnChargedFn(onCharged)

	inst:AddComponent("aipc_action")
	inst.components.aipc_action.onDoAction = onDoEat

	inst:AddComponent("inspectable")

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_gourd_"..name..".xml"

	MakeHauntableLaunch(inst)

	inst._aipInfo = info

	inst:ListenForEvent("aipInShowcase", onShowCase)

	inst.OnSave = onSave
	inst.OnLoad = onLoad

	inst:DoTaskInTime(0.1, onRefreshName)

	return inst
end

------------------------------- 遍历 -------------------------------
local prefabs = {}

for name, info in pairs(data) do
	local fullName = "aip_gourd_"..name

	local assets = {
		Asset("ANIM", "anim/aip_gourd.zip"),
		Asset("ATLAS", "images/inventoryimages/"..fullName..".xml"),
	}

	local function fn()
		local inst = commonFn(name, info)
		return inst
	end

	table.insert(prefabs, Prefab(fullName, fn, assets))
end

return unpack(prefabs)