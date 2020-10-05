local UnityCotainer = Class(function(self, inst)
	self.inst = inst

	-- 全局注册
	table.insert(TheWorld.components.world_common_store.chests, self.inst)

	-- 移除时删除
	self.inst:ListenForEvent("onremove", function()
		for i, v in ipairs(TheWorld.components.world_common_store.chests) do
			if v == self.inst then
				table.remove(TheWorld.components.world_common_store.chests, self.inst)
			end
		end
	end)
end)

function UnityCotainer:LockOthers()
	for i, chest in ipairs(TheWorld.components.world_common_store.chests) do
		if chest ~= self.inst then
			chest.components.container.canbeopened = false
		end
	end

	-- 记录一下哪个箱子被打开了
	TheWorld.components.world_common_store.openedChest = self.inst
end

function UnityCotainer:UnlockOthers()
	-- 如果被打开的箱子关闭了，则全部解锁
	if TheWorld.components.world_common_store.openedChest == self.inst then
		for i, chest in ipairs(TheWorld.components.world_common_store.chests) do
			chest.components.container.canbeopened = true
		end
	end
end

return UnityCotainer