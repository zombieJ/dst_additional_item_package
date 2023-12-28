-- 一个只会飞行到目标地点的投掷物
local DivineRapier = Class(function(self, inst)
	self.inst = inst

	-- 需要守护的目标
	self.guardTarget = nil

	-- 临时攻击的目标
	self.attackTarget = nil

	-- 设置转一圈要多少秒
	self.roundTime = 1

	-- 设置旋转距离
	self.roundDist = 2

	self.isRounding = false

	-- -- 最大移动速度
	-- self.maxSpeed = 10
	-- self.maxSpeedDist = 1

	-- 根据游戏进行时间设定围绕坐标，用于计算目标点
	self.index = 0
	self.total = 0
end)

function DivineRapier:GetRoundPt()
	-- 获取系统时间
	local now = GetTime()

	-- 当前转的角度
	local rotate = (now % self.roundTime) * (360 / self.roundTime)
	local radius = rotate / 180 * PI

	local pos = self.guardTarget:GetPosition()

	-- 计算环绕所需的目标点
	local tgtPt = Vector3(
		pos.x + math.cos(radius) * self.roundDist,
		0,
		pos.z + math.sin(radius) * self.roundDist
	)

	return tgtPt
end

function DivineRapier:Setup(guardTarget, index, total)
	self.guardTarget = guardTarget
	self.index = index
	self.total = total

	local tgtPt = self:GetRoundPt()
	self.inst:ForceFacePoint(tgtPt.x, tgtPt.y, tgtPt.z)
	-- self.inst.Physics:SetMotorVel(self.maxSpeed, 0, 0)

	self.inst:StartUpdatingComponent(self)
end

-- 角度速，返回 360 度的角度
function DivineRapier:GetAngleSpeed()
	return 360 / self.roundTime
end

-- 返回线速度
function DivineRapier:GetLineSpeed()
	local angleSpeed = self:GetAngleSpeed()
	local rotateSpeed = angleSpeed / 180 * PI
	return rotateSpeed * self.roundDist
end

-- 飞向守卫目标
function DivineRapier:OnFollowUpdate(dt)
	local roundPt = self:GetRoundPt()

	local oriAngle = self.inst:GetRotation()
	local tgtAngle = self.inst:GetAngleToPoint(roundPt.x, roundPt.y, roundPt.z)

	-- 旋转角度速度
	local angleSpeedPerSec = 360 / self.roundTime
	angleSpeedPerSec = angleSpeedPerSec * 3 -- 追速补偿

	local angle = aipToAngle(oriAngle, tgtAngle, dt * angleSpeedPerSec)
	self.inst.Transform:SetRotation(angle)

	-- 设置飞行速度
	self.inst.Physics:SetMotorVel(self:GetLineSpeed() * 2, 0, 0)
end

