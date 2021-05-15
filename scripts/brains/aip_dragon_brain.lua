-- https://gitee.com/anxin1225/BehaviourTree
require "behaviours/wander"
require "behaviours/chaseandattack"
require "behaviours/follow"
require "behaviours/panic"

local NOTAGS = { "FX", "NOCLICK", "DECOR", "playerghost", "INLIMBO" }

local MAX_CHASE_TIME = 30
local MAX_CHASE_DIST = 35

local RUN_AWAY_DIST = 3
local STOP_RUN_AWAY_DIST = 6

local DragonBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
    self.mytarget = nil
end)

local function TryCast(self)
	local inst = self.inst

	-- 过滤尾巴
	inst._aipTails = aipFilterTable(inst._aipTails, function(tail)
		return tail:IsValid()
	end)

	-- 短路：超过 3 条尾巴 或 CD 中
	if #inst._aipTails >= 3 or inst.components.timer:TimerExists("aip_cast_cd") then
		return false
	end

	-- 附近的玩家
	local players = aipFindNearPlayers(inst, TUNING.FIRE_DETECTOR_RANGE)
	players = aipFilterTable(players, function(player)
		return player ~= nil and
			player.components.sanity ~= nil and
			player.components.sanity.current > 20
	end)
	inst._aipSanityPlayer = aipRandomEnt(players)

	return inst._aipSanityPlayer ~= nil
end

function DragonBrain:OnStop()
end

function DragonBrain:OnStart()
	-- 暗影怪
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

	-- 杀人蜂
	-- local root = PriorityNode(
	-- 	{
	-- 		-- 被作祟时痛苦的乱动
	-- 		WhileNode(
	-- 			function() return self.inst.components.hauntable and self.inst.components.hauntable.panic end,
	-- 			"PanicHaunted",
	-- 			Panic(self.inst)
	-- 		),

	-- 		-- 着火了乱动
	-- 		WhileNode(
	-- 			function() return self.inst.components.health.takingfiredamage end,
	-- 			"OnFire",
	-- 			Panic(self.inst)
	-- 		),

	-- 		-- 寻找目标攻击
	-- 		WhileNode(
	-- 			function() return self.inst.components.combat.target == nil or not self.inst.components.combat:InCooldown() end,
	-- 			"AttackMomentarily",
	-- 			ChaseAndAttack(self.inst, SpringCombatMod(MAX_CHASE_TIME), SpringCombatMod(MAX_CHASE_DIST))
	-- 		),

	-- 		-- 躲闪
	-- 		WhileNode(
	-- 			function() return self.inst.components.combat.target and self.inst.components.combat:InCooldown() end,
	-- 			"Dodge",
	-- 			RunAway(self.inst, function() return self.inst.components.combat.target end, RUN_AWAY_DIST, STOP_RUN_AWAY_DIST)
	-- 		),

	-- 		-- 回家
	-- 		DoAction(self.inst, function() return beecommon.GoHomeAction(self.inst) end, "go home", true ),

	-- 		-- 游荡
	-- 		Wander(self.inst, function() return self.inst.components.knownlocations:GetLocation("home") end, beecommon.MAX_WANDER_DIST)            
	-- 	},1)

	local root = PriorityNode({
		-- 施法动作
		WhileNode(
			function()
				return TryCast(self)
			end,
			"SpecialMoves",
			ActionNode(function() self.inst:PushEvent("aip_cast") end)
		),

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

return DragonBrain