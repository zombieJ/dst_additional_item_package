-- 一个只会飞行到目标地点的投掷物
local DivineRapier = Class(function(self, inst)
	self.inst = inst

	-- 需要守护的目标
	self.guardTarget = nil

	-- 临时攻击的目标
	self.attackTarget = nil

	-- 设置转一圈要多少秒
	self.roundTime = 2

	-- 设置旋转距离
	self.roundDist = 2

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


function DivineRapier:OnUpdate(dt)
	local currentPos = self.inst:GetPosition()
	local guardPos = self.guardTarget:GetPosition()
	local rawDist = aipDist(currentPos, guardPos)

	-- 是否在环绕范围内
	local roundRange = self.roundDist * 1.25
	local isInRound = rawDist < roundRange

	-- 当远离环绕距离的时候，先尝试追上目标，反之则去环绕点
	local roundPt = self:GetRoundPt()
	local tgtPt = isInRound and roundPt or guardPos

	local oriAngle = self.inst:GetRotation()
	local tgtAngle = self.inst:GetAngleToPoint(tgtPt.x, tgtPt.y, tgtPt.z)

	-- 旋转角度速度
	local angleSpeedPerSec = 360 / self.roundTime
	angleSpeedPerSec = angleSpeedPerSec * 2 -- 追速补偿

	local angle = aipToAngle(oriAngle, tgtAngle, dt * angleSpeedPerSec)
	self.inst.Transform:SetRotation(
		isInRound and tgtAngle or angle -- 在范围内，就直接进入环绕状态
	)

	-- 周长计算 & 旋转速度
	local dist = aipDist(currentPos, roundPt)

	local perimeter = 2 * PI * self.roundDist
	local baseSpeed = perimeter / self.roundTime
	local minSpeed = baseSpeed * 0.5
	local maxSpeed = baseSpeed + TUNING.WILSON_RUN_SPEED * 5 -- 追速补偿

	local catchDist = roundRange -- perimeter * 0.8
	local speed = dist > catchDist and maxSpeed or Remap(dist, 0, catchDist, minSpeed, maxSpeed)
	self.inst.Physics:SetMotorVel(speed, 0, 0)
end

return DivineRapier