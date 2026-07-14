local questConfig = require("configurations/aip_pig_village_quest")

local PigVillageQuest = Class(function(self, inst)
	self.inst = inst
	self.taskPrefab = nil
	self.requiredCount = 0
	self.deliveredCount = 0
	self.isCompleting = false

	self.resident = nil
	self.marker = nil
	self.markerTarget = nil
	self.runtimeTask = nil

	self.originalHouseDescriptionFn = inst.components.inspectable ~= nil and
		inst.components.inspectable.descriptionfn or nil
	self._onHouseIgnite = function()
		if self:IsActive() then
			self:ClearQuest()
		end
	end

	self.inst:ListenForEvent("onignite", self._onHouseIgnite)

	if inst.components.inspectable ~= nil then
		inst.components.inspectable.descriptionfn = function(house, viewer)
			if self:IsActive() then
				return self:GetHouseDescription()
			end

			return self.originalHouseDescriptionFn ~= nil and
				self.originalHouseDescriptionFn(house, viewer) or nil
		end
	end
end)

-- 获取任务物资的本地化名称。
function PigVillageQuest:GetItemName()
	if self.taskPrefab == nil then
		return ""
	end

	return STRINGS.NAMES[string.upper(self.taskPrefab)] or self.taskPrefab
end

-- 判断猪窝当前是否记录了一个有效任务。
function PigVillageQuest:IsActive()
	return self.taskPrefab ~= nil and self.requiredCount > 0 and
		self.deliveredCount < self.requiredCount
end

-- 获取任务尚未交付的数量。
function PigVillageQuest:GetRemainingCount()
	return math.max(0, self.requiredCount - self.deliveredCount)
end

-- 生成猪人检查文本。
function PigVillageQuest:GetPigDescription()
	return string.format(
		questConfig.LANG.PIG_DESC,
		self.requiredCount,
		self:GetItemName(),
		self:GetRemainingCount()
	)
end

-- 生成猪窝检查文本。
function PigVillageQuest:GetHouseDescription()
	return string.format(
		questConfig.LANG.HOUSE_DESC,
		self:GetItemName(),
		self.deliveredCount,
		self.requiredCount
	)
end

-- 创建指定数量的可包装物品。
local function CreateItemStack(source, prefab, count)
	if prefab == nil or count == nil or count <= 0 then
		return nil
	end

	local item = aipSpawnPrefab(source, prefab)
	if item == nil then
		return nil
	end

	if item.components.stackable ~= nil and count > 1 then
		item.components.stackable:SetStackSize(count)
	end
	return item
end

-- 把现有物品交给玩家，背包放不下时抛到来源位置。
local function GiveItemToPlayer(player, item, source)
	if item == nil or not item:IsValid() then
		return
	end

	local shouldMergeFragments = item.prefab == "aip_train_ticket_fragment"
	local sourcePos = source ~= nil and source:GetPosition() or nil
	if player ~= nil and player:IsValid() and player.components.inventory ~= nil then
		player.components.inventory:GiveItem(item, nil, sourcePos)
		if shouldMergeFragments and aipMergeTrainTicketFragments ~= nil then
			aipMergeTrainTicketFragments(player)
		end
	else
		aipFlingItem(item, sourcePos)
	end
end

-- 把任务奖励和超量物资装入一次性的冬季盛宴礼物。
local function GiveRewardGift(player, source, contents)
	local items = {}
	for _, content in ipairs(contents) do
		local item = CreateItemStack(source, content.prefab, content.count)
		if item ~= nil then
			table.insert(items, item)
		end
	end

	local gift = aipSpawnPrefab(source, "gift")
	if gift ~= nil and gift.components.unwrappable ~= nil and #items > 0 then
		gift.components.unwrappable:WrapItems(items, player)
		for _, item in ipairs(items) do
			item:Remove()
		end
		aipFlingItem(gift)
		return
	end

	if gift ~= nil then
		gift:Remove()
	end
	for _, item in ipairs(items) do
		GiveItemToPlayer(player, item, source)
	end
end

