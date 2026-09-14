if aipGetModConfig("dev_mode") ~= "enabled" then return {} end

local vitals = require("aip_pig_king_train_vitals")
local Passenger = require("components/aipc_pig_king_train_passenger")
local Runtime = require("aip_pig_king_train_runtime")
local PigVillageQuest = require("components/aipc_pig_village_quest")
local QuestManager = require("components/aipc_pig_village_quest_manager")
local questConfig = require("configurations/aip_pig_village_quest")
local villageTicket = require("aip_pig_village_ticket")
local Scenarios = {}

-- 数值替身只作用于隔离测试，使用与原版一致的 setter 调用链。
local function MakeVitals()
	local inst = { components = {}, HasTag = function() return false end }
	local health = { currenthealth = 20 }
	-- 查询隔离对象是否实际死亡。
	function health:IsDead() return self.currenthealth <= 0 end
	-- 模拟生命直接赋值。
	function health:SetCurrentHealth(value) self.currenthealth = value end
	-- 模拟生命归零的最终入口。
	function health:SetVal(value) self.currenthealth = math.max(0, value) end
	-- 生命增减委托给最终赋值入口。
	function health:DoDelta(delta) self:SetVal(self.currenthealth + delta) end
	-- 生命百分比委托给最终赋值入口。
	function health:SetPercent(percent) self:SetVal(percent * 100) end
	-- 显式死亡沿用生命扣减链路。
	function health:Kill() self:DoDelta(-self.currenthealth) end
	health.ForceKill = health.Kill
	local hunger = { current = 20 }
	-- 模拟饥饿值最终赋值。
	function hunger:SetCurrent(value) self.current = math.max(0, value) end
	-- 饥饿增减委托给最终赋值入口。
	function hunger:DoDelta(delta) self:SetCurrent(self.current + delta) end
	-- 饥饿百分比委托给最终赋值入口。
	function hunger:SetPercent(percent) self:SetCurrent(percent * 100) end
	local sanity = { current = 20 }
	-- 模拟精神值增减。
	function sanity:DoDelta(delta) self.current = math.max(0, self.current + delta) end
	-- 精神百分比转换为增量。
	function sanity:SetPercent(percent) self:DoDelta(percent * 100 - self.current) end
	inst.components.health, inst.components.hunger, inst.components.sanity = health, hunger, sanity
	return inst
end

-- 生命、饥饿、精神可下降和恢复，归零及百分比 setter 都必须保留 1 点。
function Scenarios.VitalFloor()
	local inst = MakeVitals()
	local lock = vitals.Lock(inst)
	local ok, err = pcall(function()
		for _, name in ipairs({ "health", "hunger", "sanity" }) do
			local component = inst.components[name]
			local field = name == "health" and "currenthealth" or "current"
			component:DoDelta(-5)
			assert(component[field] == 15, name .. " 无法正常下降")
			component:SetPercent(0)
			assert(component[field] == 1, name .. " 百分比设置可归零")
			component:DoDelta(9)
			assert(component[field] == 10, name .. " 无法正常恢复")
			component:DoDelta(-1000)
			assert(component[field] == 1, name .. " 极端扣减可归零")
		end
	end)
	vitals.Release(lock)
	assert(ok, err)
	inst.components.hunger:SetPercent(0)
	assert(inst.components.hunger.current == 0, "结束后保底未解除")
end

-- 显式死亡仍允许执行，不能让三维保护拦截管理员强制死亡或主动删除。
function Scenarios.ForcedDeath()
	local inst = MakeVitals()
	local lock = vitals.Lock(inst)
	local ok, err = pcall(function()
		inst.components.health:ForceKill()
		assert(inst.components.health:IsDead(), "显式死亡被保护错误拦截")
		vitals.Maintain(lock)
		assert(inst.components.health:IsDead(), "死亡后错误恢复生命")
	end)
	vitals.Release(lock)
	assert(ok, err)
end

