if aipGetModConfig("dev_mode") ~= "enabled" then return {} end

local E2E = {}
local LOG_PREFIX = "[PigKingTrain][E2E]"
local ACTION_TIMEOUT = 12
local FIND_INTERVAL = 0.1
local FIND_ATTEMPTS = 40
local KING_INTERACTION_RADII = { 2.75, 3.25, 3.75 }
local KING_INTERACTION_ATTEMPTS = 16

E2E.STEPS = {
	setup = "E2E 真实白天与猪人委托场景准备",
	quest1_dialogue = "E2E 委托 1：玩家检查猪人并展示需求",
	quest1_grant = "E2E 委托 1：直接发放需求物品",
	quest1_trade = "E2E 委托 1：玩家真实给予猪人",
	quest1_reward = "E2E 委托 1：礼物拆包与碎片入包",
	quest2_dialogue = "E2E 委托 2：玩家检查猪人并展示需求",
	quest2_grant = "E2E 委托 2：直接发放需求物品",
	quest2_trade = "E2E 委托 2：玩家真实给予猪人",
	quest2_reward = "E2E 委托 2：礼物拆包与碎片入包",
	quest3_dialogue = "E2E 委托 3：玩家检查猪人并展示需求",
	quest3_grant = "E2E 委托 3：直接发放需求物品",
	quest3_trade = "E2E 委托 3：玩家真实给予猪人",
	quest3_reward = "E2E 委托 3：礼物拆包与碎片入包",
	merge = "E2E 三张碎片自动合成完整体验券",
	king_trade = "E2E 完整体验券真实交给猪王并上车",
}

E2E.ACTION_SEQUENCE = {
	"LOOKAT", "GIVE", "UNWRAP",
	"LOOKAT", "GIVE", "UNWRAP",
	"LOOKAT", "GIVE", "UNWRAP",
	"GIVE",
}

E2E.QUESTS = {
	{ prefab = "cutgrass", count = 2 },
	{ prefab = "twigs", count = 2 },
	{ prefab = "rocks", count = 2 },
}

-- 输出每个真实动作的开始和结果，实机日志可还原完整玩家操作链。
local function Debug(ctx, ...)
	aipPrint(LOG_PREFIX, "generation=" .. tostring(ctx.session.generation), ...)
end

-- 记录测试创建的实体，失败、重启和正常收尾都统一移除。
local function TrackEntity(ctx, inst)
	if inst ~= nil then
		ctx.entities[inst] = true
		inst._aip_train_e2e_generation = ctx.session.generation
	end
	return inst
end

-- 判断实体是否仍可被本轮动作使用。
local function IsValid(inst)
	return inst ~= nil and inst:IsValid()
end

-- 统计玩家物品栏中的指定物品，包含背包。
local function InventoryCount(inventory, prefab)
	local _, count = inventory:Has(prefab, 1)
	return count or 0
end

-- 把玩家原有的同名物品临时移出场景，避免测试碎片与真实存档物品合堆。
local function StashItem(ctx, item)
	local inventoryItem = item ~= nil and item.components.inventoryitem or nil
	local owner = inventoryItem ~= nil and inventoryItem.owner or nil
	local holder = owner ~= nil and (owner.components.inventory or owner.components.container) or nil
	if holder == nil then return false end
	local slot = inventoryItem.GetSlotNum ~= nil and inventoryItem:GetSlotNum() or nil
	local equipSlot = nil
	if owner.components.inventory == holder then
		for candidateSlot, equipped in pairs(holder.equipslots) do
			if equipped == item then equipSlot = candidateSlot break end
		end
	end
	local removed = holder:RemoveItem(item, true)
	if removed ~= item then return false end
	item:RemoveFromScene()
	table.insert(ctx.stashed, { item = item, owner = owner, slot = slot, equipSlot = equipSlot })
	return true
end

