local dev_mode = aipGetModConfig("dev_mode") == "enabled"

local petConfig = require("configurations/aip_pet")
local petPrefabs = require("configurations/aip_pet_prefabs")

local MAX_PET_COUNT = 5

---------------------------------------------------------------------
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
end

-- 每天重置一下喂食效率
local function OnIsDay(inst, isday)
    if isday then
        return
    end

    if inst and inst.components.aipc_pet_owner then
		for _, petData in ipairs(inst.components.aipc_pet_owner.pets) do
			petData.upgradeEffect = 1
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

	self.inst:ListenForEvent("attacked", OnAttacked)
	self.inst:ListenForEvent("timerdone", OnTimerDone)

	self.inst:WatchWorldState("isday", OnIsDay)
end)

-- 补一下数据
function PetOwner:FillInfo()
	self.pets = self.pets or {}

	for i, petData in ipairs(self.pets) do
		petData.id = petData.id or (os.time() + i)
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

		return pet
	end
end

-- 获取宠物能力对应的数据，会额外包含 lv，如果没有技能则返回 nil
function PetOwner:GetSkillInfo(skill)
	local skillLv = aipGet(self.petData, "skills|"..skill.."|lv")

	if skillLv ~= nil then
		return petConfig.SKILL_CONSTANT[skill] or {}, skillLv
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

		aipTypePrint("Skill:", upgradeSkillName, canUpgradeSkillNames)

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
    }

	return data
end

function PetOwner:OnLoad(data)
	if data ~= nil then
		self.pets = data.pets or {}
	end

	self:FillInfo()
	self.inst:DoTaskInTime(1, function()
		self:ShowPet()
	end)
end

function PetOwner:OnRemoveEntity()
	self:HidePet()
	self.inst:RemoveEventCallback("attacked", OnAttacked)
	self.inst:RemoveEventCallback("timerdone", OnTimerDone)
end

PetOwner.OnRemoveFromEntity = PetOwner.OnRemoveEntity

return PetOwner