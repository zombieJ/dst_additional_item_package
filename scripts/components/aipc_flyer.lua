-- 飞行器，玩家添加后会飞向目标地点。落地后删除该组件
local Flyer = Class(function(self, inst)
	self.inst = inst
	self.target = nil
	self.speed = 20
end)

function Flyer:FlyTo(target)
	self.target = target
	self.inst:StartUpdatingComponent(self)

	RemovePhysicsColliders(self.inst)
	self.inst.Physics:SetCollisionGroup(COLLISION.FLYERS)
	self.inst.Physics:SetMotorVel(self.speed, 1, 0)

	if self.inst.components.drownable then
		self.inst.components.drownable.enabled = false
	end
end

function Flyer:RotateToTarget(dest)
	local angle = aipGetAngle(self.inst:GetPosition(), dest)
	self.inst.Transform:SetRotation(angle)
	self.inst:FacePoint(dest)
end

function Flyer:End(target)
	ChangeToCharacterPhysics(self.inst)

	self.inst:RemoveComponent("aipc_flyer")
	self.inst:StopUpdatingComponent(self)

	if self.inst.components.drownable then
		self.inst.components.drownable.enabled = true
	end
end

function Flyer:OnUpdate(dt)
	if self.target == nil then
		-- 目标没了，不飞了
		aipPrint("no target")
		self:End()
	else
		-- 飞过去
		local instPos = self.inst:GetPosition()
		local pos = self.target:GetPosition()
		self:RotateToTarget(pos)
		-- self.inst.Transform:SetPosition(pos.x, pos.y, pos.z)

		local distance = distsq(instPos.x, instPos.z, pos.x, pos.z)
		aipPrint("dist", distance)
		if distance < 3 then
			aipPrint("less dist")
			self:End()
		else
			self:RotateToTarget(pos)
		end
	end

	
end

return Flyer