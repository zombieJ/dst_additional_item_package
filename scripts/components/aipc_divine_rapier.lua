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

	-- 根据游戏进行时间设定围绕坐标，用于计算目标点
	self.index = 0
	self.total = 0
end)

function DivineRapier:Setup(guardTarget, index, total)
	self.guardTarget = guardTarget
	self.index = index
	self.total = total

	self.inst:StartUpdatingComponent(self)
end


function DivineRapier:OnUpdate(dt)
	-- 获取系统时间
	local now = GetTime()

	-- 当前转的角度
	local rotate = (now % self.roundTime) * (360 / self.roundTime)
	local radius = rotate / 180 * PI

	local pos = self.guardTarget:GetPosition()

	local tgtPt = Vector3(
		pos.x + math.cos(radius) * self.roundDist,
		0,
		pos.z + math.sin(radius) * self.roundDist
	)

	self.inst.Physics:Teleport(tgtPt.x, tgtPt.y, tgtPt.z)
	self.inst:ForceFacePoint(pos.x, pos.y, pos.z)

	aipPrint(now, self.roundTime, now % self.roundTime, rotate, (self.inst:GetRotation() + 360) % 360)

	-- aipPrint(now, dt)
end

return DivineRapier