-- 隔离会影响合成或本轮交付的原有物品，并保证主物品栏至少留出一个槽位。
local function StashConflictingInventory(ctx)
	local inventory = ctx.doer.components.inventory
	local conflicts = {
		aip_train_ticket_fragment = true,
		aip_train_ticket = true,
		cutgrass = true,
		twigs = true,
		rocks = true,
	}
	for _, item in ipairs(inventory:FindItems(function(candidate)
		return conflicts[candidate.prefab] == true or candidate.components.closeinspector ~= nil
	end)) do
		assert(StashItem(ctx, item), "无法暂存冲突物品：" .. tostring(item.prefab))
	end
	for slot = 1, inventory.maxslots do
		if inventory.itemslots[slot] == nil then return end
	end
	for _, item in pairs(inventory.itemslots) do
		if item.prefab ~= "aip_pig_king_train_test_ticket" then
			assert(StashItem(ctx, item), "无法为 E2E 物品腾出背包槽位")
			return
		end
	end
	error("背包没有可用于 E2E 物品的槽位")
end

-- 恢复测试前暂存的玩家物品，原容器不可用时回退到玩家物品栏。
local function RestoreStashedInventory(ctx)
	for _, entry in ipairs(ctx.stashed) do
		local item = entry.item
		if IsValid(item) then
			item:ReturnToScene()
			local owner = IsValid(entry.owner) and entry.owner or ctx.doer
			local holder = owner ~= nil and (owner.components.inventory or owner.components.container) or nil
			if holder ~= nil then holder:GiveItem(item, entry.slot, ctx.savedPosition) end
			if entry.equipSlot ~= nil and holder ~= nil and holder.Equip ~= nil
				and item.components.inventoryitem.owner == owner then
				holder:Equip(item)
			end
			if item.components.inventoryitem.owner == nil and IsValid(ctx.doer)
				and ctx.doer.components.inventory ~= nil then
				ctx.doer.components.inventory:GiveItem(item, nil, ctx.savedPosition)
			end
		end
	end
	ctx.stashed = {}
end

-- 为场景实体选择猪王附近的安全自然地面。
local function FindStagePoint(king)
	local point = aipGetSecretSpawnPoint(king:GetPosition(), 10, 18, 5, true)
	if point == nil then return nil end
	if not TheWorld.Map:IsPassableAtPoint(point.x, 0, point.z) then return nil end
	return point
end

-- 在猪王碰撞体外、GIVE 有效距离内分级寻找可站立点，避免自然地皮筛选误拒绝村庄地面。
function E2E.FindKingInteractionPoint(king)
	local origin = king:GetPosition()
	local startAngle = math.random() * 2 * math.pi
	for tier, radius in ipairs(KING_INTERACTION_RADII) do
		local offset = FindWalkableOffset(origin, startAngle, radius,
			KING_INTERACTION_ATTEMPTS, false, true, nil, false, false)
		if offset ~= nil then
			local point = Vector3(origin.x + offset.x, 0, origin.z + offset.z)
			if TheWorld.Map:IsPassableAtPoint(point.x, 0, point.z) then
				return point, tier, radius
			end
		end
	end
	return nil, #KING_INTERACTION_RADII
end

-- 给真实猪人安装只读对话探针，同时保留原版说话回调。
local function InstallTalkProbe(ctx, pig)
	local talker = assert(pig.components.talker, "猪人缺少 talker 组件")
	ctx.originalTalkerOnTalk = talker.ontalk
	talker.ontalk = function(inst, script)
		local text = type(script) == "string" and script or tostring(script)
		table.insert(ctx.speeches, text)
		if ctx.expectedSpeech ~= nil and text == ctx.expectedSpeech then
			ctx.sawExpectedSpeech = true
		end
		if ctx.originalTalkerOnTalk ~= nil then
			return ctx.originalTalkerOnTalk(inst, script)
		end
	end
end

-- 恢复猪人的原版说话回调，避免测试探针泄漏到下一次会话。
local function RemoveTalkProbe(ctx)
	local pig = ctx.pig
	if IsValid(pig) and pig.components.talker ~= nil then
		pig.components.talker.ontalk = ctx.originalTalkerOnTalk
	end
	ctx.originalTalkerOnTalk = nil
end

