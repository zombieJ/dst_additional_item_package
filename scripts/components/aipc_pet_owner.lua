local dev_mode = aipGetModConfig("dev_mode") == "enabled"

local petConfig = require("configurations/aip_pet")
local petPrefabs = require("configurations/aip_pet_prefabs")

local MAX_PET_COUNT = 5

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

	-- 海绵
	if data.name == "aipc_pet_owner_drink" and pet then
		inst.components.aipc_pet_owner:StartDrink(true)
	end
end

-- 开始烹饪
local function OnStartCooking(inst, data)
	inst._aipLastCookpot = aipGet(data, "cookpot")
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

		table.insert(self.pets, data)
	end

	return self:ShowPet(#self.pets)
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

-- 升级宠物
function PetOwner:UpgradePet(id)
	local petData = aipFilterTable(self.pets, function(v)
		return v.id == id
	end)[1]

	if petData ~= nil then
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
		if self.showPet and self.showPet.components.aipc_petable:GetInfo().id == id then
			local pt = self.showPet:GetPosition()
			self:HidePet(false)
			local nextPet = self:TogglePet(id, false)

			if nextPet then
				nextPet.Transform:SetPosition(pt:Get())
				aipSpawnPrefab(nextPet, "farm_plant_happy")
			end
		end

		-- 一天内的喂食效果后续会减少
		petData.upgradeEffect = dev_mode and 0.9 or 0.1
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
	local skillInfo, skillLv = self:GetSkillInfo("play")

	if skillInfo ~= nil then
		aipBufferPatch(self.inst, target, "aip_pet_play", skillInfo.duration * skillLv)
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
			self.showPet and not self.inst.components.health:IsDead()
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
end

PetOwner.OnRemoveFromEntity = PetOwner.OnRemoveEntity

return PetOwner