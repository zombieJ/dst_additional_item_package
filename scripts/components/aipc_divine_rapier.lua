-- 一个只会飞行到目标地点的投掷物

local STATUS_ROUNDING = 0
local STATUS_GUARDING = 1
local STATUS_ATTACKING = 2
local STATUS_ATTACK_AWAY = 3

-- 飞行出去一段距离后才会回来
local FAR_AWAY_DIST = 8

local DivineRapier = Class(function(self, inst)
	self.inst = inst

	-- 需要守护的目标
	self.guardTarget = nil

	-- 临时攻击的目标
	self.attackTarget = nil

	-- 在击中目标后，还需要飞一端距离，这样好看
	self.hitPt = nil

	-- 设置转一圈要多少秒
	self.roundTime = 1

	-- 设置旋转距离
	self.roundDist = 2

	-- 守卫的时间，超过这个时间会再出去找敌人
	self.roundingTime = 0

	-- 来源武器
	self.weapon = nil

	self.status = STATUS_ATTACKING

	self.onUse = nil

	-- 根据游戏进行时间设定围绕坐标，用于计算目标点
	self.index = 0
	self.total = 1
end)

function DivineRapier:GetRoundPt()
	-- 获取系统时间
	local now = GetTime()

	-- 根据 index 获取偏转角度
	local offsetRotate = 360 / self.total * self.index

	-- 当前转的角度
	local rotate = (now % self.roundTime) * (360 / self.roundTime) + offsetRotate
	local radius = rotate / 180 * PI

	local pos = self.guardTarget:GetPosition()

	-- 计算环绕所需的目标点
	local tgtPt = Vector3(
		pos.x + math.cos(radius) * self.roundDist,
		0,
		pos.z + math.sin(radius) * self.roundDist
	)

	return tgtPt
end

function DivineRapier:Setup(guardTarget, index, total, weapon)
	self.guardTarget = guardTarget
	self.index = index
	self.total = total
	self.weapon = weapon

	local tgtPt = self:GetRoundPt()
	self.inst:ForceFacePoint(tgtPt.x, tgtPt.y, tgtPt.z)

	self.status = STATUS_ROUNDING
	self.inst:StartUpdatingComponent(self)
end

function DivineRapier:GetDamage(target)
	if self.weapon ~= nil and self.weapon.components.weapon ~= nil then
		return self.weapon.components.weapon:GetDamage(self.guardTarget, target)
	end

	return 17
end

-- 角度速，返回 360 度的角度
function DivineRapier:GetAngleSpeed()
	return 360 / self.roundTime
end

-- 返回线速度
function DivineRapier:GetLineSpeed()
	local angleSpeed = self:GetAngleSpeed()
	local rotateSpeed = angleSpeed / 180 * PI
	return rotateSpeed * self.roundDist
end

function DivineRapier:Attack(target)
	if aipCanAttack(target, self.guardTarget, true) then
		self.attackTarget = target

		self.status = STATUS_ATTACKING
	end
end

-- 寻找目标
function DivineRapier:EnsureAttackTarget()
	if not aipCanAttack(self.attackTarget, self.guardTarget, true) then
		local RETARGET_MUST_TAGS = { "_combat", "_health" }
		local RETARGET_CANT_TAGS = { "INLIMBO", "player", "engineering" }

		local x, y, z = self.guardTarget.Transform:GetWorldPosition()
		local ents = TheSim:FindEntities(
			x, y, z,
			16, RETARGET_MUST_TAGS, RETARGET_CANT_TAGS
		)
		ents = aipFilterTable(ents, function(ent)
			return aipCanAttack(ent, self.guardTarget)
		end)

		self.attackTarget = ents[1]
	end

	return self.attackTarget
end

-- 飞向目标
function DivineRapier:OnTargetUpdate(targetPt, dt)
	local oriAngle = self.inst:GetRotation()
	local tgtAngle = self.inst:GetAngleToPoint(targetPt.x, targetPt.y, targetPt.z)

	local dist = aipDist(self.inst:GetPosition(), targetPt)

	-- 旋转角度速度
	local angleSpeedPerSec = 360 / self.roundTime
	if dist < FAR_AWAY_DIST / 2 then -- 在靠近单位的时候，提供追速补偿
		angleSpeedPerSec = angleSpeedPerSec * 2
	end

	local angle = aipToAngle(oriAngle, tgtAngle, dt * angleSpeedPerSec)
	self.inst.Transform:SetRotation(angle)

	-- 设置飞行速度
	self.inst.Physics:SetMotorVel(self:GetLineSpeed() * 2, 0, 0)

	-- 返回距离
	return dist
