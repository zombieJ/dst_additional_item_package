return Class(function(self, inst)

assert(TheWorld.ismastersim, "Wormhole_Counter should not exist on client")

	self.inst = inst
	self.shadow_follower_count = 0

	function self:isShadowFollowing()
		return self.shadow_follower_count > 0
	end
end)