local dev_mode = aipGetModConfig("dev_mode") == "enabled"

-- 每天白天恢复一次因子对应的生命值
local function OnIsDay(inst, isday)
	if not isday or inst == nil or not inst:IsValid() or inst.components.aipc_oldone == nil then
		return
	end

	local factor = inst.components.aipc_oldone:GetCalFactor()

    if inst.components.health ~= nil then
		local restHealth = inst.components.health:GetMaxWithPenalty() - inst.components.health.currenthealth

		inst.components.health:DoDelta(restHealth)
		factor = factor - restHealth

		aipSpawnPrefab(inst, "farm_plant_happy")
    end

	-- 如果有剩余，则给 血精石 充能
	if factor > 0 then
		local pt = inst:GetPosition()

		local stones = TheSim:FindEntities(pt.x, pt.y, pt.z, 0.1, { "aip_bloodstone" })
		local first = stones[1]
		if first ~= nil and first.components.finiteuses ~= nil then
			first.components.finiteuses:Use(-factor)

			if first.components.finiteuses:GetPercent() > 1 then
				first.components.finiteuses:SetPercent(1)
			end
		end
	end
end

------------------------------- 组件 -------------------------------
local Oldone = Class(function(self, inst)
	self.inst = inst

	self.factor = 0

	self.inst:WatchWorldState("isday", OnIsDay)
end)

------------------------------- 方法 -------------------------------
function Oldone:GetCalFactor()
	return self.factor + (dev_mode and 10 or 0)
end

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