-- 完成一个带成功、失败和有限超时的真实 BufferedAction。
local function RunAction(ctx, actionName, action, onComplete)
	ctx.actionSerial = ctx.actionSerial + 1
	local serial = ctx.actionSerial
	ctx.activeAction = action
	Debug(ctx, "action=" .. actionName, "state=start",
		"target=" .. tostring(action.target ~= nil and action.target.prefab or nil),
		"item=" .. tostring(action.invobject ~= nil and action.invobject.prefab or nil))
	local finished = false
	local function Complete(success, detail)
		if finished or ctx.cancelled or ctx.actionSerial ~= serial then return end
		finished = true
		ctx.activeAction = nil
		Debug(ctx, "action=" .. actionName, "state=complete",
			"success=" .. tostring(success), "detail=" .. tostring(detail))
		ctx.hooks.later(0.1, function() onComplete(success, detail) end)
	end
	action:AddSuccessAction(function() Complete(true, "success") end)
	action:AddFailAction(function() Complete(false, action.reason or "action_failed") end)
	ctx.doer.components.locomotor:PushAction(action, true)
	ctx.hooks.later(ACTION_TIMEOUT, function()
		if finished or ctx.cancelled or ctx.actionSerial ~= serial then return end
		if ctx.doer.GetBufferedAction ~= nil and ctx.doer:GetBufferedAction() == action then
			ctx.doer:ClearBufferedAction()
		end
		Complete(false, "timeout")
	end)
end

-- 在当前会话中按 key 开始一个可观察的 E2E 步骤。
local function BeginStep(ctx, key, ...)
	ctx.currentStep = key
	ctx.hooks.begin(key)
	Debug(ctx, "stage=" .. key, "state=start", ...)
end

-- 结束当前 E2E 步骤并写入单行诊断。
local function PassStep(ctx, key, detail)
	Debug(ctx, "stage=" .. key, "state=complete", "result=pass", "detail=" .. tostring(detail))
	ctx.hooks.pass(key, detail)
end

-- 结束无法继续的 E2E 步骤并进入测试券统一收尾。
local function FailStep(ctx, key, detail)
	if ctx.failed or ctx.cancelled then return end
	ctx.failed = true
	Debug(ctx, "stage=" .. tostring(key), "state=complete", "result=fail",
		"detail=" .. tostring(detail))
	ctx.hooks.fail(key, detail)
end

-- 判断礼物内容中是否包含本轮体验券碎片。
local function GiftContainsFragment(gift)
	local itemdata = gift ~= nil and gift.components.unwrappable ~= nil
		and gift.components.unwrappable.itemdata or nil
	for _, record in ipairs(itemdata or {}) do
		if record.prefab == "aip_train_ticket_fragment" then return true end
	end
	return false
end

-- 查找本轮附近刚生成且尚未登记的目标实体。
local function FindNewEntity(ctx, prefab, center, radius, predicate)
	local radiusSq = radius * radius
	for _, inst in pairs(Ents) do
		if IsValid(inst) and inst.prefab == prefab and not ctx.initialGuids[inst.GUID]
			and not ctx.seenGuids[inst.GUID] then
			local point = inst:GetPosition()
			local dx, dz = point.x - center.x, point.z - center.z
			if dx * dx + dz * dz <= radiusSq and (predicate == nil or predicate(inst)) then
				ctx.seenGuids[inst.GUID] = true
				return TrackEntity(ctx, inst)
			end
		end
	end
	return nil
end

-- 有限等待新礼物或拆包物品进入实体表。
local function WaitForEntity(ctx, prefab, centerFn, radius, predicate, attempt, onComplete)
	local inst = FindNewEntity(ctx, prefab, centerFn(), radius, predicate)
	if inst ~= nil then
		onComplete(inst)
	elseif attempt >= FIND_ATTEMPTS then
		onComplete(nil, "等待 " .. prefab .. " 超时")
	else
		ctx.hooks.later(FIND_INTERVAL, function()
			WaitForEntity(ctx, prefab, centerFn, radius, predicate, attempt + 1, onComplete)
		end)
	end
end

-- 拆包后登记附近所有新物品，奖励会在上车前随场景统一清除。
local function TrackNearbyDrops(ctx)
	local center = ctx.doer:GetPosition()
	for _, inst in pairs(Ents) do
		if IsValid(inst) and inst.components.inventoryitem ~= nil and not ctx.initialGuids[inst.GUID]
			and not ctx.seenGuids[inst.GUID] then
			local point = inst:GetPosition()
			local dx, dz = point.x - center.x, point.z - center.z
			if dx * dx + dz * dz <= 20 * 20 then
				ctx.seenGuids[inst.GUID] = true
				TrackEntity(ctx, inst)
			end
		end
	end
