-- 禁止所有动作
local function ActionButton(inst, force_target)
	return
end

local function FlyActionFilter(inst, action)
	return false
end


-- 飞行器【server & client】，玩家添加后会飞向目标地点。落地后删除该组件
local Flyer = Class(function(self, inst)
	self.inst = inst
	self.target = nil
	self.speed = 50
	self.height = 3
	self.cloud = nil

	self.isFlying = net_bool(inst.GUID, "aipc_flyer_flying", "aipc_flyer_flying_dirty")
	self.isFlying:set(false)

	self.inst:ListenForEvent("aipc_flyer_flying_dirty", function()
		-- 仅对当前玩家锁定屏幕
		if self.inst == ThePlayer then
			if self:IsFlying() then
				TheCamera:SetFlyView()
			else
				TheCamera:SetDefault()
			end
		end
	end)
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

	-- 淹不死
	if self.inst.components.drownable then
		self.inst.components.drownable.enabled = false
	end

	-- 不让控制
	if self.inst.components.playercontroller ~= nil then
		self.inst.components.playercontroller.actionbuttonoverride = ActionButton
		self.inst.components.playercontroller:Enable(false)
	end

	if self.inst.components.playeractionpicker ~= nil then
		self.inst.components.playeractionpicker:PushActionFilter(FlyActionFilter, 999)
	end

	-- 添加云
	self.cloud = self.inst:SpawnChild('aip_fly_totem_cloud')

	-- 开始更新
	self.inst:StartUpdatingComponent(self)

	self.isFlying:set(true)
end

function Flyer:End(target)
	ChangeToCharacterPhysics(self.inst)

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

	-- 删除云
	if self.cloud then
		self.cloud:DeCloud(self.inst)
		self.cloud = nil
	end

	self.inst.Physics:SetMotorVel(0, -5, 0)

	self.isFlying:set(false)
end

function Flyer:OnUpdate(dt)
	if self.target == nil or (self.inst.components.health and self.inst.components.health:IsDead()) then
		-- 目标没了 or 玩家死了，结束飞行
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
		if distance < 4 then
			-- self.inst.Transform:SetPosition(pos.x, pos.y, pos.z)
			self:End()
		else
			self:RotateToTarget(pos)
		end
	end

	
end

return Flyer