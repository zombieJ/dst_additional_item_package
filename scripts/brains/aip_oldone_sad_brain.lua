require "behaviours/wander"
require "behaviours/chaseandattack"

local OldoneSadBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
    self.mytarget = nil
end)

local function GoHomeAction(inst)
    if inst.components.homeseeker and
       inst.components.homeseeker.home and
       inst.components.homeseeker.home:IsValid() then
        return BufferedAction(inst, inst.components.homeseeker.home, ACTIONS.GOHOME)
    end
end

function OldoneSadBrain:OnStop()
end

function OldoneSadBrain:OnStart()
	local root = PriorityNode({
		WhileNode( -- 幽魂只会回家
			function() return true end,
			"HasBOSS",
			DoAction(self.inst, GoHomeAction, "go home", true )),
	}, .25)
	
	self.bt = BT(self.inst, root)
end

return OldoneSadBrain