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

	-- 最大移动速度
	self.maxSpeed = 10
	self.maxSpeedDist = 1

	-- 最大转角速度
	self.maxRotateSpeed = 360

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
	self.inst.Physics:SetMotorVel(self.maxSpeed, 0, 0)

	self.inst:StartUpdatingComponent(self)
end


function DivineRapier:OnUpdate(dt)
	local tgtPt = self:GetRoundPt()

	local oriAngle = self.inst:GetRotation()
	local tgtAngle = self.inst:GetAngleToPoint(tgtPt.x, tgtPt.y, tgtPt.z)

	local angle = aipToAngle(oriAngle, tgtAngle, dt * self.maxRotateSpeed)
	self.inst.Transform:SetRotation(angle)

	-- 与目标点距离
	local dist = aipDist(self.inst:GetPosition(), tgtPt)
	local clapDist = Clamp(dist, 0, self.maxSpeedDist)

	-- 动态速度
	local speed = Remap(clapDist, 0, self.maxSpeedDist, 0, self.maxSpeed)-- 对齐到距离速度上
	self.inst.Physics:SetMotorVel(speed, 0, 0)

	-- -- 移动到目标点
	-- self.inst.Physics:Teleport(tgtPt.x, tgtPt.y, tgtPt.z)
	-- self.inst:ForceFacePoint(pos.x, pos.y, pos.z)
end

return DivineRapier