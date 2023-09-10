local dev_mode = aipGetModConfig("dev_mode") == "enabled"

local Brain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function Brain:OnStop()
end

function Brain:OnStart()
	local root = PriorityNode({
		-- 往家里走
		IfNode(
			function() return self.inst._aipHome ~= nil end,
			"GoToStone",
            DoAction(
				self.inst,
				function()
					local homePos = self.inst._aipHome:GetPosition()
					self.inst:ForceFacePoint(homePos.x, homePos.y, homePos.z)

					-- 到家检测
					local dist = aipDist(self.inst:GetPosition(), homePos)
					if dist <= 1 and self.inst._aipHome.components.aipc_blackhole_gamer then
						self.inst._aipHome.components.aipc_blackhole_gamer:Reach(self.inst)
					end

					-- 往家走去
					return BufferedAction(self.inst, self.inst._aipHome, ACTIONS.GOHOME)
				end,
				"go home",
				true
			)),
	}, .25)
	
	self.bt = BT(self.inst, root)
end

return Brain