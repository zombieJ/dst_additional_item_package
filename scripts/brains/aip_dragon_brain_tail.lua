require "behaviours/wander"
require "behaviours/chaseandattack"

local NOTAGS = { "FX", "NOCLICK", "DECOR", "playerghost", "INLIMBO" }

local MAX_CHASE_TIME = 30
local MAX_CHASE_DIST = 35

local RUN_AWAY_DIST = 3
local STOP_RUN_AWAY_DIST = 6

local DragonTailBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
    self.mytarget = nil
end)

function DragonTailBrain:OnStop()
end

function DragonTailBrain:OnStart()
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
				STOP_RUN_AWAY_DIST
			)
		),

		-- 漫步
		Wander(self.inst, function() return nil end, 40),
	}, .25)
	
	self.bt = BT(self.inst, root)
end

return DragonTailBrain