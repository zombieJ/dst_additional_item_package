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
		NAMES = {
			AIP_DOU_ELEMENT_FIRE_GUARD = "Light Guard",
			AIP_DOU_ELEMENT_ICE_GUARD = "Ice Guard",
			AIP_DOU_ELEMENT_SAND_GUARD = "Attack Guard",
			AIP_DOU_ELEMENT_HEAL_GUARD = "Cure Guard",
			AIP_DOU_ELEMENT_DAWN_GUARD = "Ridicule Guard",
		},
		DESC = {
			AIP_DOU_ELEMENT_FIRE_GUARD = "Faint light can burn away troubles",
			AIP_DOU_ELEMENT_ICE_GUARD = "Helper to extinguish the flame",
			AIP_DOU_ELEMENT_SAND_GUARD = "Killer without loyalty",
			AIP_DOU_ELEMENT_HEAL_GUARD = "Only recover the lost part",
			AIP_DOU_ELEMENT_DAWN_GUARD = "Humorous",
		},
		DAWN_SPEACH = {
			"I don't care",
			"You can try",
			"This is it",
			"Not popular",
			"Give me five",
			"Your guard",
			"(Caugh~)",
		},
	},
	chinese = {
		NAME = "元素之灵",
		DESC = "为什么帮我？",
		NAMES = {
			AIP_DOU_ELEMENT_FIRE_GUARD = "黄昏照耀者",
			AIP_DOU_ELEMENT_ICE_GUARD = "炙烤抵御者",
			AIP_DOU_ELEMENT_SAND_GUARD = "混沌刺杀者",
			AIP_DOU_ELEMENT_HEAL_GUARD = "冯芳治疗者",
			AIP_DOU_ELEMENT_DAWN_GUARD = "高傲嘲讽者",
		},
		DESC = {
			AIP_DOU_ELEMENT_FIRE_GUARD = "微弱的光芒可以烧除烦恼",
			AIP_DOU_ELEMENT_ICE_GUARD = "扑灭火焰的帮手",
			AIP_DOU_ELEMENT_SAND_GUARD = "毫无忠诚的杀手",
			AIP_DOU_ELEMENT_HEAL_GUARD = "只恢复损失的那一部分",
			AIP_DOU_ELEMENT_DAWN_GUARD = "幽默风趣",
		},
		DAWN_SPEACH = {
			"我不在乎",
			"可以试试",
			"这下可以了",
			"一点都不火",
			"喜欢点个赞",
			"你的生存导师",
			"咳咳咳~",
		},
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

-- 文字描述
STRINGS.NAMES.AIP_DOU_ELEMENT_GUARD = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_DOU_ELEMENT_GUARD = LANG.DESC
STRINGS.AIP_DAWN_GUARD_SPEACH = LANG.DAWN_SPEACH or LANG_MAP.english.DAWN_SPEACH

-- 填充名字 & 描述
local names = LANG.NAMES or LANG_MAP.english.NAMES
for key, name in pairs(names) do
	STRINGS.NAMES[key] = name
end

local descs = LANG.DESC or LANG_MAP.english.DESC
for key, name in pairs(descs) do
	STRINGS.CHARACTERS.GENERIC.DESCRIBE[key] = name
end

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
		inst:DoTaskInTime(data.duration or 8, function(inst)
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
			-- 我们存一个临时变量列表
			inst.fireEnts = {}

			-- 寻找火源
			inst:DoPeriodicTask(TUNING.FIRE_DETECTOR_PERIOD, function()
				local x, y, z = inst.Transform:GetWorldPosition()

				local NOTAGS = { "FX", "NOCLICK", "DECOR", "INLIMBO", "burnt", "player", "monster" }
				local NONEMERGENCY_FIREONLY_TAGS = {"fire"} -- {"fire", "smolder"}

				local ents = TheSim:FindEntities(
					x, 0, z,
					TUNING.FIRE_DETECTOR_RANGE, nil, NOTAGS, NONEMERGENCY_FIREONLY_TAGS
				)

				-- 寻找对象
				local match = nil
				for i, ent in ipairs(ents) do
					if ent.components.burnable ~= nil and ent.components.burnable:IsBurning() and not aipInTable(inst.fireEnts, ent) then
						table.insert(inst.fireEnts, ent)
						match = ent
					end
				end

				if match == nil then
					-- 如果没有更多对象匹配了，则重置搜查
					inst.fireEnts = {}
				else
					-- 发射灭火元素
					local proj = SpawnPrefab("aip_projectile")
					local x, y, z = inst.Transform:GetWorldPosition()

					proj.Transform:SetPosition(x, 1, z)
					proj.components.aipc_projectile:GoToTarget(match, function()
						if match ~= nil and match.components.burnable ~= nil and match.components.burnable:IsBurning() then
							match.components.burnable:Extinguish()
						end
					end)
				end
			end)
		end
	},
	{	-- 沙眼守卫：不断召唤沙刺
		name = "aip_dou_element_sand_guard",
		color = colors.SAND,
		assets = { Asset("ANIM", "anim/aip_dou_element_sand_guard.zip") },
		prefabs = { "sandspike_short" },
		scale = 1.5,
		spawnPrefab = "collapse_small",
		postFn = function(inst)
			-- 每隔 1 秒召唤一个沙刺
			inst:DoPeriodicTask(1, function()
				local x, y, z = inst.Transform:GetWorldPosition()
				local NOTAGS = { "FX", "NOCLICK", "DECOR", "INLIMBO", "burnt", "monster", "structure" }

				local ents = TheSim:FindEntities(x, 0, z, TUNING.FIRE_DETECTOR_RANGE, { "_combat", "_health" }, NOTAGS)
				ents = aipFilterTable(ents, function(ent)
					return ent.components.health ~= nil and not ent.components.health:IsDead() and not ent.components.health:IsInvincible()
				end)
				local target = aipRandomEnt(ents) -- 随机选一个目标召唤沙刺

				if target ~= nil then
					local prefab = SpawnPrefab("sandspike_short")
					local nx, ny, nz = target.Transform:GetWorldPosition()
					prefab.Transform:SetPosition(nx + (0.5 - math.random()) / 2, 0, nz + (0.5 - math.random()) / 2)

					-- 重置一下伤害
					if prefab.components.combat ~= nil then
						prefab.components.combat:SetDefaultDamage(15)
						prefab.components.combat.playerdamagepercent = 1
					end
					-- 沙刺是无敌的
					if prefab.components.health ~= nil then
						prefab.components.health:SetInvincible(true)
						prefab.components.health:LockInvincible(true)
						prefab:DoTaskInTime(3, function() -- 随机沙锥时间更短一些
							prefab.components.health:LockInvincible(false)
							prefab.components.health:SetInvincible(false)
							prefab.components.health:Kill()
						end)
					end
				end
			end)
		end,
		duration = 7,
	},
	{	-- 治疗守卫：治疗球
		name = "aip_dou_element_heal_guard",
		color = colors.HEAL,
		assets = { Asset("ANIM", "anim/aip_dou_element_heal_guard.zip") },
		scale = 1.5,
		spawnPrefab = "collapse_small",
		postFn = function(inst)
			-- 每隔 1 秒治疗一个玩家
			inst:DoPeriodicTask(1, function()
				local x, y, z = inst.Transform:GetWorldPosition()
				local NOTAGS = { "FX", "NOCLICK", "DECOR", "playerghost", "INLIMBO" }

				local ents = TheSim:FindEntities(x, 0, z, TUNING.FIRE_DETECTOR_RANGE, { "player", "_health" }, NOTAGS)
				ents = aipFilterTable(ents, function(ent) -- 只治疗受伤的
					return ent.components.health ~= nil and ent.components.health:IsHurt()
				end)
				local player = aipRandomEnt(ents)
				aipTypePrint(ents)

				if player ~= nil then
					-- 发射治疗元素
					local proj = SpawnPrefab("aip_projectile")
					proj.components.aipc_info_client:SetByteArray( -- 调整颜色
						"aip_projectile_color", { colors.HEAL[1] * 10, colors.HEAL[2] * 10, colors.HEAL[3] * 10, colors.HEAL[4] * 10 }
					)

					proj.Transform:SetPosition(x, 1, z)
					proj.components.aipc_projectile:GoToTarget(player, function()
						if player ~= nil and player.components.health ~= nil and not player.components.health:IsDead() then
							local cur = player.components.health.currenthealth
							local max = player.components.health.maxhealth
							local diff = max - cur
							player.components.health:DoDelta(math.max(diff * 0.10, 5)) -- 每次恢复损失生命值的 10%，至少 5 点
						end
					end)
				end
			end)
		end,
	},
	{	-- 晓明守卫：鼓励机制
		name = "aip_dou_element_dawn_guard",
		color = colors.DAWN,
		assets = { Asset("ANIM", "anim/aip_dou_element_dawn_guard.zip") },
		duration = 16,
		preFn = function(inst)
			inst:AddComponent("talker")
			inst.components.talker.fontsize = 30
			inst.components.talker.font = TALKINGFONT
			inst.components.talker.colour = Vector3(.9, 1, .9)
			inst.components.talker.offset = Vector3(0, -500, 0)
		end,
		postFn = function(inst)
			-- 添加生命值
			inst:AddComponent("health")
			inst.components.health:SetMaxHealth(TUNING.BABYBEEFALO_HEALTH)

			inst:AddComponent("combat")
			inst.components.combat:SetDefaultDamage(1)

			-- 每隔 6 秒说一句话嘲讽敌人
			inst:DoPeriodicTask(6, function()
				inst.components.talker:Say(aipRandomEnt(STRINGS.AIP_DAWN_GUARD_SPEACH))

				-- 找到所有敌人
				local INSTANT_TARGET_MUST_HAVE_TAGS = {"_combat", "_health"}
				local INSTANT_TARGET_CANTHAVE_TAGS = { "INLIMBO", "epic", "structure", "butterfly", "wall", "balloon", "groundspike", "smashable", "companion", "player"}

				local x, y, z = inst.Transform:GetWorldPosition()
				local entities_near_me = TheSim:FindEntities(
					x, y, z,
					TUNING.BATTLESONG_ATTACH_RADIUS, INSTANT_TARGET_MUST_HAVE_TAGS, INSTANT_TARGET_CANTHAVE_TAGS
				)
				for _, ent in ipairs(entities_near_me) do
					if ent.components.combat:CanTarget(inst) then
						ent.components.combat:SetTarget(inst)
					end
				end
			end, 0)
		end,
	},
}

local prefabs = {}

for i, data in ipairs(list) do
	table.insert(prefabs, Prefab(data.name, getFn(data), data.assets, data.prefabs))
end

return unpack(prefabs)
-- c_give("backpack") c_give("aip_dou_fire_inscription") c_give("aip_dou_ice_inscription") c_give("aip_dou_sand_inscription") c_give("aip_dou_heal_inscription") c_give("aip_dou_dawn_inscription")
-- c_give("houndfire") c_give("aip_dou_ice_inscription")


--               c_give("aip_dou_dawn_inscription")