-- 模拟组件、状态图已被移除的乘客，验证退出时不访问不存在的驾驶器或状态图。
function Scenarios.RemovedPassenger()
	local ended = 0
	local actor = {
		components = {}, IsValid = function() return false end,
		HasTag = function() return false end, RemoveTag = function() end,
		StopUpdatingComponent = function() end,
	}
	local passenger = setmetatable({ inst = actor, active = { set = function() end },
		run = { onFinish = function() ended = ended + 1 end } }, { __index = Passenger })
	passenger:Finish("passenger_removed")
	passenger:Finish("death")
	assert(ended == 1 and passenger.run == nil, "退出发生重复回调")
end

-- 独立模拟死亡、掉线和换分片后的运行清理，不向实际玩家发送破坏性事件。
function Scenarios.RuntimeCleanup()
	for _, reason in ipairs({ "death", "disconnect", "migration", "station_removed" }) do
		local removed, notifications = 0, 0
		local actor = { components = {}, IsValid = function() return false end }
		local king = { RemoveEventCallback = function() end,
			PushEvent = function() notifications = notifications + 1 end }
		local owned = { _aip_train_run_id = "dev_fixture", IsValid = function() return true end,
			Remove = function() removed = removed + 1 end }
		local other = { _aip_train_run_id = "another_run", IsValid = function() return true end,
			Remove = function() error("清理了其他线路") end }
		local manager = { inst = king, runs = {} }
		local run = { id = "dev_fixture", doer = actor, events = {}, entities = { owned, other }, points = {}, boarded = true }
		Runtime.EndRun(manager, run, reason)
		Runtime.EndRun(manager, run, reason)
		assert(removed == 1 and notifications == 1 and run.ended, reason .. " 清理不完整或重复")
	end
end

-- 创建不会进入真实世界的猪窝任务替身。
local function MakeQuestHouse(activePrefab, burnt)
	local quest = { active = activePrefab ~= nil, taskPrefab = activePrefab }
	-- 返回替身当前是否已有活动任务。
	function quest:IsActive() return self.active end
	-- 记录管理器分配给替身的新任务。
	function quest:StartQuest(prefab, count)
		assert(not self.active, "向已有任务的猪窝重复分配")
		self.active, self.taskPrefab, self.requiredCount = true, prefab, count
		return true
	end
	local house = {
		prefab = "pighouse",
		tags = { burnt = burnt == true },
		components = { spawner = {}, aipc_pig_village_quest = quest },
	}
	-- 管理器只需要查询实体有效性和燃烧标签。
	function house:IsValid() return true end
	function house:HasTag(tag) return self.tags[tag] == true end
	return house, quest
end

-- 验证首次补足三项、同日不补位、次日补位和任务类型去重。
function Scenarios.PigVillageDailyFill()
	local oldRandomEnt, oldTableRemove, oldPickTask = aipRandomEnt, aipTableRemove, questConfig.PickTask
	local oldWorldState = TheWorld.state
	if TheWorld.state == nil then TheWorld.state = { cycles = 0 } end
	local ok, err = pcall(function()
		local houses, quests = {}, {}
		for index, data in ipairs({ { "seeds", false }, { nil, false }, { nil, false },
			{ nil, false }, { nil, true } }) do
			houses[index], quests[index] = MakeQuestHouse(data[1], data[2])
		end
		local taskOrder = { "cutgrass", "twigs", "log", "rocks" }
		aipRandomEnt = function(list) return list[1] end
		aipTableRemove = function(list, value)
			for index, entry in ipairs(list) do
				if entry == value then table.remove(list, index) return end
			end
		end
		questConfig.PickTask = function(excluded)
			for _, prefab in ipairs(taskOrder) do
				if not excluded[prefab] then return { prefab = prefab, count = 2 } end
			end
		end
		local manager = setmetatable({ inst = {}, lastRefreshDay = nil, refreshTask = nil },
			{ __index = QuestManager })
		manager.FindVillageHouses = function() return houses end
		manager:FillTasks()
		local activeCount, activePrefabs = 0, {}
		for _, quest in ipairs(quests) do
			if quest:IsActive() then
				activeCount = activeCount + 1
				assert(not activePrefabs[quest.taskPrefab], "同日任务类型重复")
				activePrefabs[quest.taskPrefab] = true
			end
		end
		assert(activeCount == questConfig.MAX_ACTIVE_TASKS, "首次没有补足三个任务")
		assert(not quests[5]:IsActive(), "燃烧猪窝错误获得任务")
		quests[2].active = false
		manager:FillTasks()
		assert(not quests[2]:IsActive(), "当天完成后立即补位")
		manager.lastRefreshDay = (TheWorld.state.cycles or 0) - 1
		manager:FillTasks()
		activeCount = 0
		for _, quest in ipairs(quests) do if quest:IsActive() then activeCount = activeCount + 1 end end
		assert(activeCount == questConfig.MAX_ACTIVE_TASKS, "次日没有补足三个任务")
	end)
	aipRandomEnt, aipTableRemove, questConfig.PickTask = oldRandomEnt, oldTableRemove, oldPickTask
	TheWorld.state = oldWorldState
	assert(ok, err)
