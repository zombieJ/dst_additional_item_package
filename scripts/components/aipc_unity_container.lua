-- 合并箱子中的物品
local function moveItems(src, tgt)
	if src.components.container ~= nil and tgt.components.container ~= nil then
		local numslots = tgt.components.container:GetNumSlots()
		for slot = 1, numslots do
			local srcItem = src.components.container:GetItemInSlot(slot)
			local tgtItem = tgt.components.container:GetItemInSlot(slot)

			-- 转移物品
			if srcItem ~= nil then
				-- 如果已经有东西，直接扔地上（不应该出现，不过以防万一扔出来）
				tgt.components.container:DropItemBySlot(slot)

				-- 转移咯
				src.components.container:RemoveItem(srcItem, true)
				tgt.components.container:GiveItem(srcItem, slot, nil, true)
			end
		end

		tgt.components.container:GetNumSlots()
	end
end

-- 收集物品
local function collectItems(lureplant)
	if lureplant == nil or lureplant.components.inventory == nil or #TheWorld.components.world_common_store.chests == 0 then
		return
	end

	local holderChest = TheWorld.components.world_common_store.holderChest
	if holderChest == nil then
		-- 如果没有容器，则随机选一个作为容器
		holderChest = TheWorld.components.world_common_store.chests[1]
		TheWorld.components.world_common_store.holderChest = holderChest
	end

	-- 收集食人花内的物品
	local items = lureplant.components.inventory:FindItems(function(item)
		return not item:HasTag("nosteal") and item.prefab ~= "plantmeat"
	end)

	for i, item in ipairs(items) do
		if not holderChest.components.container:IsFull() then
			-- 箱子没满就随便放
			lureplant.components.inventory:RemoveItem(item, true)
			holderChest.components.container:GiveItem(item, nil, nil, true)
		elseif item.components.stackable == nil then
			-- 不可堆叠的满了就不继续了
			break
		else
			-- 可堆叠的需要额外判断
			local restCount = 0 -- 相同类型的剩余可叠加数量
			for slot = 1, holderChest.components.container:GetNumSlots() do
				local chestItem = holderChest.components.container:GetItemInSlot(slot)

				if chestItem and chestItem.prefab == item.prefab and chestItem.skinname == item.skinname and not chestItem.components.stackable:IsFull() then
					restCount = restCount + chestItem.components.stackable:RoomLeft()
				end
			end

			-- 满了，就在食人花中移除掉
			if restCount >= item.components.stackable:StackSize() then
				lureplant.components.inventory:RemoveItem(item, true)
			end
			holderChest.components.container:GiveItem(item)
		end
	end
end

------------------------------------------------------------------------------------------
local UnityCotainer = Class(function(self, inst)
	self.inst = inst

	-- 全局注册
	table.insert(TheWorld.components.world_common_store.chests, self.inst)

	-- 每隔一段时间收取食人花内的物品（食人花 20 秒消化一次，我们 19 秒收集一次保证都收集到）
	self.task = self.inst:DoPeriodicTask(19, function() self:CollectLureplant() end)

	-- 异步标记当前为最重要的箱子
	self.inst:DoTaskInTime(0.5, function()
		if self.inst.components.container ~= nil and not self.inst.components.container:IsEmpty() then
			TheWorld.components.world_common_store.holderChest = self.inst
		end
	end)

	-- 移除时从全局删除
	self.inst:ListenForEvent("onremove", function()
		for i, v in ipairs(TheWorld.components.world_common_store.chests) do
			if v == self.inst then
				table.remove(TheWorld.components.world_common_store.chests, i)
			end
		end

		self:UnlockOthers()
	end)
end)

function UnityCotainer:CollectLureplant()
	-- 获取附近的食人花容器
	local x, y, z = self.inst.Transform:GetWorldPosition()
	local lureplants = TheSim:FindEntities(x, y, z, 60, nil, nil, { "lureplant", "eyeplant" })
	for i, lureplant in ipairs(lureplants) do
		collectItems(lureplant)
	end
end

function UnityCotainer:LockOthers()
	for i, chest in ipairs(TheWorld.components.world_common_store.chests) do
		if chest ~= self.inst then
			chest.components.container.canbeopened = false
			chest.components.inspectable:SetDescription(STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_GLASS_CHEST_DISABLED)

			-- 把所有箱子里的东西都移动到这个箱子里
			moveItems(chest, self.inst)
		end
	end

	-- 打开的时候强制收集一次
	self:CollectLureplant()

	-- 记录一下当前主要管理箱子是谁
	TheWorld.components.world_common_store.holderChest = self.inst
	TheWorld.components.world_common_store.chestOpened = true
end

function UnityCotainer:UnlockOthers()
	-- 如果被打开的箱子关闭了，则全部解锁
	if TheWorld.components.world_common_store.holderChest == self.inst then
		for i, chest in ipairs(TheWorld.components.world_common_store.chests) do
			chest.components.container.canbeopened = true
			chest.components.inspectable:SetDescription(nil)
		end
	end

	-- 更新记录箱子已经关闭
	TheWorld.components.world_common_store.chestOpened = false
end

return UnityCotainer