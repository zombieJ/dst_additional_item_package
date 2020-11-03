-- 一个只会飞行到目标地点的投掷物
local Projectile = Class(function(self, inst)
	self.inst = inst
	self.target = nil
	self.targetPos = nil
	self.speed = 6
	self.onFinish = nil
end)

-- 飞向目标
function Projectile:GoToTarget(target)
	self.target = target
	self.targetPos = self.target:GetPosition()

	self:Start()
end

-- 飞向目标点
function Projectile:GoToPoint(targetPos)
	self.target = nil
	self.targetPos = targetPos

	self:Start()
end

-- 执行
function Projectile:Start()
	self.inst:StartUpdatingComponent(self)
	self.inst.Physics:SetMotorVel(self.speed, 0, 0)
end

-- 转向目标点
function Projectile:RotateToTarget(dest)
	local angle = aipGetAngle(self.inst:GetPosition(), dest)
	self.inst.Transform:SetRotation(angle)
	self.inst:FacePoint(dest)
end

function Projectile:OnUpdate(dt)
	self:RotateToTarget(self.targetPos)

	if distsq(self.inst:GetPosition(), self.targetPos) < 0.3 then
		self.inst:StopUpdatingComponent(self)

		if self.onFinish ~= nil then
			self.onFinish(self.inst)
		end

		self.inst:Remove()
	end
end

return Projectile