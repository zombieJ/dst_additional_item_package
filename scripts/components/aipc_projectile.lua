local Projectile = Class(function(self, inst)
	self.inst = inst
	self.queue = {}

	-- 出生后便会自动监听
	self.inst:StartUpdatingComponent(self)
end)

function Projectile:StartBy(doer, queue)
	self.inst.Transform:SetPosition(doer.Transform:GetWorldPosition())
end


function Projectile:OnUpdate(dt)
	-- 没有队列的话就可以清理了
	if #self.queue == 0 then
		self.inst:Remove()
	end
end


return Projectile