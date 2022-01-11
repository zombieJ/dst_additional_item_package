-- 跨端通用
local Fueled = Class(function(self, inst)
	self.inst = inst

	self.prefab = nil
	self.onFueled = nil
end)

function Fueled:CanUse(inst, doer)
	return inst and inst.prefab == self.prefab
end

function Fueled:TakeFuel(inst, doer)
	if self.onFueled ~= nil then
		self.onFueled(self.inst, inst, doer)
	end

	if inst.components.stackable ~= nil then
		inst.components.stackable:Get():Remove()
	else
		inst:Remove()
	end

	return true
end

return Fueled