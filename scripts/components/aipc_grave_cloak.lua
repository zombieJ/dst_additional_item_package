local dev_mode = aipGetModConfig("dev_mode") == "enabled"

-- 陵卫斗篷
local GraveCloak = Class(function(self, inst)
	self.inst = inst
	self.interval = 5
	self.count = 5

	self.rotate = 0

	self.fires = {}
end)

function GraveCloak:GetCurrent()
	return #self.fires
end

function GraveCloak:Break()
	if #self.fires > 0 then
		local fire = table.remove(self.fires, #self.fires)

		fire._aipRemove(fire)
		-- aipReplacePrefab(fire, "aip_shadow_wrapper").DoShow(0.5)
	end
end

local function fireSpeed(inst, dist)
	if dist > 0.6 then
		return 20
	end

	if dist > 0.35 then
		return 10
	end

	return 3
end

function GraveCloak:Start()
	self:Stop()

	-- 创建火球
	self.createTask = self.inst:DoPeriodicTask(self.interval, function()
		if #self.fires < self.count then
			local fire = aipSpawnPrefab(self.inst, "aip_grave_cloak")
			fire.components.aipc_float.speed = fireSpeed
			fire._dist = 1.5
			fire._rotateSpeed = 2

			table.insert(self.fires, fire)
		end
	end)

	-- 到处飞行
	self.flyTask = self.inst:DoPeriodicTask(0.01, function()
		local pos = self.inst:GetPosition()

		self.rotate = math.mod(self.rotate + 360 - 2, 360)
		local unit = 360 / self.count

		for i, fire in ipairs(self.fires) do
			local rotate = math.mod(self.rotate + unit * i + 360, 360)
			local radius = rotate / 180 * PI

			-- 目标位置
			local targetPos = Vector3(
				pos.x + math.cos(radius) * fire._dist,
				0,
				pos.z + math.sin(radius) * fire._dist
			)

			fire.components.aipc_float:MoveToPoint(targetPos)
		end
	end)
end

function GraveCloak:Stop()
	if self.createTask ~= nil then
		self.createTask:Cancel()
		self.createTask = nil
	end

	if self.flyTask ~= nil then
		self.flyTask:Cancel()
		self.flyTask = nil
	end
end

function GraveCloak:OnRemoveFromEntity()
	self:Stop()
end
GraveCloak.OnRemoveEntity = GraveCloak.OnRemoveFromEntity

return GraveCloak