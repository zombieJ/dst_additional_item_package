require "behaviours/follow"
require "behaviours/wander"

local MIN_FOLLOW_DIST = 1
local TARGET_FOLLOW_DIST = 3
local MAX_FOLLOW_DIST = 8

local MoldBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
    -- self.mytarget = nil
end)


function MoldBrain:OnStop()
end

function MoldBrain:OnStart()
	local root = PriorityNode({
		-- 如果附近有模因状态的人就跟随
		Follow(self.inst,
			function()
				local players = aipFindNearPlayers(self.inst, 20)

				players = aipFilterTable(players, function(player)
					return aipBufferExist(player, "aip_see_eyes")
				end)

				local target = aipFindCloseEnt(self.inst, players)

				self.inst._aipTarget = target

				return target
			end, MIN_FOLLOW_DIST, TARGET_FOLLOW_DIST, MAX_FOLLOW_DIST
		),

		-- 漫步
		Wander(self.inst),
	}, .25)
	
	self.bt = BT(self.inst, root)
end

return MoldBrain