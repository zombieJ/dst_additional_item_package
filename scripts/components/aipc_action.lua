local Action = Class(function(self, inst)
	self.inst = inst

	self.onDoAction = nil
end)

function Action:DoAction()
	if self.onDoAction then
		self.onDoAction(self.inst)
	end
end

return Action