-- 恢复猪人的原版交易与检查逻辑。
function PigVillageQuest:DetachResident(pig)
	pig = pig or self.resident
	if pig == nil then
		return
	end

	local original = pig._aipPigVillageQuestOriginal
	if original ~= nil and original.quest == self then
		if pig:IsValid() and pig.components.trader ~= nil then
			local trader = pig.components.trader
			trader:SetAcceptTest(original.test)
			trader:SetOnAccept(original.onaccept)
			trader:SetOnRefuse(original.onrefuse)
			trader.acceptstacks = original.acceptstacks
			trader.deleteitemonaccept = original.deleteitemonaccept
			trader.acceptnontradable = original.acceptnontradable
		end

		if pig:IsValid() and pig.components.inspectable ~= nil and
			pig.components.inspectable.descriptionfn == original.questDescriptionFn
		then
			pig.components.inspectable.descriptionfn = original.descriptionfn
		end

		pig._aipPigVillageQuestOriginal = nil
	end

	if self.resident == pig then
		self.resident = nil
	end
end

-- 把猪窝任务能力临时绑定到当前居民猪人。
function PigVillageQuest:AttachResident(pig)
	if pig == nil or not pig:IsValid() or pig.components.trader == nil then
		return
	end

	if self.resident == pig and pig._aipPigVillageQuestOriginal ~= nil then
		return
	end

	self:DetachResident()
	if pig._aipPigVillageQuestOriginal ~= nil and
		pig._aipPigVillageQuestOriginal.quest ~= self
	then
		pig._aipPigVillageQuestOriginal.quest:DetachResident(pig)
	end

	local trader = pig.components.trader
	local original = {
		quest = self,
		test = trader.test,
		onaccept = trader.onaccept,
		onrefuse = trader.onrefuse,
		acceptstacks = trader.acceptstacks,
		deleteitemonaccept = trader.deleteitemonaccept,
		acceptnontradable = trader.acceptnontradable,
		descriptionfn = pig.components.inspectable ~= nil and
			pig.components.inspectable.descriptionfn or nil,
	}

	-- 复用原版 alltrader 标签接收没有 tradable 组件的基础物资。
	trader:SetAcceptStacks()
	trader.deleteitemonaccept = true
	trader.acceptnontradable = true
	trader:SetAcceptTest(function(_, item)
		return self:IsActive() and item ~= nil and item.prefab == self.taskPrefab
	end)
	trader:SetOnAccept(function(_, giver, _, count)
		self:AcceptDelivery(pig, giver, count or 1)
	end)
	trader:SetOnRefuse(function(inst, giver, item)
		if original.onrefuse ~= nil then
			original.onrefuse(inst, giver, item)
		end
		if inst.components.talker ~= nil and self:IsActive() then
			inst.components.talker:Say(string.format(
				questConfig.LANG.WRONG_ITEM,
				self:GetItemName()
			))
		end
	end)

	if pig.components.inspectable ~= nil then
		original.questDescriptionFn = function(inst, viewer)
			if self:IsActive() and self.resident == inst then
				-- LOOKAT 默认由玩家朗读检查文本，任务内容改由猪人自己说出。
				if inst.components.talker ~= nil then
					inst.components.talker:Say(self:GetPigDescription())
					return false
				end

				return self:GetPigDescription()
			end
			return original.descriptionfn ~= nil and original.descriptionfn(inst, viewer) or nil
		end
		pig.components.inspectable.descriptionfn = original.questDescriptionFn
	end

	pig._aipPigVillageQuestOriginal = original
	self.resident = pig
end

-- 更新感叹号标记的跟随目标。
function PigVillageQuest:SetMarkerTarget(target)
	if self.markerTarget == target and self.marker ~= nil and self.marker:IsValid() then
		return
	end

	if self.marker ~= nil and self.marker:IsValid() then
		self.marker:Remove()
	end
	self.marker = nil
	self.markerTarget = target

	if target ~= nil and target:IsValid() and self:IsActive() then
		self.marker = aipSpawnPrefab(target, "aip_pig_village_quest_marker")
		if self.marker ~= nil then
			target:AddChild(self.marker)
			self.marker.Transform:SetPosition(0, 0, 0)
		end
	end
end

