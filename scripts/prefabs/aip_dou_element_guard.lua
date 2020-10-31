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
		NAME = "Element Spirit",
		DESC = "Why help me?",
	},
	chinese = {
		NAME = "元素之灵",
		DESC = "为什么帮我？",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

-- 文字描述
STRINGS.NAMES.AIP_DOU_ELEMENT_GUARD = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_DOU_ELEMENT_GUARD = LANG.DESC

---------------------------------- 特效 ----------------------------------
local createEffectVest = require("utils/aip_vest_util").createEffectVest

local function OnEffect(inst, color)
	if inst.entity:IsVisible() then
		local vest = createEffectVest("aip_dou_scepter_projectile", "aip_dou_scepter_projectile", "disappear")
		local rot = PI * 2 * math.random()
		local dist = .8

		local x, y, z = inst.Transform:GetWorldPosition()
		vest.Transform:SetPosition(x + math.sin(rot) * dist, y + 2, z + math.cos(rot) * dist)
		vest.Physics:SetMotorVel(0, -3, 0)
		vest.AnimState:OverrideMultColour(color[1], color[2], color[3], color[4])
	end
end


---------------------------------- 实体 ----------------------------------
local function getFn(buildName, effectColor, light)
	-- 返回函数哦
	local function fn()
		local inst = CreateEntity()

		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddSoundEmitter()
		inst.entity:AddNetwork()

		if light == true then
			inst.entity:AddLight()
			inst.Light:SetIntensity(.75)
			inst.Light:SetColour(200 / 255, 150 / 255, 50 / 255)
			inst.Light:SetFalloff(.5)
			inst.Light:SetRadius(1)
		end

		MakeObstaclePhysics(inst, .1)

		inst.AnimState:SetBank(buildName)
		inst.AnimState:SetBuild(buildName)

		inst.AnimState:PlayAnimation("idle", true)
		-- inst.AnimState:PlayAnimation("place")
		-- inst.AnimState:PushAnimation("idle", true)

		-- 客户端的特效
		if not TheNet:IsDedicated() then
			inst.periodTask = inst:DoPeriodicTask(0.2, OnEffect, nil, effectColor)
		end

		inst.entity:SetPristine()

		if not TheWorld.ismastersim then
			return inst
		end

		inst:AddComponent("inspectable")

		-- 召唤元素存活时间很短
		inst:DoTaskInTime(6, function(inst)
			inst:Remove()
		end)

		return inst
	end

	return fn
end

---------------------------------- 特例 ----------------------------------
local colors = require("utils/aip_scepter_util").colors

local list = {
	{
		name = "aip_dou_element_fire_guard",
		color = colors.FIRE,
		assets = { Asset("ANIM", "anim/aip_dou_element_fire_guard.zip") },
		light = true
	},
	{
		name = "aip_dou_element_ice_guard",
		color = colors.ICE,
		assets = { Asset("ANIM", "anim/aip_dou_element_ice_guard.zip") },
	},
}

local prefabs = {}

for i, data in ipairs(list) do
	table.insert(prefabs, Prefab(data.name, getFn(data.name, data.color, data.light), data.assets))
end

return unpack(prefabs)