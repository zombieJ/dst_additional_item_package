-- https://gitee.com/anxin1225/BehaviourTree
require "behaviours/wander"
require "behaviours/chaseandattack"
require "behaviours/follow"
require "behaviours/panic"

local DragonBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
    self.mytarget = nil
end)

function DragonBrain:OnStop()
    aipPrint("stop!!!")
end

function DragonBrain:OnStart()
    aipPrint("start!!!")

	-- local root = PriorityNode(
	-- 	{
	-- 		-- 如果目标在海上就传送到海上
	-- 		IfNode(
	-- 			function()
	-- 				return targetatsea(self.inst)
	-- 			end,
	-- 			"target on land",
	-- 			DoAction(self.inst, teleport)
	-- 		),

	-- 		-- 是否可以攻击目标
	-- 		WhileNode(
	-- 			function()
	-- 				return ShouldAttack(self)
	-- 			end,
	-- 			"Attack",
	-- 			ChaseAndAttack(self.inst, 100)
	-- 		),

	-- 		-- 是否骚扰目标
	-- 		WhileNode(
	-- 			function()
	-- 				return ShouldHarass(self)
	-- 			end,
	-- 			"Harass",
	-- 			PriorityNode({
	-- 				WhileNode(
	-- 					function()
	-- 						return ShouldChaseAndHarass(self)
	-- 					end,
	-- 					"ChaseAndHarass",
	-- 					Follow(
	-- 						self.inst,
	-- 						function() return self._harasstarget end,
	-- 						HARASS_MIN,
	-- 						HARASS_MED,
	-- 						HARASS_MAX
	-- 					)
	-- 				),

	-- 				ActionNode(
	-- 					function()
	-- 						self.inst.components.combat:BattleCry()
	-- 						if self.inst.sg.currentstate.name == "taunt" then
	-- 							self.inst:ForceFacePoint(self._harasstarget.Transform:GetWorldPosition())
	-- 						end
	-- 					end
	-- 				),
	-- 			}, .25)
	-- 		),

	-- 		-- 游荡
	-- 		WhileNode(
	-- 			function()
	-- 				return self._harasstarget ~= nil and self._harasstarget:IsValid()
	-- 			end,
	-- 			"LoiterAndHarass",
	-- 			Wander(
	-- 				self.inst,
	-- 				function() return self._harasstarget:GetPosition() end,
	-- 				20,
	-- 				{ minwaittime = 0, randwaittime = .3 },
	-- 				function() return GetHarassWanderDir(self) end
	-- 			)
	-- 		),

	-- 		-- 跟随
	-- 		Follow(self.inst, function() return self.mytarget end, MIN_FOLLOW, MED_FOLLOW, MAX_FOLLOW),

	-- 		-- 漫步
	-- 		Wander(self.inst, function() return self.mytarget ~= nil and self.mytarget:GetPosition() or nil end, 20),
	-- 	}, .25)

	local root = PriorityNode(
		{
			-- 被作祟时痛苦的乱动
			WhileNode(
				function() return self.inst.components.hauntable and self.inst.components.hauntable.panic end,
				"PanicHaunted",
				Panic(self.inst)
			),

			-- 着火了乱动
			WhileNode(
				function() return self.inst.components.health.takingfiredamage end,
				"OnFire",
				Panic(self.inst)
			),

			-- 寻找目标攻击
			WhileNode(
				function() return self.inst.components.combat.target == nil or not self.inst.components.combat:InCooldown() end,
				"AttackMomentarily",
				ChaseAndAttack(self.inst, SpringCombatMod(MAX_CHASE_TIME), SpringCombatMod(MAX_CHASE_DIST))
			),

			-- 躲闪
			WhileNode(
				function() return self.inst.components.combat.target and self.inst.components.combat:InCooldown() end,
				"Dodge",
				RunAway(self.inst, function() return self.inst.components.combat.target end, RUN_AWAY_DIST, STOP_RUN_AWAY_DIST)
			),

			-- 回家
			DoAction(self.inst, function() return beecommon.GoHomeAction(self.inst) end, "go home", true ),

			-- 游荡
			Wander(self.inst, function() return self.inst.components.knownlocations:GetLocation("home") end, beecommon.MAX_WANDER_DIST)            
		},1)
	
		self.bt = BT(self.inst, root)
end

return DragonBrain