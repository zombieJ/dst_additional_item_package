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
end)


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
		-- 漫步
		Wander(self.inst, findPigKingPos, 40),
	}, .25)
	
	self.bt = BT(self.inst, root)
end

return DragonBrain