end

-- 飞向守卫
function DivineRapier:OnFollowUpdate(dt)
	local roundPt = self:GetRoundPt()
	local dist = self:OnTargetUpdate(roundPt, dt)

	if dist < 3 then
		self.roundingTime = 0

		local target = self:EnsureAttackTarget()

		if target ~= nil then
			self.status = STATUS_ATTACKING
		else
			self.status = STATUS_ROUNDING
		end
	end
end

-- 飞向敌人
function DivineRapier:OnAttackUpdate(dt)
	local target = self:EnsureAttackTarget()

	if target then
		local targetPt = target:GetPosition()
		local dist = self:OnTargetUpdate(targetPt, dt)

		if dist < 1 then
			target.components.combat:GetAttacked(self.guardTarget, self:GetDamage(target))

			if self.onUse ~= nil then
				self.onUse()
			end

			self.status = STATUS_ATTACK_AWAY
		end
	else
		self.status = STATUS_GUARDING
	end

	self.hitPt = self.inst:GetPosition()
end

-- 穿过敌人后，再飞一会儿
function DivineRapier:OnAttackAwayUpdate(dt)
	local currentPos = self.inst:GetPosition()
	local dist = aipDist(currentPos, self.hitPt)
	local targetDist = self.attackTarget and aipDist(currentPos, self.attackTarget:GetPosition()) or 999999

	if dist > FAR_AWAY_DIST and targetDist > FAR_AWAY_DIST then
		self.status = STATUS_ATTACKING
	end

	self.inst.Physics:SetMotorVel(self:GetLineSpeed() * 2, 0, 0)
end

-- 环绕守卫目标
function DivineRapier:OnRoundUpdate(dt)
	local oriAngle = self.inst:GetRotation()

	self.roundingTime = self.roundingTime + dt

	--------------------------------------------------------
	-- 先看看有没有可以攻击的目标，至少转一圈再去攻击
	if self.roundingTime > self.roundTime / 2 then
		local target = self:EnsureAttackTarget()
		if target then
			local angle = self.inst:GetAngleToPoint(target:GetPosition())
			local diffAngle = aipDiffAngle(angle, oriAngle)

			if diffAngle < 30 then
				self.status = STATUS_ATTACKING
				return
			end
		end
	end

	--------------------------------------------------------
	local currentPos = self.inst:GetPosition()
	local roundPt = self:GetRoundPt()
	local guardPt = self.guardTarget:GetPosition()

	local dist = aipDist(currentPos, roundPt)

	-- 统计角度
	local angleSpeedPerSec = 360 / self.roundTime
	angleSpeedPerSec = angleSpeedPerSec * 2 -- 追速补偿

	-- 我们按照剑所在位置使用力做偏移
	self.inst:ForceFacePoint(guardPt.x, guardPt.y, guardPt.z)
	local tgtAngle = self.inst:GetRotation() + 90
	local angle = aipToAngle(oriAngle, tgtAngle, dt * angleSpeedPerSec)
	self.inst.Transform:SetRotation(angle)

	-- 计算当前施加速度的偏移角度
	local speed = dist * 10
	local faceAngle = self.inst:GetAngleToPoint(roundPt.x, roundPt.y, roundPt.z)
	local faceX = math.cos(faceAngle / 180 * PI) * speed
	local faceZ = -math.sin(faceAngle / 180 * PI) * speed

	-- 按照角度侧力
	local corrected_vel_x, corrected_vel_z = VecUtil_RotateDir(faceX, faceZ, self.inst.Transform:GetRotation() * DEGREES)
	self.inst.Physics:SetMotorVel(corrected_vel_x, 0, corrected_vel_z)
end

function DivineRapier:OnUpdate(dt)
	if self.status == STATUS_ATTACKING then
		self:OnAttackUpdate(dt)
	elseif self.status == STATUS_ATTACK_AWAY then
		self:OnAttackAwayUpdate(dt)
	elseif self.status == STATUS_GUARDING then
		self:OnFollowUpdate(dt)
	else
		self:OnRoundUpdate(dt)
	end
end

return DivineRapier