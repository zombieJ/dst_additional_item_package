local Action = Class(function(self, inst)
	self.inst = inst

	self.onDoAction = nil
	self.onDoTargetAction = nil

	-- 判断是否可以作用到物品上
	self.canActOn = nil
	self.canActOnPoint = nil
end)

function Action:CanActOn(target, doer)
	if self.canActOn then
		return self.canActOn(self.inst, target, doer)
	end
	return false
end

function Action:CanActOnPoint(doer, pos)
	if self.canActOnPoint then
		return self.canActOnPoint(self.inst, doer, pos)
	end
	return false
end

return Action