-- local COMBAT_TAGS = { "_combat", "hostile" }
local RETARGET_MUST_TAGS = { "_combat", "_health" }
local RETARGET_CANT_TAGS = { "INLIMBO", "player", "engineering" }

local ORB_SPEED = 9
local ORB_SPEED_FAST = 20
local ANGLE_SPEED = 360
local MAX_COUNT = 3
local INCREASE_TIMEOUT = 2
local DISTANCE = 1.5
local DISTANCE_FAST = 2.5

-- 获取法球目标点
local function getTargetPoint(angle, pos, offset)
	local offsetAngle = angle + (360 / MAX_COUNT * offset)
	local radius = offsetAngle / 180 * PI
	local targetPos = Vector3(pos.x + math.cos(radius) * DISTANCE, pos.y, pos.z + math.sin(radius) * DISTANCE)
	return targetPos
end

-- 寻找附近的敌对玩家
local function findNearEnemy(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
	local ents = TheSim:FindEntities(x, y, z, TUNING.AIP_JOKER_FACE_MAX_RANGE, RETARGET_MUST_TAGS, RETARGET_CANT_TAGS)

	local enemy = nil
	local targetedEnemy = nil

	for i, v in ipairs(ents) do
		if v.entity:IsVisible() and not v.components.health:IsDead() then
			if v:HasTag("hostile") then
				enemy = v
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
end)

-- 启动守护法球
function GuardianOrb:Start(owner)
	self.owner = owner
	self.inst:StartUpdatingComponent(self)
end

-- 关闭守护法球
function GuardianOrb:Stop()
	self.inst:StopUpdatingComponent(self)
end

-- 计算法球位置
function GuardianOrb:OnUpdate(dt)
	local instPos = self.inst:GetPosition()

	-- TODO: 死亡需要取消效果

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
		end
	end

	-- 计算角度
	self.angle = math.mod((self.angle + dt * ANGLE_SPEED), 360)

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
		if i == #self.orbs then
			local target = findNearEnemy(self.inst)
			if target ~= nil then
				local targetPos = target:GetPosition()
				local orbTargetAngle = orb:GetAngleToPoint(targetPos.x, targetPos.y, targetPos.z)
				local diffAngle = aipDiffAngle(orb:GetRotation(), orbTargetAngle)

				if diffAngle < 30 then
					-- 偏差小于 30 度就可以发射了
					local proj = SpawnPrefab(self.projectilePrefab)
					local x, y, z = orb.Transform:GetWorldPosition()
					proj.Transform:SetPosition(orb.Transform:GetWorldPosition())
					proj.components.projectile:SetSpeed(ORB_SPEED_FAST)
					proj.components.projectile:Throw(self.inst, target, self.owner)

					-- 清理原来的
					table.remove(self.orbs, i)
					orb:Remove()
				end
			end
		end
	end
end

return GuardianOrb