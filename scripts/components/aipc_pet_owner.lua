local dev_mode = aipGetModConfig("dev_mode") == "enabled"

local petConfig = require("configurations/aip_pet")


-- 双端通用，抓捕宠物组件
local PetOwner = Class(function(self, inst)
	self.inst = inst
	self.pets = {}

	self.showPet = nil
end)

-- 添加宠物
function PetOwner:AddPet(pet)
	if pet and pet.components.aipc_petable ~= nil then
		local data = pet.components.aipc_petable:GetInfo()

		table.insert(self.pets, data)
	end

	self:ShowPet()
end

-- 展示宠物
function PetOwner:ShowPet()
	if self.showPet ~= nil then
		aipRemove(self.showPet)
	end

	local petData = self.pets[1]
	aipTypePrint("Show Pet:", petData)

	if petData ~= nil then
		local petPrefab = "aip_pet_"..petData.prefab
		local pet = aipSpawnPrefab(self.inst, petPrefab)
		pet.components.aipc_petable:SetInfo(petData, self.inst)

		aipSpawnPrefab(pet, "aip_shadow_wrapper").DoShow()
	end
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

	self.inst:DoTaskInTime(1, function()
		self:ShowPet()
	end)
end

return PetOwner