end

-- 收尾前补登记仍在玩家物品栏中的本轮生成物，包含规划失败时正式逻辑返还的券。
local function TrackNewInventoryItems(ctx)
	local inventory = IsValid(ctx.doer) and ctx.doer.components.inventory or nil
	if inventory == nil then return end
	for _, item in ipairs(inventory:FindItems(function(candidate)
		return not ctx.initialGuids[candidate.GUID]
	end)) do
		TrackEntity(ctx, item)
	end
end

-- 把测试已经找到的物品直接放入玩家物品栏，不把无关的捡取过程塞进 E2E。
local function PutTestItemInInventory(ctx, item, label)
	assert(IsValid(item) and item.components.inventoryitem ~= nil,
		"无法放入测试物品：" .. tostring(label))
	local prefab = item.prefab
	local amount = item.components.stackable ~= nil and item.components.stackable:StackSize() or 1
	local before = InventoryCount(ctx.doer.components.inventory, prefab)
	ctx.doer.components.inventory:GiveItem(item, nil, ctx.doer:GetPosition())
	local after = InventoryCount(ctx.doer.components.inventory, prefab)
	assert(after >= before + amount,
		string.format("测试物品没有进入玩家物品栏：%s，%d->%d", tostring(label), before, after))
end

-- 每个真实交互前固定双方到近距离，避免测试把自动寻路误当成功能覆盖。
local function PlaceForPigInteraction(ctx)
	assert(IsValid(ctx.pig), "E2E 猪人已经失效")
	if ctx.pig.components.locomotor ~= nil then ctx.pig.components.locomotor:Stop() end
	if ctx.pig.components.sleeper ~= nil and ctx.pig.components.sleeper:IsAsleep() then
		ctx.pig.components.sleeper:WakeUp()
	end
	ctx.pig.Physics:Teleport(ctx.pigPoint.x, 0, ctx.pigPoint.z)
	ctx.doer.Physics:Teleport(ctx.interactionPoint.x, 0, ctx.interactionPoint.z)
end

-- 直接创建本轮委托物资并放入玩家物品栏，后续交付仍走真实 GIVE 动作。
local function GrantQuestItem(ctx, questData)
	local item = assert(SpawnPrefab(questData.prefab), "无法生成需求物品：" .. questData.prefab)
	item.persists = false
	TrackEntity(ctx, item)
	if item.components.stackable ~= nil then item.components.stackable:SetStackSize(questData.count) end
	ctx.doer.components.inventory:GiveItem(item, nil, ctx.doer:GetPosition())
	assert(item:IsValid() and item.components.inventoryitem:GetGrandOwner() == ctx.doer,
		"需求物品没有进入玩家物品栏")
	return item
end

local StartQuest

