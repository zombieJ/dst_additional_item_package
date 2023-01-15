require "behaviours/wander"

local PetBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
    -- self.mytarget = nil
end)

function PetBrain:OnStop()
end

function PetBrain:OnStart()
	local root = PriorityNode({
		-- 漫步
		Wander(self.inst, function()
			return nil
		end, 40),
	}, .25)
	
	self.bt = BT(self.inst, root)
end

return PetBrain