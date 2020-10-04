local ORB_SPEED = 9
local ORB_SPEED_FAST = 20
local ANGLE_SPEED = 360
local MAX_COUNT = 3
local INCREASE_TIMEOUT = 2
local DISTANCE = 1.5
local DISTANCE_FAST = 2

local function getTargetPoint(angle, pos, offset)
	local offsetAngle = angle + (360 / MAX_COUNT * offset)
	local radius = offsetAngle / 180 * PI
	local targetPos = Vector3(pos.x + math.cos(radius) * DISTANCE, pos.y, pos.z + math.sin(radius) * DISTANCE)
	return targetPos
end

local function facePoint(orb, targetPoint)
	local orbPos = orb:GetPosition()
	local targetAngle = aipGetAngle(orbPos, targetPoint)
	orb.Transform:SetRotation(targetAngle)
end

local GuardianOrb = Class(function(self, inst)
	self.inst = inst

	-- 计算第一个法球的位置
	self.angle = 0
	-- 法球数组
	self.orbs = {}
	-- 法球生成剩余时间
	self.timeout = 0
	-- 召唤的法球物质
	self.spawnPrefab = nil
end)

-- 启动守护法球
function GuardianOrb:Start()
	self.inst:StartUpdatingComponent(self)
end

-- 关闭守护法球
function GuardianOrb:Stop()
	self.inst:StopUpdatingComponent(self)
end

-- 计算法球位置
function GuardianOrb:OnUpdate(dt)
	local instPos = self.inst:GetPosition()

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
			facePoint(orb, instPos)
			orb.Physics:SetMotorVel(ORB_SPEED_FAST, 0, 0)
		else
			-- 在附近则转圈圈
			local targetPoint = getTargetPoint(self.angle, instPos, i - 1)
			facePoint(orb, targetPoint)
			orb.Physics:SetMotorVel(ORB_SPEED, 0, 0)
		end
	end
end

return GuardianOrb