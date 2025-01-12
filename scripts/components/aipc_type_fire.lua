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

	-- 是否永久
	self.forever = false

	-- 是否允许融合火焰
	self.canMix = false

	-- 火焰熄灭时间，用作加载时重新点燃
	self.extinguishReachTime = nil
	self.fireOnInst = false

	-- 火焰实体
	self.fire = nil
	self.fireType = nil

	self.onToggle = nil
end)

function TypeFire:StartExtinguishTimer(extinguishTime)
	self:KillExtinguishTimer()

	-- 如果是永久的，不需要熄灭
	if self.forever then
		return
	end

	local mergedExtinguishTime = extinguishTime or self.extinguishTime

	self.extinguishTimer = self.inst:DoTaskInTime(
		mergedExtinguishTime,
		function()
			self:StopFire()
		end
	)

	self.extinguishReachTime = GetTime() + mergedExtinguishTime
end

function TypeFire:KillExtinguishTimer()
	if self.extinguishTimer ~= nil then
		self.extinguishTimer:Cancel()
		self.extinguishTimer = nil
		self.extinguishReachTime = nil
	end
end

function TypeFire:StartFire(type, target, extinguishTime, supportMix)
	-- 不存在类型的时候跳过，防呆
	if not type then
		return
	end

	self.fireOnInst = target == nil or target == self.inst

	if type == self.fireType then
		-- 如果已经是这种火焰，延长时间
		self:StartExtinguishTimer(extinguishTime)
		return
	end

	local originType = self:IsBurning() and self.fireType or nil

	-- 重置一下火焰，如果同时有两种火焰，则会融合
	local hasHot = type == "hot" or originType == "hot"
	local hasCold = type == "cold" or originType == "cold"
	-- aipPrint("Go:", type, originType, hasHot, hasCold)

	self:StopFire()
	self:StartExtinguishTimer(extinguishTime)

	if hasHot and hasCold and self.canMix and supportMix then
		type = "mix"
	end

	-- aipPrint("Go Final:", type, hasHot, hasCold, self.canMix)

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

----------------------------- 存取 -----------------------------
-- 保存
function TypeFire:OnSave()
	if self.fireType and self.fireOnInst and (self.extinguishReachTime or self.forever) then
		local leftTime = (self.extinguishReachTime or 1) - GetTime()
		return {
			fireType = self.fireType,
			leftTime = math.max(23, leftTime)
		}
	end
end

-- 加载
function TypeFire:OnLoad(data)
	if data ~= nil and data.fireType ~= nil then
		self:StartFire(data.fireType, nil, data.leftTime or 1)
	end
end

return TypeFire
