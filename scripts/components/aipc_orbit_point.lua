-- 双端通用组件
local Point = Class(function(self, inst)
	self.inst = inst

	-- 绑定矿车
	self.minecar = nil
	self.fakeMinecar = nil

	-- 网络标记
	self.hasMinecar = net_bool(inst.GUID, "aipc_orbit_point_car", "aipc_orbit_point_car_dirty")

	if TheWorld.ismastersim then
		self.hasMinecar:set(false)
	end

	-- 创建的时候看看附近有没有车，放上来
	if TheWorld.ismastersim then
		self.inst:DoTaskInTime(0.1, function()
			local minecars = aipFindNearEnts(self.inst, {"aip_glass_minecar"}, 0.5)
			local minecar = minecars[1]
			if minecar ~= nil then
				self:SetMineCar(minecar)
			end
		end)
	end
end)

function disableMinecar(minecar)
	-- 矿车不能再被捡起
	if minecar.components.inventoryitem ~= nil then
		minecar.components.inventoryitem:RemoveFromOwner(true)
		minecar.components.inventoryitem.canbepickedup = false
	end

	-- 矿车不能点击
	minecar:AddTag("NOCLICK")
	minecar:AddTag("fx")
end

-- 设置矿车
function Point:SetMineCar(inst)
	if self.minecar ~= nil or inst == nil then
		return
	end

	self.minecar = inst
	self.fakeMinecar = SpawnPrefab(self.minecar.prefab)
	self.fakeMinecar.persists = false
	self.hasMinecar:set(true)
	
	disableMinecar(self.minecar)
	disableMinecar(self.fakeMinecar)

	-- 位移矿车
	local pt = self.inst:GetPosition()
	self.minecar.Physics:Teleport(pt.x, pt.y, pt.z)
	self.minecar:Hide()

	self.inst:AddChild(self.fakeMinecar)
end

-- 是否可以乘坐
function Point:CanDrive()
	return self.hasMinecar:value()
end

function Point:RemoveMineCar()
	if self.minecar ~= nil then
		self.inst:RemoveChild(self.fakeMinecar)
		self.minecar = nil
		self.hasMinecar:set(false)

		self.fakeMinecar:Remove()
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
	self.minecar:Show()

	if self.minecar.components.lootdropper ~= nil then
		self.minecar.components.lootdropper:FlingItem(self.minecar, pt)
	end
end

Point.OnRemoveFromEntity = Point.OnRemoveEntity

return Point