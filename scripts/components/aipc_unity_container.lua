-- 合并箱子中的物品
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
					-- 如果已经有东西，直接扔地上（不应该出现，不过以防万一扔出来）
					tgt.components.container:DropItemBySlot(slot)
				end
			end
		end

		tgt.components.container:GetNumSlots()
	end
end

-- 收集物品
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

------------------------------------------------------------------------------------------
local UnityCotainer = Class(function(self, inst)
	self.inst = inst

	-- 全局注册
	table.insert(TheWorld.components.world_common_store.chests, self.inst)

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