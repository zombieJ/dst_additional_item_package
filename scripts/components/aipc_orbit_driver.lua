-- 双端通用组件
local Driver = Class(function(self, inst)
	self.inst = inst

	-- 绑定矿车
	self.minecar = nil
end)

function Driver:SetMineCar(inst)
	if inst.components.inventoryitem ~= nil then
		inst.components.inventoryitem:RemoveFromOwner(true)
	end

	self.minecar = inst
	self.minecar:AddTag("NOCLICK")
	self.minecar:AddTag("fx")
	self.inst:AddChild(self.minecar)
	self.minecar.persists = false
end

return Driver