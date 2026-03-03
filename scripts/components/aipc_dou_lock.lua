local Lock = Class(function(self, inst)
	self.inst = inst
	self.speed = 10
	self.targetPT = nil
	self.lastDist = 999999999
end)

function Lock:CheckPhysics()
	return self.inst.Physics ~= nil
end

function Lock:Stop()
	if not self:CheckPhysics() then
		return
	end

	if self.task ~= nil then
		self.task:Cancel()
		self.task = nil
	end

	self.inst:StopUpdatingComponent(self)
	self.inst:RemoveComponent("aipc_dou_lock")
end

-- 转向目标点
function Lock:RotateToTarget(dest)
	if not self:CheckPhysics() then
		return
	end

	self.inst:ForceFacePoint(dest)
end

function Lock:LockTo(pt)
	if not self:CheckPhysics() then
		return
	end

	self.targetPT = pt
	self.lastDist = 999999999

	self.inst.Physics:Stop()
	self.inst:StartUpdatingComponent(self)
end

function Lock:OnUpdate(dt)
	if not self:CheckPhysics() then
		return
	end

	local src = self.inst:GetPosition()

	-- 如果不合法就退出位移
	if self.targetPT == nil or not self.inst:IsValid() then
		self:Stop()
		return
	end

	-- 计算当前角度 并 移动
	self:RotateToTarget(self.targetPT)
	self.inst.Physics:SetMotorVel(self.speed, 0, 0)

	-- 如果到位置 或者 位移反而变远则停止
	local dist = aipDist(src, self.targetPT)
	if
		self.lastDist < dist or
		dist < 0.2
	then
		self.inst.Physics:Teleport(self.targetPT.x, src.y, self.targetPT.z)
		self.inst.Physics:Stop()
		self:Stop()
		return
	end
	self.lastDist = dist
end

return Lock