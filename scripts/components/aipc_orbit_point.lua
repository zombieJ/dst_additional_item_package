-- 双端通用组件
local Point = Class(function(self, inst)
	self.inst = inst

	-- 绑定矿车
	self.minecar = nil
end)

-- 设置矿车
function Point:SetMineCar(inst)
	if self.minecar ~= nil or inst == nil then
		return
	end

	self.minecar = inst
	
	-- 矿车不能再被捡起
	if self.minecar.components.inventoryitem ~= nil then
		self.minecar.components.inventoryitem:RemoveFromOwner(true)
		self.minecar.components.inventoryitem.canbepickedup = false
	end

	-- 矿车不能点击
	self.minecar:AddTag("NOCLICK")
	self.minecar:AddTag("fx")

	self.inst:AddChild(self.minecar)
end

-- 是否可以乘坐
function Point:CanDrive()
	return self.minecar ~= nil
end

function Point:RemoveMineCar()
	if self.minecar ~= nil then
		self.inst:RemoveChild(self.minecar)
		self.minecar = nil
	end
end

-- 玩家上车了
function Point:Drive(doer)
	if self.minecar ~=nil and doer and doer.components.aipc_orbit_driver ~= nil then
		local canTake = doer.components.aipc_orbit_driver:UseMineCar(self.minecar, self.inst)

		if canTake then
			self:RemoveMineCar()
		end
	end
end

-- 拆除时会掉落矿车
function Point:OnRemoveEntity()
	if not self.minecar then
		return
	end
	

	local pt = self.inst:GetPosition()
	self.inst:RemoveChild(self.minecar)
	self.minecar.Physics:Teleport(pt.x, pt.y, pt.z)
	
	-- 矿车不能再被捡起
	if self.minecar.components.inventoryitem ~= nil then
		self.minecar.components.inventoryitem.canbepickedup = true
	end

	-- 矿车不能点击
	self.minecar:RemoveTag("NOCLICK")
	self.minecar:RemoveTag("fx")

	if self.minecar.components.lootdropper ~= nil then
		self.minecar.components.lootdropper:FlingItem(self.minecar, pt)
	end
end

Point.OnRemoveFromEntity = Point.OnRemoveEntity

return Point