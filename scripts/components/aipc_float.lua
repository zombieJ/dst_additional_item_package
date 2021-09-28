-- 一个只会飞行到目标地点的投掷物
local Float = Class(function(self, inst)
	self.inst = inst
	self.targetPos = nil
	self.speed = 6
	self.ySpeed = 6
end)

-- 转向目标点
function Float:RotateToTarget(dest)
	local angle = aipGetAngle(self.inst:GetPosition(), dest)
	self.inst.Transform:SetRotation(angle)
	self.inst:FacePoint(dest)
end

-- 重置坐标
function Float:GoToPoint(pt)
	self.targetPos = pt
	self.inst.Physics:Teleport(pt.x, pt.y, pt.z)

	self.inst:StartUpdatingComponent(self)
end

-- 飞向目标
function Float:MoveToPoint(pt)
	self.targetPos = pt
end

function Float:OnUpdate(dt)
	local pos = self.inst:GetPosition()
	if not self.targetPos then
		return
	end

	-- 水平方向的距离
	local dist = aipDist(pos, self.targetPos)
	local speed = self.speed
	if dist < 0.3 then
		speed = 0.5
	end

	-- 朝一个方向飞去
	self:RotateToTarget(self.targetPos)
	self.inst.Physics:SetMotorVel(
		speed,
		(self.targetPos.y - pos.y) * self.ySpeed,
		0
	)

	-- if self.debug then
		aipTypePrint(pos)
	-- end
end

return Float