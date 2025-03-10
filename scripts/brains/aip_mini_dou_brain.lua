require "behaviours/wander"
require "behaviours/standstill"
require "behaviours/aipThrowBall"

local MAX_CHASE_TIME = 30
local MAX_CHASE_DIST = 35

local RUN_AWAY_DIST = 3
local STOP_RUN_AWAY_DIST = 6

local MiniDouBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
    self.mytarget = nil
end)

function MiniDouBrain:OnStop()
end

function MiniDouBrain:OnStart()
	local root = PriorityNode({
		-- 打球
		ThrowBall(self.inst),

		-- 说话时就乖乖说话
		WhileNode(
			function() return self.inst.sg:HasStateTag("talking") end,
			"StandTalking",
			StandStill(self.inst)
		),

		-- 漫步
		Wander(
			self.inst,
			function() return self.inst.components.knownlocations:GetLocation("home") end,
			3
		),
	}, .25)
	
	self.bt = BT(self.inst, root)
end

function MiniDouBrain:OnInitializationComplete()
    self.inst.components.knownlocations:RememberLocation("home", self.inst:GetPosition())
end

return MiniDouBrain