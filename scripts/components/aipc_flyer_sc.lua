-- 禁止所有动作
local function ActionButton(inst, force_target)
	return
end

local function FlyActionFilter(inst, action)
	return false
end


-- 飞行器，玩家添加后会飞向目标地点。落地后删除该组件
local Flyer = Class(function(self, inst)
	self.inst = inst
	self.target = nil
	self.speed = 50
	self.height = 3

	self.isFlying = net_bool(inst.GUID, "aipc_flyer_flying", "aipc_flyer_flying_dirty")
	self.isFlying:set(false)
end)

function Flyer:IsFlying()
	return self.isFlying:value()
end

function Flyer:RotateToTarget(dest)
	local angle = aipGetAngle(self.inst:GetPosition(), dest)
	self.inst.Transform:SetRotation(angle)
	self.inst:FacePoint(dest)
end

function Flyer:FlyTo(target)
	self.target = target

	RemovePhysicsColliders(self.inst)
	self.inst.Physics:SetCollisionGroup(COLLISION.FLYERS)
	self.inst.Physics:ClearCollisionMask()

	if self.inst.components.drownable then
		self.inst.components.drownable.enabled = false
	end

	if self.inst.components.playercontroller ~= nil then
		self.inst.components.playercontroller.actionbuttonoverride = ActionButton
		self.inst.components.playercontroller:Enable(false)
	end

	if self.inst.components.playeractionpicker ~= nil then
		self.inst.components.playeractionpicker:PushActionFilter(FlyActionFilter, 999)
	end

	self.inst:StartUpdatingComponent(self)

	self.isFlying:set(true)
end

function Flyer:End(target)
	ChangeToCharacterPhysics(self.inst)
	self.inst.Physics:SetMotorVel(0, 0, 0)

	self.inst:StopUpdatingComponent(self)

	if self.inst.components.drownable then
		self.inst.components.drownable.enabled = true
	end

	if self.inst.components.playercontroller ~= nil then
		self.inst.components.playercontroller.actionbuttonoverride = nil
		self.inst.components.playercontroller:Enable(true)
	end

	if self.inst.components.playeractionpicker ~= nil then
		self.inst.components.playeractionpicker:PopActionFilter(FlyActionFilter, 999)
	end

	if self.inst.components.locomotor then
		self.inst.components.locomotor:Stop()
	end

	self.isFlying:set(false)
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

		-- 调整速度
		self:RotateToTarget(pos)
		self.inst.Physics:SetMotorVel(self.speed, (self.height - instPos.y) * 2, 0)

		local distance = distsq(instPos.x, instPos.z, pos.x, pos.z)
		if distance < 2 then
			self.inst.Transform:SetPosition(pos.x, pos.y, pos.z)
			self:End()
		else
			self:RotateToTarget(pos)
		end
	end

	
end

return Flyer