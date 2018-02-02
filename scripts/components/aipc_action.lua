local Action = Class(function(self, inst)
	self.inst = inst

	self.onDoAction = nil
end)

function Action:DoAction(doer)
	if self.onDoAction then
		self.onDoAction(self.inst, doer)
	end
end

return Action