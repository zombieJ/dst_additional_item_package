local dev_mode = aipGetModConfig("dev_mode") == "enabled"

local petConfig = require("configurations/aip_pet")


-- 双端通用，抓捕宠物组件
local PetOwner = Class(function(self, inst)
	self.inst = inst
	self.pets = {}

	self.showPet = nil
end)

-- 补一下数据
function PetOwner:FillInfo()
	self.pets = self.pets or {}

	for i, petData in ipairs(self.pets) do
		petData.id = petData.id or (os.time() + i)
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
		local data = pet.components.aipc_petable:GetInfo()

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
end

-- 展示宠物
function PetOwner:ShowPet(index)
	self:FillInfo()

	self:HidePet()

	local petData = self.pets[index or 1]
	aipTypePrint("Show Pet:", petData)

	if petData ~= nil then
		local petPrefab = "aip_pet_"..petData.prefab
		local pet = aipSpawnPrefab(self.inst, petPrefab)
		pet.components.aipc_petable:SetInfo(petData, self.inst)

		aipSpawnPrefab(pet, "aip_shadow_wrapper").DoShow()
		self.showPet = pet
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

	aipTypePrint("Save:", data.pets)

	return data
end

function PetOwner:OnLoad(data)
	aipTypePrint("load:", data)
	if data ~= nil then
		self.pets = data.pets or {}
		aipTypePrint("load 1:", data.pets)
		aipTypePrint("load 2:", self.pets)
	end

	self:FillInfo()
	self.inst:DoTaskInTime(1, function()
		self:ShowPet()
	end)
end

return PetOwner