-- 一个只会飞行到目标地点的投掷物
local DivineRapier = Class(function(self, inst)
	self.inst = inst

	-- 需要守护的目标
	self.guardTarget = nil

	-- 临时攻击的目标
	self.attackTarget = nil

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

	aipPrint(now, dt)
end

return DivineRapier