-- 同步当前居民、交易回调和任务标记。
function PigVillageQuest:SyncRuntime()
	if not self:IsActive() or self.inst.components.spawner == nil then
		return
	end

	local resident = self.inst.components.spawner.child
	if resident ~= nil and resident:IsValid() and
		(resident.components.health == nil or not resident.components.health:IsDead())
	then
		self:AttachResident(resident)
		self:SetMarkerTarget(
			self.inst.components.spawner:IsOccupied() and self.inst or resident
		)
	else
		self:DetachResident()
		self:SetMarkerTarget(self.inst)
	end
end

-- 开启任务所需的低频运行时同步。
function PigVillageQuest:StartRuntime()
	if self.runtimeTask == nil then
		self.runtimeTask = self.inst:DoPeriodicTask(questConfig.RUNTIME_SYNC_INTERVAL, function()
			self:SyncRuntime()
		end, 0)
	end
end

-- 停止运行时同步并恢复猪人状态。
function PigVillageQuest:StopRuntime()
	if self.runtimeTask ~= nil then
		self.runtimeTask:Cancel()
		self.runtimeTask = nil
	end

	self:DetachResident()
	self:SetMarkerTarget(nil)
end

-- 给猪窝创建一个新的物资任务。
function PigVillageQuest:StartQuest(prefab, requiredCount)
	if self:IsActive() or prefab == nil or requiredCount == nil then
		return false
	end

	self.taskPrefab = prefab
	self.requiredCount = requiredCount
	self.deliveredCount = 0
	self.isCompleting = false
	self:StartRuntime()
	self:SyncRuntime()
	return true
end

-- 清空已经完成或被取消的任务。
function PigVillageQuest:ClearQuest()
	self:StopRuntime()
	self.taskPrefab = nil
	self.requiredCount = 0
	self.deliveredCount = 0
	self.isCompleting = false
end

-- 完成任务并把奖励、碎片和超量物资封入礼物。
function PigVillageQuest:CompleteQuest(pig, giver, extraCount)
	if self.isCompleting or self.taskPrefab == nil or self.requiredCount <= 0 then
		return
	end
	self.isCompleting = true

	local taskPrefab = self.taskPrefab
	local requiredCount = self.requiredCount
	local reward = questConfig.PickReward(requiredCount)

	if pig ~= nil and pig:IsValid() and pig.components.talker ~= nil then
		pig.components.talker:Say(questConfig.LANG.COMPLETE)
	end

	self:ClearQuest()
	local giftContents = {
		{
			prefab = "aip_train_ticket_fragment",
			count = 1,
		},
	}
	if reward ~= nil then
		table.insert(giftContents, 1, reward)
	end
	if extraCount ~= nil and extraCount > 0 then
		table.insert(giftContents, {
			prefab = taskPrefab,
			count = extraCount,
		})
	end
	GiveRewardGift(giver, pig or self.inst, giftContents)

	self.inst:PushEvent("aip_pig_village_quest_completed", {
		player = giver,
		pig = pig,
		task_prefab = taskPrefab,
		required_count = requiredCount,
	})
end

-- 接收猪人交易传入的一组任务物资。
function PigVillageQuest:AcceptDelivery(pig, giver, count)
	if not self:IsActive() or self.isCompleting then
		return
	end

	local remaining = self:GetRemainingCount()
	local acceptedCount = math.min(math.max(count or 1, 1), remaining)
	local extraCount = math.max(0, (count or 1) - acceptedCount)

	self.deliveredCount = self.deliveredCount + acceptedCount
	if self.deliveredCount >= self.requiredCount then
		self:CompleteQuest(pig, giver, extraCount)
	elseif pig ~= nil and pig:IsValid() and pig.components.talker ~= nil then
		pig.components.talker:Say(string.format(
			questConfig.LANG.RECEIVED,
			self:GetItemName(),
			self:GetRemainingCount()
		))
	end
end

-- 移除组件时恢复猪人并清理非持久化标记。
function PigVillageQuest:OnRemoveFromEntity()
	self.inst:RemoveEventCallback("onignite", self._onHouseIgnite)
	self:StopRuntime()
end

return PigVillageQuest
