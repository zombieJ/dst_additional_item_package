require "behaviours/wander"
require "behaviours/runaway"

local SEE_PLAYER_DIST = 6
local STOP_RUN_DIST = 10
local MAX_WANDER_DIST = 80

local MudCrabBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function MudCrabBrain:OnStart()
    local root = PriorityNode(
    {
        RunAway(
			self.inst,
			"scarytoprey",
			SEE_PLAYER_DIST,
			STOP_RUN_DIST,
			nil,
			nil,
			nil,
			true
		),
	}, .25)
    self.bt = BT(self.inst, root)
end

return MudCrabBrain