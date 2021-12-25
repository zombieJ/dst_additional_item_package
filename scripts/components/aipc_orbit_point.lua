-- 双端通用组件
local Driver = Class(function(self, inst)
	self.inst = inst

	-- 绑定矿车
	self.minecar = nil
end)

-- 设置矿车
function Driver:SetMineCar(inst)
	if self.minecar ~= nil or inst == nil or inst.components.aipc_orbit_minecar == nil then
		return
	end

	self.minecar = inst
	self.minecar.components.aipc_orbit_minecar:BindPoint(self.inst)

	self.inst:AddChild(self.minecar)
end

-- 是否可以乘坐
function Driver:CanDrive()
	return self.minecar ~= nil
end

-- 玩家上车了
function Driver:Drive(doer)
	if self.minecar ~=nil and self.minecar.components.aipc_orbit_minecar ~= nil then
		self.minecar.components.aipc_orbit_minecar:TakeBy(doer)
	end
end

return Driver