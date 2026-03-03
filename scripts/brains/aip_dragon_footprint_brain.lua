require "behaviours/wander"
require "behaviours/runaway"

local SEE_PLAYER_DIST = 5
local STOP_RUN_DIST = 10
local MAX_WANDER_DIST = 80

local DragonFootprintBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function DragonFootprintBrain:OnStart()
    local root = PriorityNode(
    {
        RunAway(
			self.inst,
			"scarytoprey",
			SEE_PLAYER_DIST,
			STOP_RUN_DIST
		),
		Wander(
			self.inst,
			nil,
			MAX_WANDER_DIST
		),
    }, .25)
    self.bt = BT(self.inst, root)
end

return DragonFootprintBrain