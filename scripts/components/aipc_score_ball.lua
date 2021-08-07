local function onReset(inst)
	local asb = inst.components.aipc_score_ball
	if asb ~= nil then
		asb:ResetAll()
	end
end

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
	self.downTimes = 0
	self.startTimes = 0
	self.throwTimes = 0
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

function ScoreBall:ResetAll()
	self:ResetMotion()
	self.startTimes = 0
	self.downTimes = 0
	self.throwTimes = 0 -- 仅仅计算若光的次数
	self.playerThrow = false -- 玩家丢起的球？

	self.ball.Physics:Teleport(0, 0, 0)
	self.ball.AnimState:Pause()
	self.inst:StopUpdatingComponent(self)
end

function ScoreBall:Launch(speed, ySpeed, continueBump)
	-- 播放动画
	if continueBump ~= true then
		local anim = math.random() > .5 and "runLeft" or "runRight"

		if self.ball.AnimState:IsCurrentAnimation("idle") then
			self.ball.AnimState:PlayAnimation(anim, true)
		elseif not self.ball.AnimState:IsCurrentAnimation(anim) then
			local len = self.ball.AnimState:GetCurrentAnimationLength() / FRAMES
			local time = self.ball.AnimState:GetCurrentAnimationTime()
			local reverseTime = len - time
			self.ball.AnimState:PlayAnimation(anim, true)
			self.ball.AnimState:SetTime(math.max(reverseTime, 1))
		end
	end
	self.ball.AnimState:SetDeltaTimeMultiplier(0.5 + speed * 2)
	self.ball.AnimState:Resume()

	-- 初始化马甲
	self:ResetMotion()
	self.startTimes = self.startTimes + 1

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
	self.inst.components.inventoryitem.canbepickedup = false

	self.inst:ListenForEvent("ondropped", onReset)
	self.inst:ListenForEvent("onpickup", onReset)
end

function ScoreBall:ResetThrowCount()
	local miniDou = FindEntity(self.inst, 15, nil, { "aip_mini_doujiang" })
	if miniDou ~= nil and miniDou.aipPlayEnd ~= nil and self.throwTimes ~= 0 then
		miniDou.aipPlayEnd(miniDou, self.throwTimes)
	end

	self.throwTimes = 0
end

function ScoreBall:Throw(tgtPos, speed, ySpeed) -- 若光技能
	self.throwTimes = self.throwTimes + 1
	self.playerThrow = false
	self:InternalThrow(tgtPos, speed, ySpeed)
end

function ScoreBall:InternalThrow(tgtPos, speed, ySpeed) -- 朝着方向扔球
	local srcPos = self.inst:GetPosition()
	local angle = aipGetAngle(tgtPos, srcPos)
	self.inst.Transform:SetRotation(angle)
	self.inst:FacePoint(tgtPos)

	self.startTimes = 0
	self.downTimes = 0

	self:Launch(speed, ySpeed)
end

function ScoreBall:Kick(attacker, speed, ySpeed) -- 攻击球
	local srcPos = self.inst:GetPosition()
	local angle = aipGetAngle(attacker:GetPosition(), srcPos)
	local radius = angle / 180 * PI
	local tgtPos = Vector3(srcPos.x + math.cos(radius), 0, srcPos.z + math.sin(radius))

	self.playerThrow = true

	self:InternalThrow(tgtPos, speed, ySpeed)
end

-- 若光可以跟着球跑
function ScoreBall:CanFollow()
	local x, y, z = self.ball.Transform:GetWorldPosition()
	-- 球下落中 或者 飞起一段距离后
	return self.playerThrow and (
		(self.startTimes == 1 and (self.downTimes == 1 or y > 7)) or -- 第一次飞起 7 高度或下落中
		(self.startTimes == 2) -- 第二次飞起
	)
end

-- 若光可以击球
function ScoreBall:CanThrow()
	local x, y, z = self.ball.Transform:GetWorldPosition()
	return self:CanFollow() and (
		(self.downTimes == 1 and y < 1.5) or -- 第一次下落至 1.5 高度
		(self.startTimes == 2 and y < 1) -- 第二次 1.3 高度内
	)
end

function ScoreBall:OnUpdate(dt)
	local prevWalkTime = self.walkTime
	self.walkTime = self.walkTime + dt

	local ySpeed = (self.fullTime - self.walkTime) / self.fullTime * self.ySpeed

	self.inst.Physics:SetMotorVel(self.speed, 0, 0)
	self.ball.Physics:SetMotorVel(0, ySpeed, 0)

	if prevWalkTime <= self.fullTime and self.fullTime < self.walkTime then
		self.downTimes = self.downTimes + 1

		-- 如果弹了三次就重置扔球时间
		if self.downTimes >= 3 then
			self:ResetThrowCount()
		end
	end

	-- 退出判断
	local x, y, z = self.ball.Transform:GetWorldPosition()

	-- 超过 2.5 格时不允许被攻击
	local canInteractive = y <= 2.5
	self.inst.components.health:SetInvincible(not canInteractive)
	self.inst.components.inventoryitem.canbepickedup = canInteractive

	-- 落地判断
	if self.walkTime >= self.fullTime and y < 0.05 then
		-- 如果还有一些速度，我们就弹起来
		self.recordSpeed = self.recordSpeed / 2
		self.yRecordSpeed = self.yRecordSpeed / 3 * 2

		if self.recordSpeed > .2 and self.yRecordSpeed >= 1 then
			self:Launch(self.recordSpeed, self.yRecordSpeed, true)
		else
			self:ResetAll()
			self:ResetThrowCount() -- 不弹起则重置扔球时间
		end
	end
end

return ScoreBall