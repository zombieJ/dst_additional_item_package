-- 这个组件用于清除 side effect
local Player = Class(function(self, inst)
	self.inst = inst
end)

function Player:Destroy()
	-- MineCar
	self.inst:RemoveTag("aip_minecar_driver")
end

Player.OnRemoveEntity = MineCar.Destroy

return Player