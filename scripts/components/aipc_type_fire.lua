local dev_mode = aipGetModConfig("dev_mode") == "enabled"

-- 创建一个类型火焰，绑定到目标上
local TypeFire = Class(function(self, inst)
	self.inst = inst

	self.hotPrefab = nil
	self.coldPrefab = nil
	self.mixPrefab = nil
	self.followSymbol = nil
	self.followOffset = Vector3(0, 0, 0)
	self.followOffsets = {}
	self.postFireFn = nil

	self.extinguishTime = TUNING.YELLOWSTAFF_STAR_DURATION
	self.extinguishTimer = nil

	-- 火焰实体
	self.fire = nil
	self.fireType = nil

	self.onToggle = nil
end)

function TypeFire:StartExtinguishTimer(extinguishTime)
	self:KillExtinguishTimer()

	self.extinguishTimer = self.inst:DoTaskInTime(
		extinguishTime or self.extinguishTime,
		function()
			self:StopFire()
		end
	)
end

function TypeFire:KillExtinguishTimer()
	if self.extinguishTimer ~= nil then
		self.extinguishTimer:Cancel()
		self.extinguishTimer = nil
	end
end

function TypeFire:StartFire(type, target, extinguishTime)
	if type == self.fireType then
		-- 如果已经是这种火焰，延长时间
		self:StartExtinguishTimer(extinguishTime)
		return
	end

	self:StopFire()
	self:StartExtinguishTimer(extinguishTime)

	target = target or self.inst
	local firePrefab = self.hotPrefab
	if type == "mix" then
		firePrefab = self.mixPrefab
	elseif type == "cold" then
		firePrefab = self.coldPrefab
	end

	-- 创建火焰
	local offset = self.followOffsets[type] or self.followOffset
	
	local fx = SpawnPrefab(firePrefab)
	fx.entity:SetParent(target.entity)
	fx.entity:AddFollower()
	fx.Follower:FollowSymbol(
		target.GUID, self.followSymbol,
		offset.x, offset.y, offset.z
	)

	if self.postFireFn ~= nil then
		self.postFireFn(self.inst, fx, type)
	end

	self.fire = fx
	self.fireType = type

	if self.onToggle ~= nil then
		self.onToggle(self.inst, type)
	end
end

function TypeFire:StopFire()
	self:KillExtinguishTimer()

	if self.fire ~= nil then
		self.fire:Remove()
		self.fire = nil

		if self.onToggle ~= nil then
			self.onToggle(self.inst, nil)
		end
	end

	self.fireType = nil
end

function TypeFire:IsBurning()
	return self.fire ~= nil
end

function TypeFire:GetType()
	return self.fireType
end

-- 卸载时，停止火焰
function TypeFire:OnRemoveFromEntity()
	self:StopFire()
end
TypeFire.OnRemoveEntity = TypeFire.OnRemoveFromEntity

return TypeFire
