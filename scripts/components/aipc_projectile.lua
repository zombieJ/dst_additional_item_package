local COMBAT_TAGS = { "_combat" }
local NO_TAGS = { "player" }

local function isLine(action)
	return action == nil or action == "LINE" or action == "THROUGH"
end

local Projectile = Class(function(self, inst)
	self.inst = inst
	self.speed = 25
	self.launchoffset = Vector3(0.25, 2, 0)

	self.doer = nil
	self.queue = {}

	-- Task
	self.task = nil
	self.target = nil
	self.targetPos = nil
	self.distance = nil

	-- 超时可能投掷物已经卡死，删除之
	inst:DoTaskInTime(120, function(inst)
		inst:Remove()
	end)
end)

function Projectile:CalculateTask()
	local task = self.queue[1]
	table.remove(self.queue, 1)

	self.task = task
	if isLine(self.task.action) then
		self.distance = 10
	end
end

function Projectile:RotateToTarget(dest)
	local direction = (
		dest - 
		self.inst:GetPosition()
	):GetNormalized()
	local angle = math.acos(direction:Dot(Vector3(1, 0, 0))) / DEGREES
	self.inst.Transform:SetRotation(angle)
	self.inst:FacePoint(dest)
end

function Projectile:StartBy(doer, queue, target, targetPos)
	self.inst.Physics:ClearCollidesWith(COLLISION.LIMITS)
	self.doer = doer
	self.queue = queue
	self.target = target
	self.targetPos = targetPos

	-- 设置位置
	local x, y, z = doer.Transform:GetWorldPosition()
	local facing_angle = doer.Transform:GetRotation() * DEGREES
	self.inst.Physics:Teleport(x + self.launchoffset.x * math.cos(facing_angle), y + self.launchoffset.y, z - self.launchoffset.x * math.sin(facing_angle))

	-- 动感超人！
	self:RotateToTarget(targetPos)
	self.inst.Physics:SetVel(0, 0, 0)
	self.inst.Physics:SetFriction(0)
	self.inst.Physics:SetDamping(0)
	-- self.inst.Physics:SetMotorVel(self.speed, 1, 0)
	self.inst.Physics:SetMotorVel(self.speed, 0, 0)

	self:CalculateTask()
	self.inst:StartUpdatingComponent(self)
end

function Projectile:OnUpdate(dt)
	-- 没有队列的话就可以清理了
	if self.task == nil then
		self.inst:StopUpdatingComponent(self)
		self.inst:Remove()
		return
	end

	-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! 线性 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	if isLine(self.task.action) then
		local x, y, z = self.inst.Transform:GetWorldPosition()
		local ents = TheSim:FindEntities(x, y, z, 2, COMBAT_TAGS, NO_TAGS)

		-- 通杀
		local hit = false
		for i, prefab in ipairs(ents) do
			if
				prefab:IsValid() and
				prefab.entity:IsVisible() and
				self.inst.components.combat:CanTarget(prefab) and
				prefab.components.combat ~= nil and
				prefab.components.health ~= nil
			then
				-- 伤害
				if not self.task.cure then
					-- self.inst.components.combat:
					prefab.components.combat:GetAttacked(self.doer, self.task.damage, nil, nil)
					-- prefab.components.health:Kill()
					hit = true
				end
			end
		end

		-- 距离到了就删除
		self.distance = self.distance - self.speed * dt
		if hit or self.distance < 0 then
			self.inst:Remove()
		end
	end
end


return Projectile