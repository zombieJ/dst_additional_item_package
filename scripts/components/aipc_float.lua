-- 一个只会飞行到目标地点的投掷物
local Float = Class(function(self, inst)
	self.inst = inst
	self.targetPos = nil
	self.targetInst = nil
	self.speed = 6
	self.ySpeed = 6

	self.arriveCallback = nil -- 每次调用 MoveTo 都会重置这个方法
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
	self.targetInst = nil
	self.arriveCallbac = nil
	self.inst.Physics:Teleport(pt.x, pt.y, pt.z)

	self.inst:StartUpdatingComponent(self)
end

-- 飞向目标
function Float:MoveToPoint(pt, callback)
	self.targetPos = pt
	self.targetInst = nil
	self.arriveCallback = callback
	self.inst:StartUpdatingComponent(self)
end

function Float:MoveToInst(inst, callback)
	self.targetPos = nil
	self.targetInst = inst
	self.arriveCallback = callback
	self.inst:StartUpdatingComponent(self)
end

function Float:OnUpdate(dt)
	local pos = self.inst:GetPosition()
	local targetPos = self.targetPos or (
		self.targetInst ~= nil and self.targetInst:GetPosition()
	)

	if not targetPos then
		return
	end

	-- 水平方向的距离
	local dist = aipDist(pos, targetPos)
	local speed = self.speed
	if dist < 0.3 then
		speed = 0.5

		if self.arriveCallback ~= nil then
			self.arriveCallback(self.inst)
		end
	end

	-- 朝一个方向飞去
	self:RotateToTarget(targetPos)
	self.inst.Physics:SetMotorVel(
		speed,
		(targetPos.y - pos.y) * self.ySpeed,
		0
	)
end

return Float