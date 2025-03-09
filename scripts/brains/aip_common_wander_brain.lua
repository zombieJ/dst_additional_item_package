-- 根据 knownlocations 的 home 位置漫步
require "behaviours/wander"

local CommonWanderBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)


local MAX_WANDER_DIST = 5

function CommonWanderBrain:OnStop()
end

function CommonWanderBrain:OnStart()
	local root = PriorityNode({
		-- 漫步
		Wander(
			self.inst,
			function()
				return self.inst.components.knownlocations:GetLocation("home")
			end,
			MAX_WANDER_DIST,
            {minwalktime=50,  randwalktime=3, minwaittime=1.5, randwaittime=0.5}
		)
	}, .25)
	
	self.bt = BT(self.inst, root)
end

return CommonWanderBrain