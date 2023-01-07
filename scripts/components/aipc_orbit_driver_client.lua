----------------------------------- 客户端 -----------------------------------
local Driver = Class(function(self, player)
	self.inst = player

	self.isDriving = net_bool(self.inst.GUID, "aipc_orbit_driving", "aipc_orbit_driving_dirty")
	if TheWorld.ismastersim then
		self.isDriving:set(false)
	end

	self.inst:ListenForEvent("aipc_orbit_driving_dirty", function()
		-- 仅对当前玩家锁定屏幕 & 同步更新速度保持稳定
		if self.inst == ThePlayer then
			if not self.isDriving:value() then
				TheCamera:SetFlyView(false)
			end
		end
	end)
end)

return Driver