-- 一个只会飞行到目标地点的投掷物
local ScoreBall = Class(function(self, inst)
	self.inst = inst
	self.ball = nil
	self.speed = 0
	self.ySpeed = 0
	self.fullTime = 0
	self.walkTime = 0
end)

function ScoreBall:BindVest(ball)
	self.ball = ball
end

function ScoreBall:ResetMotion()
	self.ball.Physics:SetMotorVel(0, 0, 0)
	self.ball.Physics:Stop()

	self.inst.Physics:SetMotorVel(0, 0, 0)
	self.inst.Physics:Stop()
end

function ScoreBall:Launch(attacker, speed, ySpeed)
	local srcPos = self.inst:GetPosition()
	local angle = aipGetAngle(attacker:GetPosition(), srcPos)
	local radius = angle / 180 * PI
	local tgtPos = Vector3(srcPos.x + math.cos(radius), 0, srcPos.z + math.sin(radius))
	self.inst.Transform:SetRotation(angle)
	self.inst:FacePoint(tgtPos)

	-- 初始化马甲
	self:ResetMotion()

	-- 初始化速度
	self.speed = speed
	self.ySpeed = ySpeed

	self.fullTime = 1
	self.walkTime = 0

	self.inst.Physics:SetMotorVel(self.speed, 0, 0)
	self.ball.Physics:SetMotorVel(0, self.ySpeed, 0)

	self.inst:StartUpdatingComponent(self)

	self.inst.components.health:SetInvincible(true)
end

function ScoreBall:OnUpdate(dt)
	self.walkTime = self.walkTime + dt

	local ySpeed = (self.fullTime - self.walkTime) / self.fullTime * self.ySpeed

	self.inst.Physics:SetMotorVel(self.speed, 0, 0)
	self.ball.Physics:SetMotorVel(0, ySpeed, 0)

	-- 退出判断
	local x, y, z = self.ball.Transform:GetWorldPosition()

	if y <= 2 then
		self.inst.components.health:SetInvincible(false)
	end

	if self.walkTime >= self.fullTime and y < 0.05 then
		self:ResetMotion()
		self.ball.Physics:Teleport(0, 0, 0)
		self.inst:StopUpdatingComponent(self)
	end
end

return ScoreBall