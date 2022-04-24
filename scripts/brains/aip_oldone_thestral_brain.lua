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
    -- self.mytarget = nil
end)

-- local function TryCast(self)
-- 	local inst = self.inst

-- 	-- 过滤尾巴
-- 	inst._aipTails = aipFilterTable(inst._aipTails, function(tail)
-- 		return tail:IsValid()
-- 	end)

-- 	-- 短路：超过 3 条尾巴 或 CD 中
-- 	if #inst._aipTails >= 3 or inst.components.timer:TimerExists("aip_cast_cd") then
-- 		return false
-- 	end

-- 	-- 附近的玩家
-- 	local players = aipFindNearPlayers(inst, TUNING.FIRE_DETECTOR_RANGE)
-- 	players = aipFilterTable(players, function(player)
-- 		return player ~= nil and
-- 			player.components.sanity ~= nil and
-- 			player.components.sanity.current > 20
-- 	end)
-- 	inst._aipSanityPlayer = aipRandomEnt(players)

-- 	return inst._aipSanityPlayer ~= nil
-- end

local pingKing = nil

local function findPigKingPos(inst)
	if pingKing == nil or not pingKing:IsValid() then
		pingKing = aipFindEnt("pigking")
	end

	local pingKingPos = pingKing and pingKing:GetPosition() or nil

	-- 太远了就随便漫步了
	return aipDist(pingKingPos, inst:GetPosition()) < 80 and pingKingPos or nil
end

function DragonBrain:OnStop()
end

function DragonBrain:OnStart()
	local root = PriorityNode({
		-- 施法动作
		-- WhileNode(
		-- 	function()
		-- 		return TryCast(self)
		-- 	end,
		-- 	"SpecialMoves",
		-- 	ActionNode(function() self.inst:PushEvent("aip_cast") end)
		-- ),

		-- 寻找目标攻击
		-- WhileNode(
		-- 	function()
		-- 		return self.inst.components.combat.target == nil or not self.inst.components.combat:InCooldown()
		-- 	end,
		-- 	"AttackMomentarily",
		-- 	ChaseAndAttack(self.inst, MAX_CHASE_TIME, MAX_CHASE_DIST)
		-- ),

		-- -- 躲闪
		-- WhileNode(
		-- 	function()
		-- 		return self.inst.components.combat.target and self.inst.components.combat:InCooldown()
		-- 	end,
		-- 	"Dodge",
		-- 	RunAway(
		-- 		self.inst,
		-- 		function() return self.inst.components.combat.target end,
		-- 		RUN_AWAY_DIST,
		-- 		STOP_RUN_AWAY_DIST
		-- 	)
		-- ),

		-- 漫步
		Wander(self.inst, findPigKingPos, 40),
	}, .25)
	
	self.bt = BT(self.inst, root)
end

return DragonBrain