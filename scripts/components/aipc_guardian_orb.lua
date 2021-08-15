local RETARGET_MUST_TAGS = { "_combat", "_health" }
local RETARGET_CANT_TAGS = { "INLIMBO", "player", "engineering" }

local ORB_SPEED = 9
local ORB_SPEED_FAST = 20
local ANGLE_SPEED = 360
local MAX_COUNT = 3
local INCREASE_TIMEOUT = 2
local DISTANCE = 1.5
local DISTANCE_FAST = 2
local PROJECTILE_INTERVAL = 0.6 -- 设置可以攻击目标间隔

-- 获取法球目标点
local function getTargetPoint(angle, pos, offset)
	local offsetAngle = angle + (360 / MAX_COUNT * offset)
	local radius = offsetAngle / 180 * PI
	local targetPos = Vector3(pos.x + math.cos(radius) * DISTANCE, pos.y, pos.z + math.sin(radius) * DISTANCE)
	return targetPos
end

-- 寻找附近的敌对玩家
local function findNearEnemy(inst, owner)
	local x, y, z = inst.Transform:GetWorldPosition()
	local ents = TheSim:FindEntities(x, y, z, TUNING.AIP_JOKER_FACE_MAX_RANGE, RETARGET_MUST_TAGS, RETARGET_CANT_TAGS)

	local enemy = nil
	local distance = 9999999
	local targetedEnemy = nil

	for i, v in ipairs(ents) do
		if v.entity:IsVisible() and not v.components.health:IsDead() then
			local vx, vy, vz = v.Transform:GetWorldPosition()
			local sq = distsq(x, z, vx, vz)

			if 
				v:HasTag("hostile") and
				sq < distance and
				-- 要玩家可以攻击的目标才行
				(
					owner == nil or
					owner.components.combat == nil or
					owner.components.combat:CanTarget(enemy)
				)
			then
				-- 总是寻找最近的
				enemy = v
				distance = sq
			elseif v.components.combat.target ~= nil and v.components.combat.target:HasTag("player") then
				targetedEnemy = v
			end
		end
	end

	return targetedEnemy or enemy
end

local GuardianOrb = Class(function(self, inst)
	self.inst = inst

	-- 施法者
	self.owner = nil
	-- 计算第一个法球的位置
	self.angle = 0
	-- 法球数组
	self.orbs = {}
	-- 法球生成剩余时间
	self.timeout = 0
	-- 召唤的法球物质
	self.spawnPrefab = nil
	-- 发射出去的法球
	self.projectilePrefab = nil
	-- 法球释放间隔
	self.projectileTimeout = 0
end)

-- 启动守护法球
function GuardianOrb:Start(owner)
	self.owner = owner
	self.inst:StartUpdatingComponent(self)
end

-- 关闭守护法球
function GuardianOrb:Stop()
	self.inst:StopUpdatingComponent(self)

	for i = 1, #self.orbs do
		local orb = self.orbs[i]
		local explode = SpawnPrefab("explode_firecrackers")
		local x, y, z = orb.Transform:GetWorldPosition()
		explode.Transform:SetPosition(x, y + 1, z)
		explode.Transform:SetScale(0.3, 0.3, 0.3)
		orb:Remove()
	end

	self.orbs = {}
end

-- 计算法球位置
function GuardianOrb:OnUpdate(dt)
	local instPos = self.inst:GetPosition()

	-- 死亡取消效果
	if self.owner == nil or not self.owner.components.health or self.owner.components.health:IsDead() then
		self:Stop()
	end

	-- 法球数量计算
	self.timeout = self.timeout + dt
	if self.timeout >= INCREASE_TIMEOUT then
		self.timeout = math.mod(self.timeout, INCREASE_TIMEOUT)

		-- 可以新增法球啦
		if #self.orbs < MAX_COUNT then
			local orb = SpawnPrefab(self.spawnPrefab)
			table.insert(self.orbs, orb)
			orb.Transform:SetPosition(instPos.x, instPos.y, instPos.z)
			orb.Physics:SetMotorVel(ORB_SPEED, 0, 0)
			orb._master = true

			-- 只有一个发球的时候，重置一下可以攻击的时间
			if #self.orbs == 1 then
				self.projectileTimeout = 0
			end
		end
	end

	-- 计算是否可以释放法球
	self.projectileTimeout = self.projectileTimeout + dt

	-- 计算角度
	self.angle = math.mod((self.angle + dt * ANGLE_SPEED), 360)
	local dist = 999999

	local target = nil
	local targetPos = nil
	if self.projectileTimeout > PROJECTILE_INTERVAL then
		target = findNearEnemy(self.inst, self.owner)
		if target ~= nil then
			targetPos = target:GetPosition()
		end
	end

	for i = 1, #self.orbs do
		local orb = self.orbs[i]
		local orbPos = orb:GetPosition()

		-- 根据玩家间距调整速度
		local sq = distsq(orbPos.x, orbPos.z, instPos.x, instPos.z)
		if sq > DISTANCE_FAST * DISTANCE_FAST then
			-- 太远了就直接往目标身上追
			orb:FacePoint(instPos)
			orb.Physics:SetMotorVel(ORB_SPEED_FAST, 0, 0)
		else
			-- 在附近则转圈圈
			local targetPoint = getTargetPoint(self.angle, instPos, i - 1)
			orb:FacePoint(targetPoint)
			orb.Physics:SetMotorVel(ORB_SPEED, 0, 0)
		end

		-- 只有最后一个发球可以被扔出去
		if target ~= nil then
			local targetPos = target:GetPosition()
			local sq = distsq(targetPos.x, targetPos.z, orbPos.x, orbPos.z)

			if sq < dist then
				dist = sq
			end

			if i == #self.orbs and dist == sq then
				-- 距离最近则可以发射
				local proj = SpawnPrefab(self.projectilePrefab)
				local x, y, z = orb.Transform:GetWorldPosition()
				proj.Transform:SetPosition(orb.Transform:GetWorldPosition())
				proj.components.projectile:SetSpeed(ORB_SPEED_FAST)
				proj.components.projectile:Throw(self.inst, target, self.owner)

				-- 清理原来的
				table.remove(self.orbs, i)
				orb:Remove()
				self.projectileTimeout = 0
			end
		end
	end
end

return GuardianOrb