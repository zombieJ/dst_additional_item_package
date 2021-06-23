-- 一个只会飞行到目标地点的投掷物
local ScoreBall = Class(function(self, inst)
	self.inst = inst
	self.speed = 0
end)

function ScoreBall:Launch(attacker)
	local srcPos = self.inst:GetPosition()
	local angle = aipGetAngle(attacker:GetPosition(), srcPos)
	local radius = angle / 180 * PI
	local tgtPos = Vector3(srcPos.x + math.cos(radius), 0, srcPos.z + math.sin(radius))
	self.inst.Transform:SetRotation(angle)
	self.inst:FacePoint(tgtPos)

	self.speed = 5
	self.inst.Physics:SetMotorVel(self.speed, 0, 0)

	self.inst:StartUpdatingComponent(self)
end

function ScoreBall:OnUpdate(dt)
	aipTypePrint(dt)

	self.speed = self.speed * 0.9

	if self.speed < 0.01 then
		self.speed = 0
		self.inst:StopUpdatingComponent(self)
	end

	self.inst.Physics:SetMotorVel(self.speed, 0, 0)
end

return ScoreBall