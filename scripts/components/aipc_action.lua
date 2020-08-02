local Action = Class(function(self, inst)
	self.inst = inst

	self.onDoAction = nil
	self.onDoTargetAction = nil

	-- 判断是否可以作用到物品上
	self.canActOn = nil
end)

function Action:DoAction(doer)
	if self.onDoAction then
		self.onDoAction(self.inst, doer)
	end
end

function Action:DoTargetAction(doer, target)
	if self.onDoTargetAction then
		self.onDoTargetAction(self.inst, doer, target)
	end
end

function Action:CanActOn(target, doer)
	if self.canActOn then
		return self.canActOn(self.inst, target, doer)
	end
	return false
end

return Action