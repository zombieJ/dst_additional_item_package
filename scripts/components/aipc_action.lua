local Action = Class(function(self, inst)
	self.inst = inst

	self.onDoAction = nil
	self.onDoTargetAction = nil
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

return Action