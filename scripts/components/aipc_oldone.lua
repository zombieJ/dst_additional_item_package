local dev_mode = aipGetModConfig("dev_mode") == "enabled"

------------------------------- 组件 -------------------------------
local Oldone = Class(function(self, inst)
	self.inst = inst

	self.factor = 0
end)

------------------------------- 方法 -------------------------------
function Oldone:DoDelta(amount)
	amount = amount or 1

	self.factor = self.factor + amount
	if amount > 0 then
		aipSpawnPrefab(self.inst, "farm_plant_happy")
	elseif amount < 0 then
		aipSpawnPrefab(self.inst, "farm_plant_unhappy")
	end
end

------------------------------- 存取 -------------------------------
function Oldone:OnSave()
    return {
        health = self.factor,
    }
end

function Oldone:OnLoad(data)
	if data.factor ~= nil then
		self.factor = data.factor
	end
end

return Oldone