-- 测试夹具把礼物放入背包，玩家只执行真正需要验证的拆包动作。
local function CollectQuestReward(ctx, questIndex, gift)
	local key = "quest" .. tostring(questIndex) .. "_reward"
	BeginStep(ctx, key, "gift=" .. tostring(gift.GUID))
	local prepared, prepareError = pcall(PutTestItemInInventory, ctx, gift, "委托礼物")
	if not prepared then FailStep(ctx, key, prepareError) return end
	RunAction(ctx, "UNWRAP_GIFT", BufferedAction(ctx.doer, nil, ACTIONS.UNWRAP, gift),
		function(unwrapped, unwrapDetail)
			if not unwrapped then
				FailStep(ctx, key, "礼物拆包失败：" .. tostring(unwrapDetail))
				return
			end
			ctx.hooks.later(0.5, function()
				WaitForEntity(ctx, "aip_train_ticket_fragment",
					function() return ctx.doer:GetPosition() end, 20, nil, 1,
					function(fragment, findError)
						if fragment == nil then FailStep(ctx, key, findError) return end
						TrackNearbyDrops(ctx)
						local inserted, insertError = pcall(
							PutTestItemInInventory, ctx, fragment, "体验券碎片")
						if not inserted then FailStep(ctx, key, insertError) return end
						ctx.receivedFragments = ctx.receivedFragments + 1
						local inventoryFragments = InventoryCount(ctx.doer.components.inventory,
							"aip_train_ticket_fragment")
						local mergeScheduled = ctx.doer._aipTrainTicketMergeTask ~= nil
						if questIndex == #E2E.QUESTS and not mergeScheduled then
							FailStep(ctx, key, "第三张碎片入包后没有安排正式合成任务")
							return
						end
						PassStep(ctx, key, string.format(
							"quest=%d,gift=%s,fragment=%s,received=%d,inventoryFragments=%d,mergeScheduled=%s,action=UNWRAP,directInventory=true",
							questIndex, tostring(gift.GUID), tostring(fragment.GUID),
							ctx.receivedFragments, inventoryFragments, tostring(mergeScheduled)))
						if questIndex < #E2E.QUESTS then
							ctx.hooks.later(0.75, function() StartQuest(ctx, questIndex + 1) end)
						else
							ctx.hooks.later(0.75, function()
								local mergeKey = "merge"
								BeginStep(ctx, mergeKey)
								local function WaitForTicket(attempt)
									local ticket = ctx.doer.components.inventory:FindItem(function(item)
										return item.prefab == "aip_train_ticket"
									end)
									if ticket ~= nil then
										TrackEntity(ctx, ticket)
										ctx.ticket = ticket
										local fragments = InventoryCount(ctx.doer.components.inventory,
											"aip_train_ticket_fragment")
										if fragments ~= 0 then
											FailStep(ctx, mergeKey, "合成后仍有测试碎片：" .. fragments)
											return
										end
										PassStep(ctx, mergeKey, "fragments=3,tickets=1,ticket="
											.. tostring(ticket.GUID))
										E2E.ReleaseFixture(ctx.session, ticket)
										ctx.hooks.done(ticket, string.format(
											"quests=%d,fragments=%d,tickets=1,actions=LOOKAT>GIVE>UNWRAP",
											#E2E.QUESTS, ctx.receivedFragments))
									elseif attempt >= FIND_ATTEMPTS then
										FailStep(ctx, mergeKey, string.format(
											"三张碎片没有在有限时间内合成完整券；inventoryFragments=%d；mergeScheduled=%s",
											InventoryCount(ctx.doer.components.inventory,
												"aip_train_ticket_fragment"),
											tostring(ctx.doer._aipTrainTicketMergeTask ~= nil)))
									else
										ctx.hooks.later(FIND_INTERVAL, function() WaitForTicket(attempt + 1) end)
									end
								end
								WaitForTicket(1)
							end)
						end
					end)
			end)
		end)
end

-- 通过真实 GIVE 动作完成一项猪人委托，并等待奖励礼物落地。
local function DeliverQuest(ctx, questIndex, item)
	local key = "quest" .. tostring(questIndex) .. "_trade"
	BeginStep(ctx, key, "prefab=" .. item.prefab)
	local positioned, positionError = pcall(PlaceForPigInteraction, ctx)
	if not positioned then FailStep(ctx, key, positionError) return end
	ctx.completedEvent = nil
	RunAction(ctx, "GIVE_QUEST_ITEM", BufferedAction(ctx.doer, ctx.pig, ACTIONS.GIVE, item),
		function(success, detail)
			if not success then FailStep(ctx, key, "给予动作失败：" .. tostring(detail)) return end
			if ctx.quest:IsActive() or ctx.completedEvent == nil
				or ctx.completedEvent.player ~= ctx.doer then
				FailStep(ctx, key, "给予动作没有完成真实委托事件")
				return
			end
			WaitForEntity(ctx, "gift", function() return ctx.pig:GetPosition() end, 24,
				GiftContainsFragment, 1, function(gift, findError)
					if gift == nil then FailStep(ctx, key, findError) return end
					ctx.gift = gift
					PassStep(ctx, key, string.format(
						"quest=%d,prefab=%s,count=%d,event=true,gift=%s,action=GIVE",
						questIndex, tostring(ctx.completedEvent.task_prefab),
						ctx.completedEvent.required_count or 0, tostring(gift.GUID)))
					ctx.hooks.later(0.75, function() CollectQuestReward(ctx, questIndex, gift) end)
				end)
		end)
end

-- 把当前任务需求物资直接发给玩家，下一步才由玩家动作交给猪人。
local function GrantQuest(ctx, questIndex)
	local questData = E2E.QUESTS[questIndex]
	local key = "quest" .. tostring(questIndex) .. "_grant"
	BeginStep(ctx, key, "prefab=" .. questData.prefab, "count=" .. questData.count)
	local ok, item = pcall(GrantQuestItem, ctx, questData)
	if not ok then FailStep(ctx, key, item) return end
	ctx.questItem = item
	PassStep(ctx, key, string.format("prefab=%s,count=%d,owner=player",
		questData.prefab, questData.count))
	ctx.hooks.later(0.75, function() DeliverQuest(ctx, questIndex, item) end)
end

-- 玩家已由测试夹具放在交互距离内，只通过 LOOKAT 验证真实需求对话。
StartQuest = function(ctx, questIndex)
	local questData = E2E.QUESTS[questIndex]
	local key = "quest" .. tostring(questIndex) .. "_dialogue"
	BeginStep(ctx, key, "prefab=" .. questData.prefab, "count=" .. questData.count)
	if not ctx.quest:StartQuest(questData.prefab, questData.count) then
		FailStep(ctx, key, "无法开始真实猪人委托")
		return
	end
	ctx.quest:SyncRuntime()
	ctx.expectedSpeech = ctx.quest:GetPigDescription()
	ctx.sawExpectedSpeech = false
	local positioned, positionError = pcall(PlaceForPigInteraction, ctx)
	if not positioned then FailStep(ctx, key, positionError) return end
	RunAction(ctx, "LOOKAT_PIG", BufferedAction(ctx.doer, ctx.pig, ACTIONS.LOOKAT),
		function(_, lookDetail)
			ctx.hooks.later(0.25, function()
				if not ctx.sawExpectedSpeech then
					FailStep(ctx, key, "LOOKAT 未展示需求：" .. tostring(lookDetail))
					return
				end
				PassStep(ctx, key, string.format(
					"quest=%d,prefab=%s,count=%d,speech=%s,action=LOOKAT",
					questIndex, questData.prefab, questData.count, ctx.expectedSpeech))
				ctx.hooks.later(0.75, function() GrantQuest(ctx, questIndex) end)
			end)
		end)
end

-- 创建真实猪屋和居民猪人，并把玩家直接放到交互距离内。
local function PrepareFixture(ctx)
	assert(ctx.doer.components.inventory ~= nil, "玩家缺少 inventory 组件")
	assert(ctx.doer.components.locomotor ~= nil, "玩家缺少 locomotor 组件")
	assert(ctx.doer.Physics ~= nil, "玩家缺少 Physics")
	ctx.savedPosition = ctx.doer:GetPosition()
	for _, inst in pairs(Ents) do ctx.initialGuids[inst.GUID] = true end
	StashConflictingInventory(ctx)
	local stagePoint = assert(FindStagePoint(ctx.king), "猪王附近没有安全 E2E 场地")
	ctx.stagePoint = stagePoint
	local house = assert(SpawnPrefab("pighouse"), "无法生成 E2E 猪屋")
	house.persists = false
	house.Transform:SetPosition(stagePoint.x, 0, stagePoint.z)
	ctx.house = TrackEntity(ctx, house)
	local spawner = assert(house.components.spawner, "E2E 猪屋缺少 spawner 组件")
	spawner:CancelSpawning()
	spawner:ReleaseChild()
	local pig = assert(spawner.child, "E2E 猪屋没有居民猪人")
	pig.persists = false
	ctx.pig = TrackEntity(ctx, pig)
	ctx.pigPoint = pig:GetPosition()
	if pig.components.sleeper ~= nil and pig.components.sleeper:IsAsleep() then
		pig.components.sleeper:WakeUp()
	end
	ctx.quest = assert(house.components.aipc_pig_village_quest, "E2E 猪屋缺少委托组件")
	InstallTalkProbe(ctx, pig)
	ctx.onQuestCompleted = function(_, data) ctx.completedEvent = data end
	house:ListenForEvent("aip_pig_village_quest_completed", ctx.onQuestCompleted)
	local interactionPoint = aipGetSecretSpawnPoint(ctx.pigPoint, 1.5, 2.5, 1, true)
	assert(interactionPoint ~= nil, "E2E 场地附近没有玩家交互点")
	ctx.interactionPoint = interactionPoint
	PlaceForPigInteraction(ctx)
	Debug(ctx, "fixture=ready", "house=" .. tostring(house.GUID),
		"pig=" .. tostring(pig.GUID),
		string.format("housePos=(%.1f,%.1f)", stagePoint.x, stagePoint.z),
		string.format("pigPos=(%.1f,%.1f)", ctx.pigPoint.x, ctx.pigPoint.z),
		string.format("playerPos=(%.1f,%.1f)", interactionPoint.x, interactionPoint.z))
end

-- 移除猪人交互场景和拆包奖励，只保留即将交给猪王的测试体验券。
function E2E.ReleaseFixture(session, ticket)
	local ctx = session.e2e
	if ctx == nil or ctx.fixtureReleased then return end
	ctx.fixtureReleased = true
	RemoveTalkProbe(ctx)
	ctx.cancelled = true
	ctx.actionSerial = ctx.actionSerial + 1
	for inst in pairs(ctx.entities) do
		if inst ~= ticket and IsValid(inst) then inst:Remove() end
	end
	ctx.cancelled = false
	Debug(ctx, "fixture=released", "ticket=" .. tostring(ticket ~= nil and ticket.GUID or nil))
end

-- 重启、失败和正常结束都恢复玩家物品并删除本轮 E2E 实体。
function E2E.Cleanup(session)
	local ctx = session.e2e
	if ctx == nil or ctx.cleaned then return true end
	ctx.cleaned = true
	ctx.cancelled = true
	ctx.actionSerial = ctx.actionSerial + 1
	if IsValid(ctx.doer) and ctx.doer.GetBufferedAction ~= nil
		and ctx.doer:GetBufferedAction() == ctx.activeAction then
		ctx.doer:ClearBufferedAction()
	end
	if IsValid(ctx.doer) and ctx.doer.components.locomotor ~= nil then
		ctx.doer.components.locomotor:Stop()
	end
	if IsValid(ctx.doer) and ctx.doer._aipTrainTicketMergeTask ~= nil then
		ctx.doer._aipTrainTicketMergeTask:Cancel()
		ctx.doer._aipTrainTicketMergeTask = nil
	end
	RemoveTalkProbe(ctx)
	TrackNewInventoryItems(ctx)
	for inst in pairs(ctx.entities) do if IsValid(inst) then inst:Remove() end end
	RestoreStashedInventory(ctx)
	if IsValid(ctx.doer) and ctx.savedPosition ~= nil
		and (ctx.session.run == nil or ctx.session.run.boarded ~= true) then
		ctx.doer.Physics:Stop()
		ctx.doer.Physics:Teleport(ctx.savedPosition.x, 0, ctx.savedPosition.z)
	end
	local remaining = 0
	for inst in pairs(ctx.entities) do if IsValid(inst) then remaining = remaining + 1 end end
	ctx.remaining = remaining
	local detail = remaining > 0 and ("E2E 实体残留：" .. tostring(remaining)) or nil
	return remaining == 0, detail
end

-- 在白天阶段准备真实交互场景并启动三轮完整猪人委托。
function E2E.Start(session, king, hooks)
	local ctx = {
		session = session,
		doer = session.doer,
		king = king,
		hooks = hooks,
		entities = {},
		stashed = {},
		initialGuids = {},
		seenGuids = {},
		speeches = {},
		receivedFragments = 0,
		actionSerial = 0,
	}
	session.e2e = ctx
	Debug(ctx, "stage=setup", "state=start")
	local ok, err = pcall(PrepareFixture, ctx)
	if not ok then FailStep(ctx, "setup", err) return false end
	PassStep(ctx, "setup", string.format("house=%s,pig=%s,phase=day",
		tostring(ctx.house.GUID), tostring(ctx.pig.GUID)))
	hooks.later(0.75, function() StartQuest(ctx, 1) end)
	return true
end

-- 使用完整体验券执行真实 GIVE 动作，并以 paid 运行记录证明猪王交易链路成功。
function E2E.GiveTicketToKing(session, king, ticket, hooks)
	local ctx = session.e2e
	if ctx == nil then hooks.fail("king_trade", "E2E 场景不存在") return end
	if not IsValid(ticket) then FailStep(ctx, "king_trade", "完整体验券不存在") return end
	ctx.hooks = hooks
	BeginStep(ctx, "king_trade", "ticket=" .. tostring(ticket.GUID),
		"king=" .. tostring(king.GUID))
	local kingPoint, searchTier, searchRadius = E2E.FindKingInteractionPoint(king)
	if kingPoint == nil then
		FailStep(ctx, "king_trade", string.format(
			"猪王附近没有安全交互点；tiers=%d；attemptsPerTier=%d；maxRadius=%.2f",
			searchTier or #KING_INTERACTION_RADII, KING_INTERACTION_ATTEMPTS,
			KING_INTERACTION_RADII[#KING_INTERACTION_RADII]))
		return
	end
	Debug(ctx, "stage=king_trade", "interactionPoint=ready",
		string.format("tier=%d,radius=%.2f,point=(%.1f,%.1f)",
			searchTier, searchRadius, kingPoint.x, kingPoint.z))
	ctx.doer.Physics:Teleport(kingPoint.x, 0, kingPoint.z)
	local trader = king.components.trader
	local able, ableReason = false, "missing_trader"
	local wants = false
	if trader ~= nil then
		able, ableReason = trader:AbleToAccept(ticket, ctx.doer, 1)
		wants = trader:WantsToAccept(ticket, ctx.doer, 1)
	end
	local kingPosition = king:GetPosition()
	local playerPosition = ctx.doer:GetPosition()
	local dx, dz = playerPosition.x - kingPosition.x, playerPosition.z - kingPosition.z
	local grandOwner = ticket.components.inventoryitem ~= nil
		and ticket.components.inventoryitem:GetGrandOwner() or nil
	local stateName = king.sg ~= nil and king.sg.currentstate ~= nil
		and king.sg.currentstate.name or nil
	Debug(ctx, "stage=king_trade", "preflight=complete",
		"traderEnabled=" .. tostring(trader ~= nil and trader.enabled == true),
		"able=" .. tostring(able), "ableReason=" .. tostring(ableReason),
		"wants=" .. tostring(wants), "state=" .. tostring(stateName),
		"busy=" .. tostring(king.sg ~= nil and king.sg:HasStateTag("busy")),
		"sleeping=" .. tostring(king.sg ~= nil and king.sg:HasStateTag("sleeping")),
		"owner=" .. tostring(grandOwner ~= nil and grandOwner.prefab or nil),
		string.format("distance=%.2f", math.sqrt(dx * dx + dz * dz)))
	if not able or not wants or grandOwner ~= ctx.doer then
		FailStep(ctx, "king_trade", string.format(
			"猪王交易前置不满足：enabled=%s,able=%s,reason=%s,wants=%s,state=%s,owner=%s,distance=%.2f",
			tostring(trader ~= nil and trader.enabled == true), tostring(able),
			tostring(ableReason), tostring(wants), tostring(stateName),
			tostring(grandOwner ~= nil and grandOwner.prefab or nil), math.sqrt(dx * dx + dz * dz)))
		return
	end
	RunAction(ctx, "GIVE_TICKET_TO_PIGKING",
		BufferedAction(ctx.doer, king, ACTIONS.GIVE, ticket), function(success, detail)
			if not success then FailStep(ctx, "king_trade", "猪王收券动作失败：" .. tostring(detail)) return end
			local function WaitForRun(attempt)
				local run = ctx.doer._aip_train_run
				if run ~= nil and run.boarded == true then
					if run.paid ~= true then FailStep(ctx, "king_trade", "列车不是付券启动") return end
					PassStep(ctx, "king_trade", "action=GIVE,paid=true,boarded=true,run=" .. tostring(run.id))
					hooks.rideReady(run)
				elseif run ~= nil and run.ended == true then
					FailStep(ctx, "king_trade", "猪王收券后列车在上车前结束：" .. tostring(run.endReason))
				elseif attempt >= FIND_ATTEMPTS then
					FailStep(ctx, "king_trade", string.format(
						"猪王收券后没有完成上车：run=%s,boarded=%s",
						tostring(run ~= nil and run.id or nil), tostring(run ~= nil and run.boarded == true)))
				else
					hooks.later(FIND_INTERVAL, function() WaitForRun(attempt + 1) end)
				end
			end
			WaitForRun(1)
		end)
end

return E2E
