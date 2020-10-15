-- 飞行器，玩家添加后会飞向目标地点。落地后删除该组件
local Flyer = Class(function(self, inst)
	self.inst = inst
end)

function Flyer:FlyTo(pos)

end

return Flyer