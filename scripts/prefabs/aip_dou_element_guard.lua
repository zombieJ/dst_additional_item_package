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
local colors = require("utils/aip_scepter_util").colors

local function getFn(data)
	-- 返回函数哦
	local function fn()
		local inst = CreateEntity()

		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddSoundEmitter()
		inst.entity:AddNetwork()

		if data.preFn ~= nil then
			data.preFn(inst)
		end

		MakeObstaclePhysics(inst, .1)

		inst.AnimState:SetBank(data.name)
		inst.AnimState:SetBuild(data.name)

		inst.AnimState:PlayAnimation("idle", true)
		-- inst.AnimState:PlayAnimation("place")
		-- inst.AnimState:PushAnimation("idle", true)

		local scale = data.scale or 1
		inst.Transform:SetScale(scale, scale, scale)

		-- 客户端的特效
		if not TheNet:IsDedicated() then
			inst.periodTask = inst:DoPeriodicTask(0.2, OnEffect, nil, data.color or colors._default)
		end

		inst.entity:SetPristine()

		if not TheWorld.ismastersim then
			return inst
		end

		inst:AddComponent("inspectable")

		if data.postFn ~= nil then
			data.postFn(inst)
		end

		-- 召唤元素存活时间很短
		inst:DoTaskInTime(data.duration or 7, function(inst)
			local effect = SpawnPrefab("collapse_small")
			effect.Transform:SetPosition(inst.Transform:GetWorldPosition())

			inst:Remove()
		end)

		if data.spawnPrefab ~= nil then
			inst:DoTaskInTime(0.01, function()
				local effect = SpawnPrefab(data.spawnPrefab)
				effect.Transform:SetPosition(inst.Transform:GetWorldPosition())
			end)
		end

		return inst
	end

	return fn
end

---------------------------------- 特例 ----------------------------------
local list = {
	{	-- 火焰守卫：长时间光亮
		name = "aip_dou_element_fire_guard",
		color = colors.FIRE,
		assets = { Asset("ANIM", "anim/aip_dou_element_fire_guard.zip") },
		preFn = function(inst)
			inst.entity:AddLight()
			inst.Light:SetIntensity(.75)
			inst.Light:SetColour(200 / 255, 150 / 255, 50 / 255)
			inst.Light:SetFalloff(.5)
			inst.Light:SetRadius(1)
		end,
		postFn = function(inst)
			-- 加热附近的单位
			inst:AddComponent("heater")
			inst.components.heater.heat = 115

			-- 点燃能力
			inst:AddComponent("propagator")
			inst.components.propagator.heatoutput = 15
			inst.components.propagator.spreading = true
			inst.components.propagator:StartUpdating()
		end,
		duration = 30, -- 火焰持续 30 秒
	},
	{	-- 冰冻守卫：灭火、降温球
		name = "aip_dou_element_ice_guard",
		color = colors.ICE,
		assets = { Asset("ANIM", "anim/aip_dou_element_ice_guard.zip") },
		prefabs = { "aip_projectile" },
		postFn = function(inst)
			-- 灭火能力
			inst:AddComponent("wateryprotection")
			inst.components.wateryprotection.extinguishheatpercent = TUNING.FIRESUPPRESSOR_EXTINGUISH_HEAT_PERCENT
			inst.components.wateryprotection.temperaturereduction = TUNING.FIRESUPPRESSOR_TEMP_REDUCTION
			inst.components.wateryprotection.witherprotectiontime = TUNING.FIRESUPPRESSOR_PROTECTION_TIME
			inst.components.wateryprotection.addcoldness = TUNING.FIRESUPPRESSOR_ADD_COLDNESS
			-- inst.components.wateryprotection:AddIgnoreTag("player")

			-- 寻找火源
			inst:AddComponent("firedetector")
			inst.components.firedetector:Activate(0)
			inst.components.firedetector:SetOnFindFireFn(function(inst, firePos)
				-- TODO 投掷一个冰球
				-- inst.components.wateryprotection:SpreadProtectionAtPoint(firePos:Get())
				local proj = SpawnPrefab("aip_projectile")
				proj.Transform:SetPosition(inst.Transform:GetWorldPosition())
				proj.components.aipc_projectile:GoToPoint(firePos)
			end)
		end
	},
	{	-- 沙眼守卫：主动攻击
		name = "aip_dou_element_sand_guard",
		color = colors.SAND,
		assets = { Asset("ANIM", "anim/aip_dou_element_sand_guard.zip") },
	},
	{	-- 治疗守卫：治疗球
		name = "aip_dou_element_heal_guard",
		color = colors.HEAL,
		assets = { Asset("ANIM", "anim/aip_dou_element_heal_guard.zip") },
		scale = 1.5,
		spawnPrefab = "collapse_small",
	},
	{	-- 晓明守卫：理智光环
		name = "aip_dou_element_dawn_guard",
		color = colors.HEAL,
		assets = { Asset("ANIM", "anim/aip_dou_element_dawn_guard.zip") },
	},
}

local prefabs = {}

for i, data in ipairs(list) do
	table.insert(prefabs, Prefab(data.name, getFn(data), data.assets, data.prefabs))
end

return unpack(prefabs)
-- c_give("backpack") c_give("aip_dou_fire_inscription") c_give("aip_dou_ice_inscription") c_give("aip_dou_sand_inscription") c_give("aip_dou_heal_inscription") c_give("aip_dou_dawn_inscription")
-- c_give("houndfire") c_give("aip_dou_ice_inscription")