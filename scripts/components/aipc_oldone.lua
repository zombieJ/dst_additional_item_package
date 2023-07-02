local dev_mode = aipGetModConfig("dev_mode") == "enabled"

-- 每天白天恢复一次因子对应的生命值
local function OnIsDay(inst, isday)
	if not isday or inst == nil or not inst:IsValid() or inst.components.aipc_oldone == nil then
		return
	end

	local factor = inst.components.aipc_oldone:GetCalFactor()

    if inst.components.health ~= nil then
		local restHealth = inst.components.health:GetMaxWithPenalty() - inst.components.health.currenthealth

		-- 有谜团因子才会出现特效
		if factor > 0 then
			aipSpawnPrefab(inst, "farm_plant_happy")
		end

		inst.components.health:DoDelta(factor)
		factor = factor - restHealth
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
	self.worldDropTimes = 0 -- 记录玩家世界掉落次数

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

function Oldone:GetWorldDropTimes()
	return self.worldDropTimes or 0
end


function Oldone:DoWorldDropTimesDelta(offset)
	self.worldDropTimes = self:GetWorldDropTimes() + offset
end

------------------------------- 存取 -------------------------------
function Oldone:OnSave()
    return {
        factor = self.factor,
		worldDropTimes = self.worldDropTimes,
    }
end

function Oldone:OnLoad(data)
	if data.factor ~= nil then
		self.factor = data.factor
		self.worldDropTimes = data.worldDropTimes
	end
end

return Oldone