require "behaviours/follow"
require "behaviours/wander"

local MIN_FOLLOW_DIST = 1
local TARGET_FOLLOW_DIST = 3
local MAX_FOLLOW_DIST = 8

local MoldBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
    -- self.mytarget = nil
end)


local function FindFoodAction(inst)
    if not inst.sg:HasStateTag("busy") and inst.components.inventory ~= nil then
        local target = inst.components.inventory:FindItem(function(item) return item:HasTag("aip_nectar") end)

        if target ~= nil then
			aipPrint("eat!!!")
            return BufferedAction(inst, target, ACTIONS.EAT)
        end
    end
end


function MoldBrain:OnStop()
end

function MoldBrain:OnStart()
	local root = PriorityNode({
		-- 吃物品栏中的食物
		DoAction(self.inst, FindFoodAction),

		-- 漫步
		Wander(self.inst),
	}, .25)
	
	self.bt = BT(self.inst, root)
end

return MoldBrain