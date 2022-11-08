local Action = Class(function(self, inst)
	self.inst = inst

	self.onDoTargetAction = nil

	-- 判断是否可以作用到物品上
	self.canActOn = nil
	self.canActOnPoint = nil
	self.canActOnTarget = nil
	self.canBeActOn = nil
	self.canBeGiveOn = nil
	self.canBeTakeOn = nil
	self.canBeCastOn = nil
	self.canBeRead = nil
	self.canBeEat = nil

	-- 是否是带网格纹理的
	self.gridplacer = false
end)

function Action:CanActOn(doer, target)
	if self.canActOn then
		return self.canActOn(self.inst, doer, target)
	end
	return false
end

function Action:CanBeActOn(doer)
	if self.canBeActOn then
		return self.canBeActOn(self.inst, doer)
	end
	return false
end

-- 可以被拿取
function Action:CanBeGiveOn(doer, item)
	if self.canBeGiveOn then
		return self.canBeGiveOn(self.inst, doer, item)
	end
	return false
end

-- 可以被拿取
function Action:CanBeTakeOn(doer)
	if self.canBeTakeOn then
		return self.canBeTakeOn(self.inst, doer)
	end
	return false
end

function Action:CanBeCastOn(doer)
	if self.canBeCastOn then
		return self.canBeCastOn(self.inst, doer)
	end
	return false
end

function Action:CanBeRead(doer)
	if self.canBeRead then
		return self.canBeRead(self.inst, doer)
	end
	return false
end

function Action:CanBeEat(doer)
	if self.canBeEat then
		return self.canBeEat(self.inst, doer)
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