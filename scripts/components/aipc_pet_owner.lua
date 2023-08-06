local dev_mode = aipGetModConfig("dev_mode") == "enabled"

local petConfig = require("configurations/aip_pet")
local petPrefabs = require("configurations/aip_pet_prefabs")

local language = aipGetModConfig("language")

local MAX_PET_COUNT = 5
local MAX_UP_QUALITY_VALUE = dev_mode and 5 or 3

-- 文字描述
local LANG_MAP = {
	english = {
		FULL_FUDGE = "It ate too much fudge",
		NO_FUDGE = "No skill need raise quality",
	},
	chinese = {
		FULL_FUDGE = "它吃了太多软糖",
		NO_FUDGE = "它没有要提升品质的技能",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_PET_FULL_FUDGE = LANG.FULL_FUDGE
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_PET_NO_FUDGE = LANG.NO_FUDGE

-------------------------------- Buff --------------------------------
-- 嬉闹 BUFF
aipBufferRegister("aip_pet_play", {
	startFn = function(source, inst, info)
		if source ~= nil and source.components.aipc_pet_owner ~= nil then
			local skillInfo, skillLv = source.components.aipc_pet_owner:GetSkillInfo("play")
			if skillInfo ~= nil then
				local desc = skillInfo.weak * skillLv
				info.data.desc = math.min(1, math.max(info.data.desc or 0, desc))
			end
		end
	end,

	showFX = true,
})

-- 泥泞 BUFF
aipBufferRegister("aip_pet_muddy", {
	startFn = function(source, inst, info)
		if
			source ~= nil and source.components.aipc_pet_owner ~= nil and
			inst ~= nil and inst.components.locomotor ~= nil
		then
			local skillInfo, skillLv = source.components.aipc_pet_owner:GetSkillInfo("muddy")
			if skillInfo ~= nil then
				local slowPTG = math.max(0.1, 1 - skillInfo.multi * skillLv)

				inst.components.locomotor:SetExternalSpeedMultiplier(
					inst, "aipc_pet_muddy_speed", slowPTG
				)
			end
		end
	end,

	endFn = function(source, inst)
		if
			inst ~= nil and inst.components.locomotor ~= nil
		then
			inst.components.locomotor:RemoveExternalSpeedMultiplier(
				inst, "aipc_pet_muddy_speed"
			)
		end
	end,

	showFX = true,
})

---------------------------------------------------------------------
local function OnAttack(inst, data)
	if inst ~= nil and inst.components.aipc_pet_owner ~= nil and data ~= nil and data.target ~= nil then
		inst.components.aipc_pet_owner:Attack(data.target)
	end
end

local function OnAttacked(inst, data)
	if inst ~= nil and inst.components.aipc_pet_owner ~= nil then
		inst.components.aipc_pet_owner:Attacked(data)
	end
end

local function StopSpeed(inst)
	if inst.components.locomotor then
		inst.components.locomotor:RemoveExternalSpeedMultiplier(
			inst, "aipc_pet_owner_speed"
		)
	end
end

local function OnTimerDone(inst, data)
	data = data or {}

	if not inst.components.aipc_pet_owner then
		return
	end

	-- 宠物
	local pet = inst.components.aipc_pet_owner.showPet

	-- 检测距离
	if data.name == "aipc_pet_owner_distance" and pet then
		inst.components.aipc_pet_owner:StartDistanceCheck()
	end

	-- 不再加速
	if data.name == "aipc_pet_owner_speed" then
		StopSpeed(inst)
	end

	-- 定期掉落物品，同时循环再掉落
	if data.name == "aipc_pet_owner_shedding" and pet then
		-- 在随机表格中添加种子
		local lootTbl = petPrefabs.SHEDDING_LOOT[pet._aipPetPrefab]

		lootTbl = aipCloneTable(lootTbl or {})
		lootTbl.seeds = 0.5
		lootTbl.ash = 0.5

		local lootPrefab = aipRandomLoot(lootTbl)
		aipFlingItem(aipSpawnPrefab(pet, lootPrefab))
		inst.components.aipc_pet_owner:StartShedding()
	end

	-- 治疗
	if data.name == "aipc_pet_owner_cure" and pet then
		inst.components.aipc_pet_owner:StartCure(true)
	end

	-- 治疗
	if data.name == "aipc_pet_owner_blasphemy" and pet then
		inst.components.aipc_pet_owner:StartBlasphemy(true)
	end

	-- 海绵
	if data.name == "aipc_pet_owner_drink" and pet then
		inst.components.aipc_pet_owner:StartDrink(true)
	end
end

-- 开始烹饪
local function OnStartCooking(inst, data)
	local cookpot = aipGet(data, "cookpot")
	inst._aipLastCookpot = cookpot

	-- 如果是厨神则会加快烹饪速度
	local skillInfo, skillLv = inst.components.aipc_pet_owner:GetSkillInfo("cooker")
	if skillInfo ~= nil and cookpot ~= nil and cookpot.components.stewer ~= nil then
		local multi = math.max(0, 1 - skillInfo.multi * skillLv)

		-- 临时修改烹饪时间
		local oriCooktimemult = cookpot.components.stewer.cooktimemult
		cookpot.components.stewer.cooktimemult = multi

		-- 重置回去
		cookpot:DoTaskInTime(0, function()
			cookpot.components.stewer.cooktimemult = oriCooktimemult
		end)
	end
end

-- 时间阶段变化
local function OnPhase(inst, phase)
	if not inst.components.aipc_pet_owner then
		return
	end

	local pet = inst.components.aipc_pet_owner.showPet

	-- 每天白天重置一下宠物的喂食计数器
	if phase ~= "day" then
		if inst then
			for _, petData in ipairs(inst.components.aipc_pet_owner.pets) do
				petData.upgradeEffect = 1
				
				-- 恶行易施 计数器
				if petData.skills.d4c ~= nil then
					petData.skills.d4c.done = nil
				end
			end
		end
	end

	-- 如果是黄昏则制作一个虫洞
	if phase == "dusk" then
		local skillInfo, skillLv = inst.components.aipc_pet_owner:GetSkillInfo("dig")

		if skillInfo ~= nil and inst._aipLastCookpot ~= nil and inst._aipLastCookpot:IsValid() then
			local src = aipSpawnPrefab(pet, "wormhole_limited_1")
			local tgt = aipSpawnPrefab(inst._aipLastCookpot, "wormhole_limited_1")
			src.persists = false
			tgt.persists = false

			src.components.teleporter:Target(tgt)
			tgt.components.teleporter:Target(src)

			aipSpawnPrefab(src, "aip_shadow_wrapper").DoShow()

			-- 藏起来
			tgt.AnimState:OverrideMultColour(0, 0, 0, 0)
			tgt.Transform:SetScale(0.1, 0.1, 0.1)

			-- 自动移除
			local rmTime = skillInfo.duration + skillInfo.durationUnit * skillLv
			src:DoTaskInTime(rmTime, function(inst)
				if src:IsAsleep() then
					src:Remove()
				else
					src.sg:GoToState("death")
				end
			end)
			tgt:DoTaskInTime(rmTime, tgt.Remove)
		end
	end
end

-- 玩家跳虫洞
local function OnWormholeTravel(inst)
	if inst and inst.components.aipc_pet_owner then
		local skillInfo, skillLv, skill = inst.components.aipc_pet_owner:GetSkillInfo("d4c")

		if skillInfo ~= nil and skill.done == nil and inst.components.health ~= nil then
			inst.components.health:SetPercent(1)
			skill.done = true

			-- 播放特效
			local fx = SpawnPrefab("shadow_shield2")
			fx.entity:SetParent(inst.entity)
		end
	end
end

-- 捡起东西
local function OnPick(inst, data)
	data = data or {}

	if not inst.components.aipc_pet_owner then
		return
	end

	-- 如果存在 ge 技能，则重新生成植物
	local skillInfo, skillLv = inst.components.aipc_pet_owner:GetSkillInfo("ge")

	-- 总是拿出第一个
	local loot = data.loot or {}
	loot = loot[1] or loot
	loot = loot[1] or loot

	if skillInfo ~= nil and data.object ~= nil and loot ~= nil then
		-- 检查是否存在对应种子
		local seedName = loot.prefab.."_seeds"
		if not PrefabExists(seedName) then
			return
		end

		local chance = skillInfo.ptg * skillLv
		local pt = data.object:GetPosition()

		if math.random() < chance then
			inst:DoTaskInTime(0.1, function()
				local ents = TheSim:FindEntities(pt.x, 0, pt.z, 0.1)
				local farm_soil = aipFilterTable(ents, function(ent)
					return ent.prefab == "farm_soil"
				end)[1]

				if farm_soil ~= nil then
					local soil = aipReplacePrefab(farm_soil, "farm_soil")
					local seed = SpawnPrefab(seedName)
					seed.components.farmplantable:Plant(soil, inst)
				end
			end)
		end
	end
end

-- 躲避攻击
local function OnMissAttack(inst)
	if inst.components.aipc_pet_owner == nil then
		return
	end

	-- 如果存在 米糕 技能，则叠加输出
	local skillInfo, skillLv, skill = inst.components.aipc_pet_owner:GetSkillInfo("migao")

	if skillInfo ~= nil then
		-- 特效
		aipSpawnPrefab(inst, "farm_plant_happy")

		-- 叠加伤害
		skill._multi = math.min(
			(skill._multi or 0) + 1,
			skillLv
		)
	end
end

---------------------------------------------------------------------
-- 双端通用，抓捕宠物组件
local PetOwner = Class(function(self, inst)
	self.inst = inst
	self.pets = {}

	self.showPet = nil
	self.petData = nil		-- 临时存储展示的宠物信息用于快速查询

	self.inst:ListenForEvent("onhitother", OnAttack)
	self.inst:ListenForEvent("attacked", OnAttacked)
	self.inst:ListenForEvent("timerdone", OnTimerDone)
	self.inst:ListenForEvent("wormholespit", OnWormholeTravel)
	self.inst:ListenForEvent("aipStartCooking", OnStartCooking)
	self.inst:ListenForEvent("picksomething", OnPick)
	self.inst:ListenForEvent("aipMissAttack", OnMissAttack)

	self.inst:WatchWorldState("phase", OnPhase)
end)

-- 补一下数据
function PetOwner:FillInfo()
	self.pets = self.pets or {}

	for i, petData in ipairs(self.pets) do
		petData.id = petData.id or (os.time() + i)

		-- 喂食 计数器
		petData.upgradeEffect = petData.upgradeEffect or 1

		-- 补充等级
		petData.skills = petData.skills or {}
		for skillName, skillData in pairs(petData.skills) do
			skillData.lv = skillData.lv or 1
			skillData.quality = math.max(1, skillData.quality or 1)
		end
	end
end

-- 切换宠物，已经显示的则不做操作
function PetOwner:TogglePet(petId, showEffect)
	self:FillInfo()

	if
		self.showPet ~= nil and
		self.showPet.components.aipc_petable:GetInfo().id == petId
	then
		return
	else
		-- 不同则展示
		local index = aipTableIndex(self.pets, function(v)
			return v.id == petId
		end)

		if index ~= nil then
			return self:ShowPet(index, showEffect)
		end
	end
end

function PetOwner:Count()
	return #self.pets
end

function PetOwner:AddPetByInfo(data)
	table.insert(self.pets, data)

	return self:ShowPet(#self.pets)
end

-- 添加宠物
function PetOwner:AddPet(pet, qualityOffset)
	if self:IsFull() then
		return
	end

	if pet and pet.components.aipc_petable ~= nil then
		if qualityOffset and qualityOffset ~= 0 then
			pet.components.aipc_petable:DeltaQuality(qualityOffset)
		end

		local data = pet.components.aipc_petable:GetInfo(self.inst)

		return self:AddPetByInfo(data)
	end
end

-- 移除宠物
function PetOwner:RemovePet(id)
	-- 先藏起来
	if self.showPet ~= nil and self.showPet.components.aipc_petable:GetInfo().id == id then
		self:HidePet()
	end

	-- 移除
	local originLen = #self.pets
	self.pets = aipFilterTable(self.pets, function(v)
		return v.id ~= id
	end)

	return originLen ~= #self.pets
end

-- 隐藏宠物
function PetOwner:HidePet(showEffect)
	if self.showPet ~= nil then
		if showEffect == false then
			aipRemove(self.showPet)
		else
			aipReplacePrefab(self.showPet, "aip_shadow_wrapper").DoShow()
		end
		self.showPet = nil
	end

	self.petData = nil
	self:EnsureTimer()

	-- 停止距离检测
	self.inst.components.timer:StopTimer("aipc_pet_owner_distance")

	-- 停止加速
	StopSpeed(self.inst)

	-- 停止掉毛
	self.inst.components.timer:StopTimer("aipc_pet_owner_shedding")

	-- 停止治疗
	self.inst.components.timer:StopTimer("aipc_pet_owner_cure")

	-- 停止海绵
	self.inst.components.timer:StopTimer("aipc_pet_owner_drink")

	-- 停止杀神
	self:StopJohnWick()

	-- 停止 陵卫斗篷
	if self.inst.components.aipc_grave_cloak ~= nil then
		self.inst.components.aipc_grave_cloak:Stop()
	end
end

-- 展示宠物
function PetOwner:ShowPet(index, showEffect)
	self:FillInfo()

	self:HidePet()

	local petData = self.pets[index or 1]
	self.petData = petData

	if petData ~= nil then
		local fullname = petData.prefab..(petData.subPrefab or "")
		local petPrefab = "aip_pet_"..fullname
		local pet = aipSpawnPrefab(self.inst, petPrefab)
		pet._aipPetPrefab = fullname
		pet.components.aipc_petable:SetInfo(petData, self.inst)

		if showEffect ~= false then
			aipSpawnPrefab(pet, "aip_shadow_wrapper").DoShow()
		end
		self.showPet = pet

		-- 距离检测
		self:StartDistanceCheck()

		-- 尝试掉毛
		self:StartShedding()

		-- 尝试光环
		self:StartAura()

		-- 尝试温度
		self:StartHeater()

		-- 尝试治愈
		self:StartCure()

		-- 尝试海绵
		self:StartDrink()

		-- 尝试杀神
		self:StartJohnWick()

		-- 尝试陵卫斗篷
		self:StartGraveCloak()

		-- 尝试亵渎
		self:StartBlasphemy()

		-- 尝试光媒
		self:StartBubble()

		return pet
	end
end

-- 获取宠物能力对应的数据，会额外包含 lv，如果没有技能则返回 nil
function PetOwner:GetSkillInfo(skillName)
	local skill = aipGet(self.petData, "skills|"..skillName)

	if skill ~= nil then
		local skillLv = skill.lv
		return petConfig.SKILL_CONSTANT[skillName] or {}, skillLv, skill
	end

	return nil
end

-- 刷新宠物，重新渲染出来
function PetOwner:RefreshPet(id)
	if self.showPet and self.showPet.components.aipc_petable:GetInfo().id == id then
		local pt = self.showPet:GetPosition()
		self:HidePet(false)
		local nextPet = self:TogglePet(id, false)

		if nextPet then
			nextPet.Transform:SetPosition(pt:Get())
			aipSpawnPrefab(nextPet, "farm_plant_happy")
		end
	end
end

-- 升级宠物
function PetOwner:UpgradePet(id, inst)
	local petData = aipFilterTable(self.pets, function(v)
		return v.id == id
	end)[1]

	if petData ~= nil then
		aipPrint("UpgradePet:", inst.prefab)

		-- 如果是 BUG 软糖，直接满级
		if inst.prefab == "aip_pet_fudge_bug" then
			local MAX_QUALITY = 5

			petData.quality = MAX_QUALITY

			for skillName, skillData in pairs(petData.skills) do
				skillData.quality = MAX_QUALITY
			end

			-- 添加一个亵渎技能
			petData.skills.blasphemy = {
				lv = 1,
				quality = MAX_QUALITY,
			}

			self:RefreshPet(id)
			return
		end

		if inst:HasTag("aip_pet_fudge") then
			-- 升级技能品质
			local quality = petData.quality
			petData.upgradeQuality = petData.upgradeQuality or 0

			local isFish = inst.prefab == "aip_pet_fudge_fish"
			local qualityValue = isFish and 3 or 1

			if petData.upgradeQuality + qualityValue <= MAX_UP_QUALITY_VALUE then
				petData.upgradeQuality = petData.upgradeQuality + qualityValue

				-- 收集一下可以升级品质的技能列表
				local canUpgradeSkillNames = {}
				local lowestSkillQuality = 999
				local lowestSkillName = nil

				for skillName, skillData in pairs(petData.skills) do
					local skillQuality = skillData.quality

					if skillQuality < quality then
						table.insert(canUpgradeSkillNames, skillName)

						if skillQuality < lowestSkillQuality then
							lowestSkillQuality = skillQuality
							lowestSkillName = skillName
						end
					end
				end

				local upgradeSkillName = aipRandomEnt(canUpgradeSkillNames)

				if not isFish then
					-- 随机升级一个技能 1 级
					for skillName, skillData in pairs(petData.skills) do
						if skillName == upgradeSkillName then
							skillData.quality = skillData.quality + 1
							break
						end
					end

					aipPrint("Upgrade 1:", upgradeSkillName)
				elseif lowestSkillName ~= nil then
					-- 升级最低品质的技能 2 级
					petData.skills[lowestSkillName].quality = math.min(
						petData.skills[lowestSkillName].quality + 2,
						quality
					)

					aipPrint("Upgrade 2:", lowestSkillName)
				end

				-- 告知不需要提升品质了
				if not upgradeSkillName and not lowestSkillName then
					aipFlingItem(aipSpawnPrefab(self.showPet, inst.prefab))

					if self.inst.components.talker ~= nil then
						self.inst.components.talker:Say(
							STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_PET_NO_FUDGE
						)
					end

					return
				end

				-- 如果是当前宠物，则重新渲染
				self:RefreshPet(id)


			else -- 不能吃更多软糖了，吐出来
				aipFlingItem(aipSpawnPrefab(self.showPet, inst.prefab))

				if self.inst.components.talker ~= nil then
					self.inst.components.talker:Say(
						STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_PET_FULL_FUDGE
					)
				end
			end
		else
			-- 升级技能等级
			local upgradeEffect = petData.upgradeEffect or 1

			-- 收集一下可以升级的技能列表
			local canUpgradeSkillNames = {}
			for skillName, skillData in pairs(petData.skills) do
				local maxLevel = petConfig.SKILL_MAX_LEVEL[skillName] or {}
				local maxLv = maxLevel[skillData.quality] or 1

				if skillData.lv < maxLv then
					table.insert(canUpgradeSkillNames, skillName)
				end
			end

			-- 随机升级一个技能
			local upgradeSkillName = aipRandomEnt(canUpgradeSkillNames)
			for skillName, skillData in pairs(petData.skills) do
				if skillName == upgradeSkillName then
					local maxLevel = petConfig.SKILL_MAX_LEVEL[skillName] or {}

					-- 有最高等级限制
					skillData.lv = skillData.lv + upgradeEffect
					skillData.lv = math.min(skillData.lv, maxLevel[skillData.quality] or 1)
					break
				end
			end

			-- 如果是当前宠物，则重新渲染
			self:RefreshPet(id)

			-- 一天内的喂食效果后续会减少
			petData.upgradeEffect = dev_mode and 0.9 or 0.1
		end
	end
end

------------------------------ 杂项 ------------------------------
function PetOwner:EnsureTimer()
	if not self.inst.components.timer then
		self.inst:AddComponent("timer")
	end
end

-- 攻击
function PetOwner:Attack(target)
	-- 嬉闹
	local skillInfo, skillLv = self:GetSkillInfo("play")

	if skillInfo ~= nil then
		aipBufferPatch(self.inst, target, "aip_pet_play", skillInfo.duration * skillLv)
	end

	-- 泥泞
	local muddyInfo, muddyLv = self:GetSkillInfo("muddy")

	if muddyInfo ~= nil then
		aipBufferPatch(self.inst, target, "aip_pet_muddy", muddyInfo.duration)
	end
end

-- 被攻击
function PetOwner:Attacked(data)
	self:EnsureTimer()
	
	local attacker = aipGet(data, 'attacker')

	-- 触发 谨慎 效果
	local skillInfo, skillLv = self:GetSkillInfo("cowardly")
	if skillInfo ~= nil and self.inst.components.locomotor ~= nil then
		local multi = 1 + skillInfo.multi * skillLv

		-- 添加计时器
		self.inst.components.timer:StopTimer("aipc_pet_owner_speed")
		self.inst.components.timer:StartTimer("aipc_pet_owner_speed", skillInfo.duration)

		-- 重置一下速度叠加
		self.inst.components.locomotor:RemoveExternalSpeedMultiplier(
			self.inst, "aipc_pet_owner_speed"
		)
		self.inst.components.locomotor:SetExternalSpeedMultiplier(
			self.inst, "aipc_pet_owner_speed", multi
		)
	end

	-- 触发 睡眠 效果
	local hypnosisInfo, hypnosisLv = self:GetSkillInfo("hypnosis")
	if hypnosisInfo ~= nil and attacker ~= nil then
		local multi = hypnosisInfo.multi * hypnosisLv

		-- 睡 5 秒
		local SLEEP_TIME = TUNING.PANFLUTE_SLEEPTIME / 4

		if math.random() < multi then
			if attacker.components.sleeper ~= nil then
				attacker.components.sleeper:AddSleepiness(10, SLEEP_TIME)
			elseif attacker.components.grogginess ~= nil then
				attacker.components.grogginess:AddGrogginess(10, SLEEP_TIME)
			else
				attacker:PushEvent("knockedout")
			end
		end
	end
end

-- 距离检测
function PetOwner:StartDistanceCheck()
	if self.showPet then
		local playerPT = self.inst:GetPosition()
		local petPT = self.showPet:GetPosition()
		local dist = aipDist(playerPT, petPT)
		local MAX_DIST = 30

		-- 超过距离就飞过去
		if dist > MAX_DIST then
			local angle = aipGetAngle(playerPT, petPT)
			local nextPetPT = aipAngleDist(playerPT, angle, MAX_DIST)

			self.showPet.Transform:SetPosition(nextPetPT:Get())
		end

		self:EnsureTimer()
		self.inst.components.timer:StartTimer("aipc_pet_owner_distance", 5)
	end
end

-- 掉落物品
function PetOwner:StartShedding()
	local skillInfo, skillLv = self:GetSkillInfo("shedding")

	if skillInfo ~= nil then
		self:EnsureTimer()
		local timeout = skillInfo.base - skillInfo.multi * skillLv
		timeout = math.max(timeout, 10)	-- 最少 10 秒
		self.inst.components.timer:StartTimer("aipc_pet_owner_shedding", timeout)
	end
end

-- 添加一些光环
function PetOwner:StartAura()
	local skillInfo, skillLv = self:GetSkillInfo("accompany")

	if skillInfo ~= nil and self.showPet ~= nil then
		if self.showPet.components.sanityaura == nil then
			self.showPet:AddComponent("sanityaura")
		end

		-- 给宠物添加一个光环
		self.showPet.components.sanityaura.aura = skillInfo.unit * skillLv
	end
end

-- 添加温度控制器
function PetOwner:StartHeater()
	local coolSkillInfo, coolSkillLv = self:GetSkillInfo("cool")
	local hotSkillInfo, hotSkillLv = self:GetSkillInfo("hot")

	local skillInfo = coolSkillInfo or hotSkillInfo
	local skillLv = coolSkillLv or hotSkillLv

	if skillInfo ~= nil and self.showPet ~= nil then
		if self.showPet.components.heater == nil then
			self.showPet:AddComponent("heater")
		end

		-- 温度变化
		local heat = skillInfo.heat * skillLv
		self.showPet.components.heater.heat = heat
		if heat < 0 then
			self.showPet.components.heater:SetThermics(false, true)
		end
	end
end

-- 开始持续的恢复生命值
function PetOwner:StartCure(doCure)
	local skillInfo, skillLv = self:GetSkillInfo("cure")

	if skillInfo ~= nil and self.inst.components.health ~= nil then
		local ptg = self.inst.components.health:GetPercent()
		local maxPtg = skillInfo.max + skillInfo.maxMulti * skillLv

		-- 如果生命值低于阈值，发射飞弹治疗目标
		if
			doCure and ptg < maxPtg and
			self.showPet and self.showPet:IsValid() and
			not self.inst.components.health:IsDead()
		then
			local delta = skillInfo.multi * skillLv
			
			local proj = aipSpawnPrefab(self.showPet, "aip_projectile")
			proj.components.aipc_info_client:SetByteArray( -- 调整颜色
				"aip_projectile_color", { 0, 10, 3, 5 }
			)

			proj.components.aipc_projectile:GoToTarget(self.inst, function()
				if
					self.inst.components.health ~= nil and
					not self.inst.components.health:IsDead() and
					self.inst:IsValid() and not self.inst:IsInLimbo()
				then
					self.inst.components.health:DoDelta(delta)
				end
			end)
		end

		self:EnsureTimer()
		self.inst.components.timer:StartTimer("aipc_pet_owner_cure", skillInfo.interval)
	end
end

-- 开始吸收雨露值
function PetOwner:StartDrink(doCure)
	local skillInfo, skillLv = self:GetSkillInfo("sponge")

	if skillInfo ~= nil and self.inst.components.moisture ~= nil then
		local moisture = self.inst.components.moisture:GetMoisture()
		moisture = math.min(moisture, skillInfo.multi * skillLv)

		-- 减少雨露，增加饥饿值
		if doCure and moisture > 0 then
			self.inst.components.moisture:DoDelta(-moisture)

			if self.inst.components.hunger ~= nil then
				self.inst.components.hunger:DoDelta(moisture)
			end
		end

		self:EnsureTimer()
		self.inst.components.timer:StartTimer("aipc_pet_owner_drink", skillInfo.interval)
	end
end

-- 开始杀神
function PetOwner:StartJohnWick()
	self:StopJohnWick()

	local skillInfo, skillLv = self:GetSkillInfo("johnWick")
	if skillInfo ~= nil then
		local pets = {}
		if self.inst.components.petleash ~= nil then
			pets = self.inst.components.petleash:GetPets() or {}
		end

		local existDog = false

		for k, pet in pairs(pets) do
			if pet.prefab == "critter_puppy" then
				existDog = true
			end
		end

		-- 根据宠物切换光环
		self._johnWichAura = self.inst:SpawnChild(
			existDog and "aip_aura_john_wick" or "aip_aura_john_wick_single"
		)
	end
end


-- 开始亵渎：持续丢失生命值
function PetOwner:StartBlasphemy(doDelta)
	local skillInfo, skillLv = self:GetSkillInfo("blasphemy")

	if
		skillInfo ~= nil and
		self.showPet and
		self.showPet:IsValid() and
		self.inst.components.health ~= nil
	then
		if
			self.inst.components.health.currenthealth > 1 and
			doDelta
		then
			self.inst.components.health:DoDelta(-1, true)
		end

		self:EnsureTimer()
		self.inst.components.timer:StartTimer("aipc_pet_owner_blasphemy", 1)
	end
end

-- 开始光媒：发出光芒
function PetOwner:StartBubble()
	local skillInfo, skillLv = self:GetSkillInfo("bubble")

	if skillInfo ~= nil and self.showPet ~= nil then
		local radius = skillInfo.base + skillInfo.multi * skillLv

		if not self.showPet.Light then
			self.showPet.entity:AddLight()
		end

		self.showPet.Light:SetFalloff(0.5)
		self.showPet.Light:SetIntensity(.9)
		self.showPet.Light:SetColour(237/255, 237/255, 209/255)
		self.showPet.Light:SetRadius(radius)
		self.showPet.Light:Enable(true)
	end
end

function PetOwner:StopJohnWick()
	if self._johnWichAura ~= nil then
		self._johnWichAura:Remove()
		self._johnWichAura = nil
	end
end

-- 开始 陵卫斗篷
function PetOwner:StartGraveCloak()
	local skillInfo, skillLv, skill = self:GetSkillInfo("graveCloak")

	if skillInfo ~= nil then
		if self.inst.components.aipc_grave_cloak == nil then
			self.inst:AddComponent("aipc_grave_cloak")
		end

		self.inst.components.aipc_grave_cloak.interval = skillInfo.interval
		self.inst.components.aipc_grave_cloak.count = skillInfo.count

		self.inst.components.aipc_grave_cloak:Start()
	end
end

function PetOwner:IsFull()
	return #self.pets >= MAX_PET_COUNT
end

function PetOwner:IsEmpty()
	return #self.pets <= 0
end

------------------------------ 数据 ------------------------------
function PetOwner:GetInfos()
	self:FillInfo()
	return self.pets or {}
end

------------------------------ 存取 ------------------------------
function PetOwner:OnSave()
    local data = {
        pets = self.pets,
		id = self.showPet ~= nil and self.showPet.components.aipc_petable:GetInfo().id or false,
    }

	return data
end

function PetOwner:OnLoad(data)
	local id = false
	if data ~= nil then
		self.pets = data.pets or {}
	end

	self:FillInfo()

	-- 如果不是 false 就填充一个宠物出来
	if data ~= nil then
		id = data.id
		if data.id == nil then
			id = self.pets[1] ~= nil and self.pets[1].id or false
		end
	end

	aipTypePrint("Load:", data, id)

	if id ~= false then
		self.inst:DoTaskInTime(1, function()
			self:TogglePet(id, true)
		end)
	end
end

function PetOwner:OnRemoveEntity()
	self:HidePet()
	self.inst:RemoveEventCallback("onhitother", OnAttack)
	self.inst:RemoveEventCallback("attacked", OnAttacked)
	self.inst:RemoveEventCallback("timerdone", OnTimerDone)
	self.inst:RemoveEventCallback("wormholespit", OnWormholeTravel)
	self.inst:RemoveEventCallback("aipStartCooking", OnStartCooking)
	self.inst:RemoveEventCallback("picksomething", OnPick)
	self.inst:RemoveEventCallback("aipMissAttack", OnMissAttack)
end

PetOwner.OnRemoveFromEntity = PetOwner.OnRemoveEntity

return PetOwner