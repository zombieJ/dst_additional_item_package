local COMBAT_TAGS = { "_combat" }
local NO_TAGS = { "player" }

local function isLine(action)
	return action == nil or action == "LINE" or action == "THROUGH"
end

local function FindEntities(pos, radius)
	local ents = TheSim:FindEntities(pos.x, pos.y, pos.z, radius or 2, COMBAT_TAGS, NO_TAGS)
	return ents
end

local Projectile = Class(function(self, inst)
	self.inst = inst
	self.speed = 10
	self.launchoffset = Vector3(0.25, 2, 0)

	self.doer = nil
	self.queue = {}

	-- Task
	self.task = nil
	self.target = nil
	self.targetPos = nil
	self.distance = nil
	self.cachePos = nil -- 存储上一次位置
	self.diffTime = nil -- 释放后经过的时间

	-- 超时可能投掷物已经卡死，删除之
	inst:DoTaskInTime(120, function()
		self:CleanUp()
	end)
end)

function Projectile:CleanUp()
	self.inst:StopUpdatingComponent(self)
	self.inst:Remove()
end

function Projectile:CalculateTask()
	local task = self.queue[1]
	table.remove(self.queue, 1)

	if task == nil then
		self:CleanUp()
		return
	end

	self.task = task
	self.diffTime = 0
	self.inst.AnimState:SetMultColour(1, 1, 1, 1)

	if isLine(self.task.action) then
		self.distance = 10
	elseif self.task.action == "AREA" then
		self.inst.AnimState:SetMultColour(0, 0, 0, 0)
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
	self.cachePos = doer:GetPosition()

	if self.target and not self.targetPos then
		self.targetPos = self.target:GetPosition()
	end

	-- 设置位置
	local x, y, z = doer.Transform:GetWorldPosition()
	local facing_angle = doer.Transform:GetRotation() * DEGREES
	self.inst.Physics:Teleport(x + self.launchoffset.x * math.cos(facing_angle), y + self.launchoffset.y, z - self.launchoffset.x * math.sin(facing_angle))

	-- 动感超人！
	self:RotateToTarget(self.targetPos)
	self.inst.Physics:SetVel(0, 0, 0)
	self.inst.Physics:SetFriction(0)
	self.inst.Physics:SetDamping(0)
	-- self.inst.Physics:SetMotorVel(self.speed, 1, 0)
	self.inst.Physics:SetMotorVel(self.speed, 0, 0)

	self:CalculateTask()
	self.inst:StartUpdatingComponent(self)
end

function Projectile:EffectTaskOn(target)
	-- 伤害
	if not self.task.cure then
		target.components.combat:GetAttacked(self.doer, self.task.damage, nil, nil)
		return true
	end

	return false
end

function Projectile:OnUpdate(dt)
	-- 没有队列的话就可以清理了
	if self.task == nil then
		self:CleanUp()
		return
	end

	self.diffTime = self.diffTime + dt

	local currentPos = self.inst:GetPosition()
	local finishTask = false

	-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! 线性 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	if isLine(self.task.action) then
		local ents = FindEntities(self.inst:GetPosition())

		-- 通杀
		for i, prefab in ipairs(ents) do
			if
				prefab:IsValid() and
				prefab.entity:IsVisible() and
				self.inst.components.combat:CanTarget(prefab) and
				prefab.components.combat ~= nil and
				prefab.components.health ~= nil
			then
				finishTask = self:EffectTaskOn(prefab) or finishTask
			end
		end

		-- 距离到了就删除
		self.distance = self.distance - self.speed * dt
		if self.distance < 0 then
			finishTask = true
		end

	-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! 跟随 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	elseif self.task.action == "FOLLOW" then
		if self.target == nil or self.target.components.health == nil or self.target.components.health:IsDead() then
			finishTask = true
		else
			local targetPos = self.target:GetPosition()
			self.targetPos = targetPos

			if distsq(currentPos, targetPos) < 3 then
				finishTask = self:EffectTaskOn(self.target) or finishTask
			else
				self:RotateToTarget(self.targetPos)
			end
		end
	-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! 区域 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	elseif self.task.action == "AREA" then
		-- 区域魔法会经过一定延迟释放
		if self.diffTime >= 0.1 then
			local ents = FindEntities(self.targetPos)

			-- 通杀
			for i, prefab in ipairs(ents) do
				if
					prefab:IsValid() and
					prefab.entity:IsVisible() and
					self.inst.components.combat:CanTarget(prefab) and
					prefab.components.combat ~= nil and
					prefab.components.health ~= nil
				then
					self:EffectTaskOn(prefab)
				end
			end

			finishTask = true
		end
	end

	if finishTask then
		self:CalculateTask()
	end

	self.cachePos = currentPos
end


return Projectile