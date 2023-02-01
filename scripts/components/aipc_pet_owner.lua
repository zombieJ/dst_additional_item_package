local dev_mode = aipGetModConfig("dev_mode") == "enabled"

local petConfig = require("configurations/aip_pet")

---------------------------------------------------------------------
local function OnAttacked(inst)
	if inst ~= nil and inst.components.aipc_pet_owner ~= nil then
		inst.components.aipc_pet_owner:Attacked()
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

	-- 不再加速
	if data.name == "aipc_pet_owner_speed" then
		StopSpeed(inst)
	end

	-- 定期掉落物品，同时循环再掉落
	if data.name == "aipc_pet_owner_shedding" and pet then
		aipFlingItem(aipSpawnPrefab(pet, "seeds"))
		inst.components.aipc_pet_owner:StartShedding()
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
end)

-- 补一下数据
function PetOwner:FillInfo()
	self.pets = self.pets or {}

	for i, petData in ipairs(self.pets) do
		petData.id = petData.id or (os.time() + i)

		-- 补充等级
		petData.skills = petData.skills or {}
		for skillName, skillData in pairs(petData.skills) do
			skillData.lv = skillData.lv or 1
			skillData.quality = math.max(1, skillData.quality or 1)
		end
	end
end

-- 切换宠物，如果已经展示则隐藏
function PetOwner:TogglePet(petId)
	self:FillInfo()

	if
		self.showPet ~= nil and
		self.showPet.components.aipc_petable:GetInfo().id == petId
	then
		-- 相同则隐藏
		self:HidePet()
	else
		-- 不同则展示
		local index = aipTableIndex(self.pets, function(v)
			return v.id == petId
		end)

		if index ~= nil then
			self:ShowPet(index)
		end
	end
end

-- 添加宠物
function PetOwner:AddPet(pet)
	if pet and pet.components.aipc_petable ~= nil then
		local data = pet.components.aipc_petable:GetInfo(self.inst)

		table.insert(self.pets, data)
	end

	self:ShowPet(#self.pets)
end

-- 隐藏宠物
function PetOwner:HidePet()
	if self.showPet ~= nil then
		aipReplacePrefab(self.showPet, "aip_shadow_wrapper").DoShow()
		self.showPet = nil
	end

	self.petData = nil

	-- 停止加速
	StopSpeed(self.inst)

	-- 停止掉毛
	self:EnsureTimer()
	self.inst.components.timer:StopTimer("aipc_pet_owner_shedding")
end

-- 展示宠物
function PetOwner:ShowPet(index)
	self:FillInfo()

	self:HidePet()

	local petData = self.pets[index or 1]
	self.petData = petData

	if petData ~= nil then
		local petPrefab = "aip_pet_"..petData.prefab..(petData.subPrefab or "")
		local pet = aipSpawnPrefab(self.inst, petPrefab)
		pet.components.aipc_petable:SetInfo(petData, self.inst)

		aipSpawnPrefab(pet, "aip_shadow_wrapper").DoShow()
		self.showPet = pet

		-- 尝试掉毛
		self:StartShedding()

		-- 尝试光环
		self:StartAura()
	end
end

-- 获取宠物能力对应的数据，会额外包含 lv，如果没有技能则返回 nil
function PetOwner:GetSkillInfo(skill)
	local skillLv = aipGet(self.petData, "skills|"..skill.."|lv")

	if skillLv ~= nil then
		return petConfig.SKILL_CONSTANT[skill], skillLv
	end

	return nil
end

------------------------------ 杂项 ------------------------------
function PetOwner:EnsureTimer()
	if not self.inst.components.timer then
		self.inst:AddComponent("timer")
	end
end

-- 被攻击
function PetOwner:Attacked()
	self:EnsureTimer()

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
end

-- 掉落物品
function PetOwner:StartShedding()
	local skillInfo, skillLv = self:GetSkillInfo("shedding")

	if skillInfo ~= nil then
		self:EnsureTimer()
		local timeout = skillInfo.base - skillInfo.multi * skillLv
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