-- 创建一个类型火焰，绑定到目标上
local TypeFire = Class(function(self, inst)
	self.inst = inst

	self.hotPrefab = nil
	self.coldPrefab = nil
	self.mixPrefab = nil
	self.followSymbol = nil
	self.followOffset = Vector3(0, 0, 0)
	self.postFireFn = nil

	-- 火焰实体
	self.fire = nil
	self.fireType = nil
end)

function TypeFire:StartFire(type, target)
	if type == self.fireType then
		return
	end

	self:StopFire()

	target = target or self.inst
	local firePrefab = self.hotPrefab
	if type == "mix" then
		firePrefab = self.mixPrefab
	elseif type == "cold" then
		firePrefab = self.coldPrefab
	end

	-- 创建火焰
	local fx = SpawnPrefab(firePrefab)
	fx.entity:SetParent(target.entity)
	fx.entity:AddFollower()
	fx.Follower:FollowSymbol(
		target.GUID, self.followSymbol,
		self.followOffset.x, self.followOffset.y, self.followOffset.z
	)

	if self.postFireFn ~= nil then
		self.postFireFn(self.inst, fx, type)
	end

	self.fire = fx
	self.fireType = type
end

function TypeFire:StopFire()
	if self.fire ~= nil then
		self.fire:Remove()
		self.fire = nil
	end

	self.fireType = nil
end

-- 卸载时，停止火焰
function TypeFire:OnRemoveFromEntity()
	self:StopFire()
end
TypeFire.OnRemoveEntity = TypeFire.OnRemoveFromEntity

return TypeFire
