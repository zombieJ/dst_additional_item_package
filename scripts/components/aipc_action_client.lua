local Action = Class(function(self, inst)
	self.inst = inst

	self.onDoAction = nil
	self.onDoTargetAction = nil

	-- 判断是否可以作用到物品上
	self.canActOn = nil
	self.canActOnPoint = nil
	self.canActOnTarget = nil
	self.canBeActOn = nil

	-- 做行动
	self.onDoAction = nil
end)

function Action:CanActOn(doer, target)
	if self.canActOn then
		return self.canActOn(self.inst, doer, target)
	end
	return false
end

function Action:CanActOnPoint(doer, pos)
	if self.canActOnPoint then
		return self.canActOnPoint(self.inst, doer, pos)
	end
	return false
end

function Action:CanBeActOn(doer)
	aipTypePrint("Can Be Act!!!", doer)
	if self.canBeActOn then
		return self.canBeActOn(self.inst, doer)
	end
	return false
end

function Action:DoAction(doer)
	aipTypePrint("Action Dialog!!!", doer)
	if self.onDoAction then
		self.onDoAction(self.inst, doer)
	end
end

return Action