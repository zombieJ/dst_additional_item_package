local Projectile = Class(function(self, inst)
	self.inst = inst
end)

function Projectile:DoAction(doer)
	if self.onDoAction then
		self.onDoAction(self.inst, doer)
	end
end


return Projectile