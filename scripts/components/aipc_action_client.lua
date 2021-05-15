local Action = Class(function(self, inst)
	self.inst = inst

	self.onDoTargetAction = nil

	-- 判断是否可以作用到物品上
	self.canActOn = nil
	self.canActOnPoint = nil
	self.canActOnTarget = nil
	self.canBeActOn = nil

	-- 是否是带网格纹理的
	self.gridplacer = false
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

return Action