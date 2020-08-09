local COMBAT_TAGS = { "_combat" }
local NO_TAGS = { "player" }

local function include(table, value)
    for k,v in ipairs(table) do
      if v == value then
          return true
      end
    end
    return false
end

local function isLine(action)
	return action == nil or action == "LINE" or action == "THROUGH"
end

local function ShowEffect(element, point, smallEffect)
	local prefab
	local normalScale = 1
	local smallScale = 0.5

	if element == "FIRE" then
		prefab = SpawnPrefab("explode_small")
		normalScale = 1.2
	elseif element == "ICE" then
		prefab = SpawnPrefab("icespike_fx_2")
		normalScale = 2
		smallScale = 0.7
	else
		prefab = SpawnPrefab("collapse_small")
	end

	if prefab ~= nil then
		if smallEffect then
			prefab.Transform:SetScale(smallScale, smallScale, smallScale)
		else
			prefab.Transform:SetScale(normalScale, normalScale, normalScale)
		end
		prefab.Transform:SetPosition(point.x, point.y, point.z)
	end
end

local function ApplyElementEffect(target, element, elementCount)
	if element == "FIRE" and math.random() < (elementCount or 0) * .4 then
		-- 应用火焰伤害
		if target.components.burnable ~= nil and not target.components.burnable:IsBurning() then
			if target.components.freezable ~= nil and target.components.freezable:IsFrozen() then
				target.components.freezable:Unfreeze()
			elseif target.components.fueled == nil
				or (target.components.fueled.fueltype ~= FUELTYPE.BURNABLE and
					target.components.fueled.secondaryfueltype ~= FUELTYPE.BURNABLE) then
				--does not take burnable fuel, so just burn it
				if target.components.burnable.canlight or target.components.combat ~= nil then
					target.components.burnable:Ignite(true)
				end
			elseif target.components.fueled.accepting then
				--takes burnable fuel, so fuel it
				local fuel = SpawnPrefab("cutgrass")
				if fuel ~= nil then
					if fuel.components.fuel ~= nil and
						fuel.components.fuel.fueltype == FUELTYPE.BURNABLE then
						target.components.fueled:TakeFuelItem(fuel)
					else
						fuel:Remove()
					end
				end
			end
		end
	end
end

local Projectile = Class(function(self, inst)
	self.inst = inst
	self.speed = 20
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
	self.affectedEntities = nil -- 被影响到的单位

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
	self.affectedEntities = {}
	self.inst.AnimState:SetMultColour(1, 1, 1, 1)

	if isLine(self.task.action) then
		self.distance = 10
	elseif self.task.action == "AREA" then
		self.inst.AnimState:SetMultColour(0, 0, 0, 0)
	end
end

function Projectile:FindEntities(pos, radius)
	local filteredEnts = {}
	local ents = TheSim:FindEntities(pos.x, pos.y, pos.z, radius or 2, COMBAT_TAGS, NO_TAGS)

	for i, ent in ipairs(ents) do
		if not include(self.affectedEntities, ent) then
			table.insert(self.affectedEntities, ent)
			table.insert(filteredEnts, ent)
		end
	end

	return filteredEnts
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
	local doEffect = false
	-- 伤害
	if not self.task.cure then
		target.components.combat:GetAttacked(self.doer, self.task.damage, nil, nil)
		doEffect = true
	end

	if doEffect then
		ApplyElementEffect(target, self.task.element, self.task.elementCount)
	end

	return doEffect
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
		local ents = self:FindEntities(self.inst:GetPosition())

		-- 通杀
		for i, prefab in ipairs(ents) do
			if
				prefab:IsValid() and
				prefab.entity:IsVisible() and
				self.inst.components.combat:CanTarget(prefab) and
				prefab.components.combat ~= nil and
				prefab.components.health ~= nil
			then
				local effectWork = self:EffectTaskOn(prefab)
				if self.task.action ~= "THROUGH" then
					finishTask = effectWork or finishTask
				elseif effectWork then
					ShowEffect(self.task.element, prefab:GetPosition(), true)
				end
			end
		end

		-- 距离到了就删除
		self.distance = self.distance - self.speed * dt
		if self.distance < 0 then
			finishTask = true
		end

		if finishTask and self.task.action ~= "THROUGH" then
			ShowEffect(self.task.element, self.inst:GetPosition())
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
				ShowEffect(self.task.element, self.target:GetPosition())
			else
				self:RotateToTarget(self.targetPos)
			end
		end

	-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! 区域 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	elseif self.task.action == "AREA" then
		-- 区域魔法会经过一定延迟释放
		if self.diffTime >= 0.1 then
			local ents = self:FindEntities(self.targetPos)

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

		if finishTask then
			ShowEffect(self.task.element, self.targetPos)
		end
	end

	if finishTask then
		self:CalculateTask()
	end

	self.cachePos = currentPos
end


return Projectile