local dev_mode = aipGetModConfig("dev_mode") == "enabled"


-- 双端通用，抓捕宠物组件
local PetOwner = Class(function(self, inst)
	self.inst = inst
	self.pets = {}
end)

-- 添加宠物
function PetOwner:AddPet(pet)
	-- table.insert(self.pets, {prefab = prefab, quality = quality})
end

return PetOwner