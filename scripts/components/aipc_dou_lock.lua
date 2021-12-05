local INTERVAL = 0.05
local SPEED = 0.3

local Lock = Class(function(self, inst)
	self.inst = inst
	self.targetPT = nil
	self.lastDist = 999999999

	self.task = self.inst:DoPeriodicTask(INTERVAL, function()
		self:SyncPos()
	end)
end)

function Lock:Stop()
	if self.task ~= nil then
		self.task:Cancel()
		self.task = nil
	end

	self.inst:RemoveComponent("aipc_dou_lock")
end

function Lock:SyncPos()
	local pos = self.inst:GetPosition()

	if self.targetPT == nil or not self.inst:IsValid() or not self.inst.Physics then
		self:Stop()
		return
	end

	-- 如果到位置 或者 位移反而变远了
	local dist = aipDist(pos, self.targetPT)
	if self.lastDist < dist or dist < 0.2 then
		self.inst.Physics:Teleport(self.targetPT.x, pos.y, self.targetPT.z)
		self:Stop()
		return
	end
	self.lastDist = dist

	-- 没到位置，我们继续位移
	local diffSpeed = 1 - SPEED
	local newPos = Vector3(
		pos.x * diffSpeed + self.targetPT.x * SPEED,
		pos.y, -- y 坐标不用变
		pos.z * diffSpeed + self.targetPT.z * SPEED
	)
	self.inst.Physics:Stop()
	self.inst.Physics:Teleport(newPos.x, newPos.y, newPos.z)
end

return Lock