local ANGLE_SPEED = 5
local MAX_COUNT = 3
local INCREASE_TIMEOUT = 2
local DISTANCE = 1

local function getTargetPoint(angle, pos, offset)
	local offsetAngle = angle + (360 / MAX_COUNT * offset)
	local radius = offsetAngle / 180 * PI
	local targetPos = Vector3(pos.x + math.cos(radius) * DISTANCE, pos.y, pos.z + math.sin(radius) * DISTANCE)
	return targetPos
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
	-- 初始化速度
	self.speed = 20
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
			orb.Physics:SetMotorVel(self.speed, 0, 0)
		end
	end

	-- 计算角度
	self.angle = math.mod((self.angle + dt * ANGLE_SPEED), 360)

	for i = 1, #self.orbs do
		local orb = self.orbs[i]
		local targetPoint = getTargetPoint(self.angle, instPos, i - 1)

		local angle = aipGetAngle(orb:GetPosition(), targetPoint)
		orb.Transform:SetRotation(angle)
		orb:FacePoint(targetPoint)
	end
end

return GuardianOrb