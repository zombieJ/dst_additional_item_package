local Action = Class(function(self, inst)
	self.inst = inst

	self.onDoAction = nil
	self.onDoTargetAction = nil
	self.onDoGiveAction = nil
	self.onDoPointAction = nil
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

-- 玩家把 item 给 inst
function Action:DoGiveAction(doer, item)
	if self.onDoGiveAction then
		self.onDoGiveAction(self.inst, doer, item)
	end
end

function Action:DoPointAction(doer, point)
	if self.onDoPointAction then
		self.onDoPointAction(self.inst, doer, point)
	end
end

return Action