-- 环绕守卫目标
function DivineRapier:OnRoundUpdate(dt)
	local currentPos = self.inst:GetPosition()
	local roundPt = self:GetRoundPt()
	local guardPt = self.guardTarget:GetPosition()

	local dist = aipDist(currentPos, roundPt)

	-- 我们按照剑所在位置使用力做偏移
	self.inst:ForceFacePoint(roundPt.x, roundPt.y, roundPt.z)
	-- self.inst:ForceFacePoint(guardPt.x, guardPt.y, guardPt.z)
	-- self.inst.Transform:SetRotation(self.inst:GetRotation() + 90)

	-- 计算当前施加速度的偏移角度
	local speed = dist * 10
	local faceAngle = self.inst:GetAngleToPoint(roundPt.x, roundPt.y, roundPt.z)
	local faceX = math.cos(faceAngle / 180 * PI) * speed
	local faceZ = -math.sin(faceAngle / 180 * PI) * speed

	local corrected_vel_x, corrected_vel_z = VecUtil_RotateDir(faceX, faceZ, self.inst.Transform:GetRotation() * DEGREES)
	self.inst.Physics:SetMotorVel(corrected_vel_x, 0, corrected_vel_z)
	-- self.inst.Physics:Stop()

	aipTypePrint("currentPos:", currentPos)
	aipTypePrint("guardPt:", guardPt)
	aipTypePrint("roundPt:", roundPt)
	aipPrint("Current Angle:", self.inst:GetRotation())
	aipTypePrint("faceAngle:", faceAngle)
	aipPrint("faceXZ:", faceX, faceZ)
	aipPrint("correctedXZ:", corrected_vel_x, corrected_vel_z)

	-------------------------------------------------------------------
	-- -- 尝试固定位置的实现方式
	-- self.inst.Physics:Teleport(roundPt.x, roundPt.y, roundPt.z)
	-- self.inst:ForceFacePoint(guardPt.x, guardPt.y, guardPt.z)
	-- self.inst.Transform:SetRotation(self.inst:GetRotation() + 90)
	-- -- self.inst.Physics:Stop()
	-- self.inst.Physics:SetMotorVel(self:GetLineSpeed(), 0, 0)

	-------------------------------------------------------------------
	-- self.inst:ForceFacePoint(roundPt.x, roundPt.y, roundPt.z)

	-- -- 加速距离计算
	-- local maxDist = self.roundDist
	-- local dist = Clamp(aipDist(currentPos, roundPt), 0, maxDist)

	-- -- -- 设置飞行速度
	-- local baseSpeed = self:GetLineSpeed()
	-- local maxSpeed = baseSpeed + TUNING.WILSON_RUN_SPEED * 5 -- 追速补偿
	-- local speed = Remap(dist, 0, maxDist, baseSpeed, maxSpeed)

	-- self.inst.Physics:SetMotorVel(speed, 0, 0)
end

function DivineRapier:OnUpdate(dt)
	local currentPos = self.inst:GetPosition()
	local roundPt = self:GetRoundPt()

	-- 当前与目标的距离
	local dist = aipDist(currentPos, roundPt)

	-- 如果靠近环绕点，则进入环绕状态
	if dist < 0.5 then
		self.isRounding = true
	end

	if self.isRounding then
		self:OnRoundUpdate(dt)
	else
		self:OnFollowUpdate(dt)
	end
end

	-- local currentPos = self.inst:GetPosition()
	-- local guardPos = self.guardTarget:GetPosition()
	-- local rawDist = aipDist(currentPos, guardPos)

	-- -- 是否在环绕范围内
	-- local roundRange = self.roundDist * 1.1
	-- local isInRound = rawDist < roundRange

	-- -- 切换状态
	-- if isInRound and not self:IsRounding() then
	-- 	self.guardTarget:AddChild(self.inst)
	-- elseif not isInRound and self:IsRounding() then
	-- 	elf.guardTarget:RemoveChild(self.inst)
	-- end

	-- if not self:IsRounding() then
	-- 	return
	-- end

	-- -- 当远离环绕距离的时候，先尝试追上目标，反之则去环绕点
	-- local roundPt = self:GetRoundPt()
	-- local tgtPt = isInRound and roundPt or guardPos

	-- local oriAngle = self.inst:GetRotation()
	-- local tgtAngle = self.inst:GetAngleToPoint(tgtPt.x, tgtPt.y, tgtPt.z)

	-- -- 旋转角度速度
	-- local angleSpeedPerSec = 360 / self.roundTime
	-- angleSpeedPerSec = angleSpeedPerSec * 2 -- 追速补偿

	-- local angle = aipToAngle(oriAngle, tgtAngle, dt * angleSpeedPerSec)
	-- self.inst.Transform:SetRotation(
	-- 	isInRound and tgtAngle or angle -- 在范围内，就直接进入环绕状态
	-- )

	-- -- 周长计算 & 旋转速度
	-- local dist = aipDist(currentPos, roundPt)

	-- local perimeter = 2 * PI * self.roundDist
	-- local baseSpeed = perimeter / self.roundTime
	-- local minSpeed = baseSpeed * 0.5
	-- local maxSpeed = baseSpeed + TUNING.WILSON_RUN_SPEED * 5 -- 追速补偿

	-- local catchDist = roundRange -- perimeter * 0.8
	-- local speed = dist > catchDist and maxSpeed or Remap(dist, 0, catchDist, minSpeed, maxSpeed)
	-- self.inst.Physics:SetMotorVel(speed, 0, 0)

return DivineRapier