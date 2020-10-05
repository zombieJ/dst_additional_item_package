local CommonStore = Class(function(self, inst)
	self.inst = inst
	self.shadow_follower_count = 0
	-- 记录目前哪个箱子被打开了
	self.openedChest = nil
	-- 记录所有的箱子
	self.chests = {}
end)

function CommonStore:isShadowFollowing()
	return self.shadow_follower_count > 0
end

return CommonStore