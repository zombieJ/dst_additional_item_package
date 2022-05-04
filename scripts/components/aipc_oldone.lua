local dev_mode = aipGetModConfig("dev_mode") == "enabled"

-- 每天白天恢复一次因子对应的生命值
local function OnIsDay(inst, isday)
    if
		isday and inst ~= nil and inst:IsValid() and
		inst.components.aipc_oldone ~= nil and inst.components.health ~= nil and
		inst.components.aipc_oldone.factor > 0
	then
		inst.components.health:DoDelta(
			inst.components.aipc_oldone.factor
		)

		aipSpawnPrefab(inst, "farm_plant_happy")
    end
end

------------------------------- 组件 -------------------------------
local Oldone = Class(function(self, inst)
	self.inst = inst

	self.factor = 0

	self.inst:WatchWorldState("isday", OnIsDay)
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

	if dev_mode then
		aipPrint("增加谜团因子：", amount)
	end
end

------------------------------- 存取 -------------------------------
function Oldone:OnSave()
    return {
        factor = self.factor,
    }
end

function Oldone:OnLoad(data)
	if data.factor ~= nil then
		self.factor = data.factor
	end
end

return Oldone