local function moveItems(src, tgt)
	if src.components.container ~= nil and tgt.components.container ~= nil then
		local numslots = tgt.components.container:GetNumSlots()
		for slot = 1, numslots do
			local srcItem = src.components.container:GetItemInSlot(slot)
			local tgtItem = tgt.components.container:GetItemInSlot(slot)

			-- 转移物品
			if srcItem ~= nil then
				if tgtItem == nil then
					src.components.container:RemoveItem(srcItem, true)
					tgt.components.container:GiveItem(srcItem, slot, nil, true)
				else
					-- 如果已经有东西，直接扔地上
					tgt.components.container:DropItemBySlot(slot)
				end
			end
		end

		tgt.components.container:GetNumSlots()
	end
end

local function collectItems(lureplant, chest)
	if lureplant == nil or lureplant.components.inventory == nil then
		return
	end

	for i = 1, 20 do
		if chest.components.container:IsFull() then
			break
		else
			-- 找到一个物品，且不能是叶肉
			local item = lureplant.components.inventory:FindItem(function(item) return not item:HasTag("nosteal") and item.prefab ~= "plantmeat" end)

			if item == nil then
				break
			else
				lureplant.components.inventory:RemoveItem(item, true)
				chest.components.container:GiveItem(item, nil, nil, true)
			end
		end
	end
end

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
			chest.components.inspectable:SetDescription(STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_GLASS_CHEST_DISABLED)

			-- 把所有箱子里的东西都移动到这个箱子里
			moveItems(chest, self.inst)
		end
	end

	-- 获取附近的食人花容器
	local x, y, z = self.inst.Transform:GetWorldPosition()
	local lureplants = TheSim:FindEntities(x, y, z, 60, nil, nil, { "lureplant", "eyeplant" })
	for i, lureplant in ipairs(lureplants) do
		collectItems(lureplant, self.inst)
	end

	-- 记录一下哪个箱子被打开了
	TheWorld.components.world_common_store.openedChest = self.inst
end

function UnityCotainer:UnlockOthers()
	-- 如果被打开的箱子关闭了，则全部解锁
	if TheWorld.components.world_common_store.openedChest == self.inst then
		for i, chest in ipairs(TheWorld.components.world_common_store.chests) do
			chest.components.container.canbeopened = true
			chest.components.inspectable:SetDescription(nil)
		end
	end
end

return UnityCotainer