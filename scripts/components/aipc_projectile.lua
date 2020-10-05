local AREA_DISTANCE = 2

local COMBAT_TAGS = { "_combat" }
-- local NO_TAGS = { "player" }
local NO_TAGS = nil

-- local FLOWERS = { "stalker_bulb", "stalker_berry", "stalker_fern" }
local FLOWERS = { 1, 2, 3, 4 }

local function SpawnFlower(index)
	-- local flower = SpawnPrefab(FLOWERS[math.fmod(index, #FLOWERS) + 1])
	-- flower.Transform:SetScale(0.7, 0.7, 0.7)
	-- flower:AddTag("NOCLICK")
	-- return flower
	local flower = SpawnPrefab("wormwood_plant_fx")
	local rnd = FLOWERS[math.fmod(index, #FLOWERS) + 1]
	flower:SetVariation(rnd)
	return flower
end

local function SpawnFlowers(point, dest, count, flowerIndex)
	for i = 1, count do
		local flower = SpawnFlower(flowerIndex + i)
		local angle = 2 * PI / count * i
		local distance = dest + math.random() / 2
		flower.Transform:SetPosition(point.x + math.cos(angle) * distance, 0, point.z + math.sin(angle) * distance)
	end
end

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

local function ShowEffect(element, point, targetEffect)
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
	elseif element == "SAND" then
		smallScale = 1
		if targetEffect then
			prefab = SpawnPrefab("sandspike_short")
		else
			prefab = SpawnPrefab("sandspike_tall")
		end
		
		-- 重置一下伤害
		if prefab.components.combat ~= nil then
			prefab.components.combat:SetDefaultDamage(10)
			prefab.components.combat.playerdamagepercent = 1
		end
	elseif element == "HEAL" then
		if targetEffect then
			prefab = SpawnPrefab("aip_heal_fx")
			smallScale = 1
		else
			-- 范围施法时样式不太一样
			local flowerIndex = math.floor(math.random() * #FLOWERS) + 1
			local flower = SpawnFlower(flowerIndex)
			flower.Transform:SetPosition(point.x, 0, point.z)

			-- 范围特效添加一个光环效果
			local aip_sanity_fx = SpawnPrefab("aip_sanity_fx")
			aip_sanity_fx.Transform:SetPosition(point.x, 0, point.z)

			-- 最远的花
			SpawnFlowers(point, 1.5, 8, flowerIndex + 1)

			-- 中间的花
			SpawnFlowers(point, 0.5, 5, flowerIndex + 9)
		end
	else
		prefab = SpawnPrefab("collapse_small")
	end

	if prefab ~= nil then
		if targetEffect then
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
	elseif element == "ICE" then
		-- 应用冰冻效果
		if target.components.freezable ~= nil then
			target.components.freezable:AddColdness(elementCount or 1)
			target.components.freezable:SpawnShatterFX()
		end
	end
end

local function ApplySandEffect(element, position)
	if element == "SAND" then
		-- 创建沙丁
		local blocker = SpawnPrefab("sandspike_med")
		blocker.Physics:Teleport(position.x, position.y, position.z)
	end
end

local Projectile = Class(function(self, inst)
	self.inst = inst
	-- self.speed = 20
	self.speed = 20
	-- self.launchoffset = Vector3(0.25, 2, 0)
	self.launchoffset = Vector3(0, 1.6, 0)

	self.doer = nil
	self.queue = {}

	-- Task
	self.task = nil
	self.source = nil
	self.sourcePos = nil
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

function Projectile:FindEntities(element, pos, radius)
	local filteredEnts = {}
	local ents = TheSim:FindEntities(pos.x, pos.y, pos.z, radius or AREA_DISTANCE, COMBAT_TAGS, NO_TAGS)

	for i, ent in ipairs(ents) do
		-- 根据元素选择目标
		if (element == "HEAL" and ent:HasTag("player")) or (element ~= "HEAL" and not ent:HasTag("player")) then
			-- 只寻找活着的生物
			-- if not include(self.affectedEntities, ent) and self.inst.components.combat:CanTarget(ent) then
			-- TODO 去重寻找
			if self.inst.components.combat:CanTarget(ent) then
				table.insert(filteredEnts, ent)
			end
		end
	end

	return filteredEnts
end

function Projectile:RotateToTarget(dest)
	local angle = aipGetAngle(self.inst:GetPosition(), dest)
	self.inst.Transform:SetRotation(angle)
	self.inst:FacePoint(dest)
end

---------------------------------------- 计算任务 ----------------------------------------
-- 开始任务
function Projectile:StartBy(doer, queue, target, targetPos, replaceSourcePos)
	local task = queue[1]

	if task == nil then
		self:CleanUp()
		return
	end

	local splitCount = task.split + 1

	-- 跟踪需要准备单位池
	local ents = {}
	if task.action == "FOLLOW" and target ~= nil then
		local tmpEnts = self:FindEntities(task.element, target:GetPosition(), 8)

		for i, prefab in ipairs(tmpEnts) do
			if prefab ~= target then
				table.insert(ents, prefab)
			end
		end
	end

	for i = 1, splitCount do
		local effectProjectile = SpawnPrefab("aip_dou_scepter_projectile")


		if task.action == "FOLLOW" then
			-- 对随机目标施放
			if i == 1 then
				-- 第一个始终为目标
				effectProjectile.components.aipc_projectile:StartEffectTask(doer, queue, target, targetPos, replaceSourcePos)
			else
				-- 依次作用目标
				local newTarget = ents[i - 1]
				if newTarget ~= nil then
					effectProjectile.components.aipc_projectile:StartEffectTask(doer, queue, newTarget, newTarget:GetPosition(), replaceSourcePos)
				end
			end
		else
			-- 方向性技能四散而去
			local sourcePos = replaceSourcePos or doer:GetPosition()
			local angle = (aipGetAngle(sourcePos, targetPos) + ((i - 1) - (splitCount - 1) / 2) * 30)
			local radius = angle / 180 * PI
			local distance = math.pow(distsq(sourcePos.x, sourcePos.z, targetPos.x, targetPos.z), 0.5)
			local newTargetPos = Vector3(sourcePos.x + math.cos(radius) * distance, sourcePos.y, sourcePos.z + math.sin(radius) * distance)

			effectProjectile.components.aipc_projectile:StartEffectTask(doer, queue, target, newTargetPos, replaceSourcePos)
		end
	end
end

-- 分裂完毕后启动的单个任务
function Projectile:StartEffectTask(doer, queue, target, targetPos, replaceSourcePos)
	self.inst.Physics:ClearCollidesWith(COLLISION.LIMITS)
	self.doer = doer
	self.queue = queue
	self.source = doer
	self.sourcePos = replaceSourcePos or doer:GetPosition()
	self.target = target
	self.targetPos = targetPos
	self.cachePos = doer:GetPosition()

	if self.target and not self.targetPos then
		self.targetPos = self.target:GetPosition()
	end

	-- 设置位置
	local x, y, z = self.sourcePos:Get()
	local facing_angle = doer.Transform:GetRotation() * DEGREES
	self.inst.Physics:Teleport(x + self.launchoffset.x * math.cos(facing_angle), y + self.launchoffset.y, z - self.launchoffset.x * math.sin(facing_angle))

	-- 动感超人！
	self:RotateToTarget(self.targetPos)
	self.inst.Physics:SetVel(0, 0, 0)
	self.inst.Physics:SetFriction(0)
	self.inst.Physics:SetDamping(0)
	self.inst.Physics:SetMotorVel(self.speed, 1, 0)
	-- self.inst.Physics:SetMotorVel(self.speed, 0, 0)

	self:CalculateTask()
	self.inst:StartUpdatingComponent(self)
end

-- 计算后续操作
function Projectile:CalculateTask()
	local task = self.queue[1]

	if task == nil then
		self:CleanUp()
		return
	end

	-- 重置颜色
	local color = task.color
	self.inst.components.aipc_info_client:SetByteArray("aip_projectile_color", { color[1] * 10, color[2] * 10, color[3] * 10, color[4] * 10 })

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

-- 开始下一个任务
function Projectile:DoNextTask()
	local newQueue = {}
	local prevTask = self.queue[1]

	-- 复制一份
	for i = 2, #self.queue do
		local task = self.queue[i]
		table.insert(newQueue, task)
	end

	if #newQueue >= 1 then
		local nextTask = newQueue[1]
		local nextProjectile = SpawnPrefab("aip_dou_scepter_projectile")
		local nextPos = nil
		local nextTarget = nil

		-- 临时变量减少代码体积
		local targetPos = self.targetPos
		-- 替换的起始位置
		local replaceSourcePos = targetPos
		local diffX = targetPos.x - self.sourcePos.x
		local diffZ = targetPos.z - self.sourcePos.z

		if nextTask.action == "AREA" then
			-- 圈会在释放点后一定的距离再次释放，最多不超过 4 格距离
			nextPos = Vector3(targetPos.x + math.min(4, diffX / 2), targetPos.y, targetPos.z + math.min(4, diffZ / 2))
		elseif nextTask.action == "FOLLOW" then
			-- 跟踪是不知道下一个目标的，所以在施法距离内随机选一个符合要求的目标
			local ents = self:FindEntities(nextTask.element, targetPos, 8)

			-- 优先寻找靠中间的且不是原来的目标的以展示弹道
			local bestTarget = nil
			local bestDistance = 999999

			for i, prefab in ipairs(ents) do
				local prefabPos = prefab:GetPosition()
				local sq = distsq(targetPos.x, targetPos.z, prefabPos.x, prefabPos.z)
				local dst = math.abs(math.pow(sq, 0.5) - 4)

				if prefab ~= self.target and dst < bestDistance then
					bestTarget = prefab
					bestDistance = dst
				end
			end

			if bestTarget == nil and self.target ~= nil then
				bestTarget = self.target
			end

			-- 附近没有新目标，结束施法
			if bestTarget == nil then
				self:CleanUp()
				return
			end

			nextTarget = bestTarget
			nextPos = nextTarget:GetPosition()
		else
			-- 直线目标
			nextPos = Vector3(targetPos.x + diffX * 100, targetPos.y, targetPos.z + diffZ * 100)

			-- 如果是 Area 则计算 2 格偏移量以免重复的命中目标
			if prevTask.action == "AREA" then
				local angle = aipGetAngle(targetPos, nextPos)
				local radius = angle / 180 * PI
				replaceSourcePos = Vector3(targetPos.x + math.cos(radius) * AREA_DISTANCE, targetPos.y, targetPos.z + math.sin(radius) * AREA_DISTANCE)
			end
		end

		nextProjectile.components.aipc_projectile:StartBy(self.doer, newQueue, nextTarget, nextPos, replaceSourcePos)
	end

	self:CleanUp()
end

---------------------------------------- 效果执行 ----------------------------------------
function Projectile:EffectTaskOn(target)
	local doEffect = false
	-- 治疗
	if self.task.element == "HEAL" then
		if target.components.health ~= nil then
			target.components.health:DoDelta(self.task.damage, false, self.inst.prefab)
			doEffect = true
		end

	-- 伤害
	else
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
		local ents = self:FindEntities(self.task.element, self.inst:GetPosition())

		-- 通杀
		for i, prefab in ipairs(ents) do
			if
				prefab:IsValid() and
				prefab.entity:IsVisible() and
				-- self.inst.components.combat:CanTarget(prefab) and
				prefab.components.combat ~= nil and
				prefab.components.health ~= nil
			then
				-- 只有穿透才能对施法者有效
				if self.doer ~= prefab or self.task.action == "THROUGH" then
					local effectWork = self:EffectTaskOn(prefab)
					if self.task.action ~= "THROUGH" then
						finishTask = effectWork or finishTask

						-- 命中则更新位置和目标
						if effectWork then
							self.target = prefab
							self.targetPos = self.target:GetPosition()
						end
					end

					ShowEffect(self.task.element, prefab:GetPosition(), true)
				end
			end
		end

		-- 距离到了就删除
		self.distance = self.distance - self.speed * dt
		if self.distance < 0 then
			finishTask = true
		end

		-- if finishTask and self.task.action ~= "THROUGH" then
		-- 	ShowEffect(self.task.element, self.inst:GetPosition())
		-- end

	-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! 跟随 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	elseif self.task.action == "FOLLOW" then
		if self.target == nil or self.target.components.health == nil or self.target.components.health:IsDead() then
			finishTask = true
		else
			-- 命中更新目标位置
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
			local ents = self:FindEntities(self.task.element, self.targetPos)

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

					if self.task.element == "HEAL" then
						ShowEffect(self.task.element, prefab:GetPosition(), true)
					end
				end
			end

			finishTask = true
		end

		if finishTask then
			ShowEffect(self.task.element, self.targetPos)
		end
	end

	if finishTask then
		self:DoNextTask()
	end

	self.cachePos = currentPos
end


return Projectile