-- 一个只会飞行到目标地点的投掷物
local ScoreBall = Class(function(self, inst)
	self.inst = inst
	self.ball = nil
	self.speed = 0
	self.ySpeed = 0
	self.recordSpeed = 0 -- 启动时的 x 速度，每次落地都会减少一些
	self.yRecordSpeed = 0 -- 启动时的 y 速度，每次落地都会减少一些
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

function ScoreBall:Launch(speed, ySpeed)
	-- 初始化马甲
	self:ResetMotion()

	-- 初始化速度
	self.speed = speed
	self.ySpeed = ySpeed
	self.recordSpeed = speed
	self.yRecordSpeed = ySpeed

	self.fullTime = 1
	self.walkTime = 0

	self.inst.Physics:SetMotorVel(self.speed, 0, 0)
	self.ball.Physics:SetMotorVel(0, self.ySpeed, 0)

	self.inst:StartUpdatingComponent(self)

	self.inst.components.health:SetInvincible(true)
end

function ScoreBall:Kick(attacker, speed, ySpeed) -- 攻击球
	local srcPos = self.inst:GetPosition()
	local angle = aipGetAngle(attacker:GetPosition(), srcPos)
	local radius = angle / 180 * PI
	local tgtPos = Vector3(srcPos.x + math.cos(radius), 0, srcPos.z + math.sin(radius))
	self.inst.Transform:SetRotation(angle)
	self.inst:FacePoint(tgtPos)

	self:Launch(speed, ySpeed)
end

function ScoreBall:OnUpdate(dt)
	self.walkTime = self.walkTime + dt

	local ySpeed = (self.fullTime - self.walkTime) / self.fullTime * self.ySpeed

	self.inst.Physics:SetMotorVel(self.speed, 0, 0)
	self.ball.Physics:SetMotorVel(0, ySpeed, 0)

	-- 退出判断
	local x, y, z = self.ball.Transform:GetWorldPosition()

	-- 超过 2 格时不允许被攻击
	if y <= 2 then
		self.inst.components.health:SetInvincible(false)
	end

	-- 落地判断
	if self.walkTime >= self.fullTime and y < 0.05 then
		self:ResetMotion()
		self.ball.Physics:Teleport(0, 0, 0)
		self.inst:StopUpdatingComponent(self)

		-- 如果还有一些速度，我们就弹起来
		self.recordSpeed = self.recordSpeed / 2
		self.yRecordSpeed = self.yRecordSpeed / 3 * 2
		aipTypePrint(self.yRecordSpeed)
		if self.recordSpeed > .5 and self.yRecordSpeed >= 1 then
			self:Launch(self.recordSpeed, self.yRecordSpeed)
		end
	end
end

return ScoreBall