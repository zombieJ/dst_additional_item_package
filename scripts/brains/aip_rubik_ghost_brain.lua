require "behaviours/wander"
require "behaviours/chaseandattack"

local NOTAGS = { "FX", "NOCLICK", "DECOR", "playerghost", "INLIMBO" }

local MAX_CHASE_DIST = 15
local MAX_CHASE_TIME = 8

local MAX_WANDER_DIST = 20

local RUN_AWAY_DIST = 3
local STOP_RUN_AWAY_DIST = 5
local STOP_RUN_AWAY_DIST_MAX = 8

local RubikGhostBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
    self.mytarget = nil
end)

function RubikGhostBrain:OnStop()
end

function RubikGhostBrain:OnStart()
	local root = PriorityNode({
		-- 寻找目标攻击
		WhileNode(
			function()
				return self.inst.components.combat.target == nil or not self.inst.components.combat:InCooldown()
			end,
			"AttackMomentarily",
			ChaseAndAttack(self.inst, MAX_CHASE_TIME, MAX_CHASE_DIST)
		),

		-- 躲闪
		WhileNode(
			function()
				return self.inst.components.combat.target and self.inst.components.combat:InCooldown()
			end,
			"Dodge",
			RunAway(
				self.inst,
				function() return self.inst.components.combat.target end,
				RUN_AWAY_DIST,
				math.random(STOP_RUN_AWAY_DIST, STOP_RUN_AWAY_DIST_MAX)
			)
		),

		-- 漫步
		Wander(self.inst, function() return self.inst.components.knownlocations:GetLocation("home") end, MAX_WANDER_DIST),
	}, .25)
	
	self.bt = BT(self.inst, root)
end

return RubikGhostBrain