end

-- 验证猪人任务接管、部分交付、超量返还、奖励礼物和原逻辑恢复。
function Scenarios.PigVillageDelivery()
	local oldSpawn, oldFling, oldPickReward = aipSpawnPrefab, aipFlingItem, questConfig.PickReward
	local oldGrassName = STRINGS.NAMES.CUTGRASS
	local ok, err = pcall(function()
		STRINGS.NAMES.CUTGRASS = "草"
		local originalRefused = 0
		local originalTest = function() return false end
		local originalAccept = function() end
		local originalRefuse = function() originalRefused = originalRefused + 1 end
		local trader = {
			test = originalTest,
			onaccept = originalAccept,
			onrefuse = originalRefuse,
			acceptstacks = false,
			deleteitemonaccept = false,
			acceptnontradable = false,
		}
		-- 保存任务覆盖后的交易回调。
		function trader:SetAcceptStacks() self.acceptstacks = true end
		function trader:SetAcceptTest(fn) self.test = fn end
		function trader:SetOnAccept(fn) self.onaccept = fn end
		function trader:SetOnRefuse(fn) self.onrefuse = fn end
		local messages = {}
		local pig = { components = {
			trader = trader,
			inspectable = { descriptionfn = function() return "原版检查" end },
			talker = { Say = function(_, text) table.insert(messages, text) end },
		} }
		-- 猪人替身在整个同步场景中保持有效。
		function pig:IsValid() return true end
		local eventData = nil
		local house = { components = {} }
		-- 记录任务完成事件，不向真实世界广播。
		function house:PushEvent(name, data)
			if name == "aip_pig_village_quest_completed" then eventData = data end
		end
		local quest = setmetatable({ inst = house, taskPrefab = nil, requiredCount = 0,
			deliveredCount = 0, isCompleting = false, resident = nil, marker = nil,
			markerTarget = nil, runtimeTask = nil }, { __index = PigVillageQuest })
		quest.StartRuntime = function(self) self.runtimeStarted = true end
		quest.SyncRuntime = function() end
		assert(quest:StartQuest("cutgrass", 3), "任务无法开始")
		quest:AttachResident(pig)
		assert(trader.acceptstacks and trader.deleteitemonaccept and trader.acceptnontradable,
			"猪人没有接管整组或非 tradable 物资")
		assert(trader.test(pig, { prefab = "cutgrass" })
			and not trader.test(pig, { prefab = "rocks" }), "任务物资过滤错误")
		trader.onrefuse(pig, {}, { prefab = "rocks" })
		assert(originalRefused == 1 and #messages == 1, "拒绝物品没有保留原回调或任务提示")
		assert(pig.components.inspectable.descriptionfn(pig, {}) == false and #messages == 2,
			"检查任务猪人时没有由猪人说明需求")
		quest:AcceptDelivery(pig, {}, 2)
		assert(quest.deliveredCount == 2 and quest:GetRemainingCount() == 1,
			"部分交付进度错误")

		local wrapped, flung = nil, nil
		-- 生成只记录礼物内容的奖励替身。
		aipSpawnPrefab = function(_, prefab)
			local item = { prefab = prefab, valid = true, components = {} }
			function item:IsValid() return self.valid end
			function item:Remove() self.valid = false end
			if prefab == "gift" then
				item.components.unwrappable = { WrapItems = function(_, items)
					wrapped = {}
					for _, content in ipairs(items) do
						table.insert(wrapped, { prefab = content.prefab, count = content.stackSize or 1 })
					end
				end }
			else
				item.components.stackable = { SetStackSize = function(_, count) item.stackSize = count end }
			end
			return item
		end
		aipFlingItem = function(item) flung = item end
		questConfig.PickReward = function() return { prefab = "goldnugget", count = 1 } end
		local giver = {}
		quest:AcceptDelivery(pig, giver, 2)
		assert(not quest:IsActive() and eventData ~= nil and eventData.player == giver,
			"任务完成状态或事件错误")
		assert(flung ~= nil and flung.prefab == "gift" and wrapped ~= nil and #wrapped == 3,
			"奖励没有封入单个礼物")
		local contents = {}
		for _, content in ipairs(wrapped) do contents[content.prefab] = content.count end
		assert(contents.goldnugget == 1 and contents.aip_train_ticket_fragment == 1
			and contents.cutgrass == 1, "奖励、碎片或超量物资错误")
		assert(trader.test == originalTest and trader.onaccept == originalAccept
			and trader.onrefuse == originalRefuse and not trader.acceptstacks
			and not trader.deleteitemonaccept and not trader.acceptnontradable,
			"完成后没有恢复原版交易逻辑")
		assert(pig.components.inspectable.descriptionfn(pig, {}) == "原版检查",
			"完成后没有恢复原版检查文本")
	end)
	aipSpawnPrefab, aipFlingItem, questConfig.PickReward = oldSpawn, oldFling, oldPickReward
	STRINGS.NAMES.CUTGRASS = oldGrassName
	assert(ok, err)
end

-- 验证多个同帧回调只安排一次检查，并按三张一组批量合成。
function Scenarios.TrainTicketFragmentMerge()
	local oldSpawn = aipSpawnPrefab
	local ok, err = pcall(function()
		local fragments, consumed, tickets, scheduled, spoken = 7, 0, 0, {}, 0
		local inventory = {}
		-- 返回当前碎片数量。
		function inventory:Has() return fragments > 0, fragments end
		-- 记录本次合成实际消耗的碎片。
		function inventory:ConsumeByName(_, count) fragments, consumed = fragments - count, consumed + count end
		-- 记录生成的正式体验券。
		function inventory:GiveItem(item)
			assert(item.prefab == "aip_train_ticket", "合成生成了错误物品")
			tickets = tickets + 1
		end
		local owner = { components = {
			inventory = inventory,
			talker = { Say = function() spoken = spoken + 1 end },
		} }
		-- 合成替身始终是有效玩家。
		function owner:IsValid() return true end
		function owner:HasTag(tag) return tag == "player" end
		function owner:GetPosition() return { x = 0, y = 0, z = 0 } end
		function owner:DoTaskInTime(_, fn)
			local task = { fn = fn }
			table.insert(scheduled, task)
			return task
		end
		aipSpawnPrefab = function(_, prefab) return { prefab = prefab } end
		assert(villageTicket.ScheduleMerge(owner), "首次合成检查未安排")
		assert(not villageTicket.ScheduleMerge(owner) and #scheduled == 1,
			"同一帧重复安排合成检查")
		scheduled[1].fn(owner)
		assert(owner._aipTrainTicketMergeTask == nil and consumed == 6 and fragments == 1
			and tickets == 2 and spoken == 1, "七张碎片没有合成两张体验券并保留一张")
		assert(villageTicket.MergeFragments(owner) == 0 and consumed == 6 and tickets == 2,
			"不足三张时仍然发生合成")
	end)
	aipSpawnPrefab = oldSpawn
	assert(ok, err)
end

-- 生成两种真实券 prefab，核对图标、动画、堆叠、交易与入包合成入口。
function Scenarios.TrainTicketPrefabs()
	local created = {}
	local ok, err = pcall(function()
		local ticket = assert(SpawnPrefab("aip_train_ticket"), "正式体验券 prefab 不存在")
		local fragment = assert(SpawnPrefab("aip_train_ticket_fragment"), "体验券碎片 prefab 不存在")
		table.insert(created, ticket)
		table.insert(created, fragment)
		assert(ticket:IsValid() and ticket.components.stackable ~= nil
			and ticket.components.tradable ~= nil, "正式体验券不能堆叠或交给猪王")
		assert(ticket.components.inventoryitem ~= nil
			and ticket.components.inventoryitem.imagename == "aip_train_ticket"
			and ticket.components.inventoryitem.atlasname == "images/inventoryimages/aip_train_ticket.xml",
			"正式体验券物品栏图标配置错误")
		assert(ticket.AnimState:IsCurrentAnimation("idle"), "正式体验券没有播放 idle 动画")
		assert(fragment:IsValid() and fragment.components.stackable ~= nil
			and fragment.components.inventoryitem ~= nil, "体验券碎片不能堆叠或放入物品栏")
		assert(fragment.components.inventoryitem.imagename == "aip_train_ticket_fragment"
			and fragment.components.inventoryitem.atlasname
				== "images/inventoryimages/aip_train_ticket_fragment.xml",
			"体验券碎片物品栏图标配置错误")
		assert(type(fragment.components.inventoryitem.onputininventoryfn) == "function",
			"体验券碎片缺少入包合成入口")
		local scheduled = 0
		local owner = { components = { inventory = {} } }
		function owner:HasTag(tag) return tag == "player" end
		function owner:DoTaskInTime()
			scheduled = scheduled + 1
			return { Cancel = function() end }
		end
		fragment.components.inventoryitem.GetGrandOwner = function() return owner end
		fragment:PushEvent("stacksizechange", { oldstacksize = 1, stacksize = 2 })
		assert(scheduled == 1 and owner._aipTrainTicketMergeTask ~= nil,
			"体验券碎片并入已有堆叠后没有重新安排合成")
		fragment:PushEvent("stacksizechange", { oldstacksize = 2, stacksize = 1 })
		assert(scheduled == 1, "消耗体验券碎片时不应重复安排合成")
		owner._aipTrainTicketMergeTask:Cancel()
		owner._aipTrainTicketMergeTask = nil
		assert(fragment.AnimState:IsCurrentAnimation("idle"), "体验券碎片没有播放 idle 动画")
	end)
	for _, item in ipairs(created) do if item:IsValid() then item:Remove() end end
	assert(ok, err)
end

-- 使用真实 trader 组件验证正式券被消耗并按付费流程启动，同时保留原版交易边界与返券语义。
function Scenarios.PaidTicketTrade()
	local king = CreateEntity()
	king.entity:AddTransform()
	king.persists = false
	king:AddComponent("trader")
	local trader = king.components.trader
	local accepted, started, paid = 0, 0, nil
	trader:SetAcceptTest(function(_, item) return item.prefab == "meat" end)
	trader:SetOnAccept(function() accepted = accepted + 1 end)
	local manager = Runtime(king)
	manager.StartTrain = function(_, _, wasPaid)
		started, paid = started + 1, wasPaid
		return true
	end
	-- 创建会走原版 Trader:AcceptGift 删除链路、但不进入真实物品栏的隔离物品。
	local function MakeTradeItem(prefab)
		local item = { prefab = prefab, removedFromOwner = 0, removed = 0, components = {} }
		item.components.inventoryitem = {
			RemoveFromOwner = function() item.removedFromOwner = item.removedFromOwner + 1 end,
		}
		item.components.stackable = { stacksize = 1 }
		function item:Remove() self.removed = self.removed + 1 end
		return item
	end
	local ok, err = pcall(function()
		local giver = { GetPosition = function() return Vector3(0, 0, 0) end }
		local ticket = MakeTradeItem("aip_train_ticket")
		assert(trader:AcceptGift(giver, ticket, 1), "正式体验券没有被猪王接受")
		assert(ticket.removedFromOwner == 1 and ticket.removed == 1,
			"正式体验券交易后没有恰好扣除一次")
		assert(started == 1 and paid == true, "正式体验券没有按付费流程启动列车")
		local meat = MakeTradeItem("meat")
		assert(trader:AcceptGift(giver, meat, 1) and accepted == 1 and started == 1,
			"普通猪王交易没有保留原逻辑")
		local twigs = MakeTradeItem("twigs")
		assert(not trader:AcceptGift(giver, twigs, 1) and twigs.removed == 0,
			"列车包装错误扩大了猪王收礼范围")

		local oldSpawn = SpawnPrefab
		local refunds = 0
		local refundOK, refundError = pcall(function()
			SpawnPrefab = function(prefab)
				assert(prefab == "aip_train_ticket", "失败返还了错误物品")
				local item = { Transform = { SetPosition = function() end } }
				function item:Remove() end
				return item
			end
			local actor = {
				components = {
					inventory = { GiveItem = function() refunds = refunds + 1 end },
					talker = { Say = function() end },
				},
				IsValid = function() return true end,
			}
			manager:Fail(actor, { code = "test_paid_failure" }, true)
			assert(refunds == 1, "付费启动失败没有恰好返还一张正式券")
			manager:Fail(actor, { code = "test_free_failure" }, false)
			assert(refunds == 1, "免费测试失败时凭空返还了正式券")
		end)
		SpawnPrefab = oldSpawn
		assert(refundOK, refundError)
	end)
	if king:IsValid() then king:Remove() end
	assert(ok, err)
end

-- 强制第一轮地面占比失败，确认运行时只做有限重试、替换故障景点并最终清理测试运行。
function Scenarios.RoutePlanningRetry(doer)
	local king = CreateEntity()
	king.entity:AddTransform()
	king.persists = false
	local routeCalls, planCalls, secondOptions = 0, 0, nil
	local priorities = { "P0", "P1", "P2" }
	local stops = {}
	for index = 1, 6 do
		local id = index == 1 and "bad_spot" or "kept_spot_" .. tostring(index)
		table.insert(stops, { id = id, name = id, prefab = id,
			priority = priorities[math.floor((index - 1) / 2) + 1], point = Vector3(index * 10, 0, 0) })
	end
	local routeMap = {
		start = { point = Vector3(0, 0, 0) }, stops = stops, legs = {}, totalDistance = 60,
		spotCount = 6, optimizePasses = 0,
		selectionStats = {
			P0 = { attempts = 2, attemptLimit = 12, selectedCount = 2 },
			P1 = { attempts = 2, attemptLimit = 12, selectedCount = 2 },
			P2 = { attempts = 2, attemptLimit = 12, selectedCount = 2 },
		},
	}
	local routeStub = { Create = function(_, options)
		routeCalls = routeCalls + 1
		if routeCalls == 2 then secondOptions = options end
		return routeMap
	end }
	local plan = {
		station = Vector3(0, 0, 0), points = { Vector3(0, 0, 0), Vector3(1, 0, 0) },
		stops = {}, views = {}, arcs = {}, scenicSegments = {}, totalDistance = 1,
		oceanDistance = 0, groundDistance = 1, elevatedDistance = 0,
		heightTransitions = 0, visualCount = 1,
	}
	local trackStub = { Plan = function()
		planCalls = planCalls + 1
		if planCalls == 1 then
			return nil, { code = "insufficient_ground_ratio", spot = "bad_spot",
				detail = "forced retry" }
		end
		return plan
	end }
	local manager = Runtime(king, { route = routeStub, track = trackStub })
	local ok, err = pcall(function()
		local started, result = manager:StartTrain(doer, false)
		assert(started and result == routeMap and routeCalls == 2 and planCalls == 2,
			"可重试的规划错误没有在有限轮次内恢复")
		assert(secondOptions ~= nil and secondOptions.excludedSpotIds.bad_spot == true,
			"第二轮没有排除故障景点")
		for _, stop in ipairs(stops) do
			if stop.id ~= "bad_spot" then
				assert(secondOptions.preferredSpotIds[stop.id] == true, "第二轮没有保留有效景点")
			end
		end
		manager:EndRun(doer._aip_train_run, "complete")
		assert(doer._aip_train_run == nil, "规划重试隔离运行没有清理")
	end)
	if doer._aip_train_run ~= nil then manager:EndRun(doer._aip_train_run, "test_cleanup") end
	if king:IsValid() then king:Remove() end
	assert(ok, err)
end

return Scenarios
