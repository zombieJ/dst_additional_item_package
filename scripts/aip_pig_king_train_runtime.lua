local trainRoute = require("aip_pig_king_train_route")
local track = require("aip_pig_king_train_track")
local config = require("configurations/aip_pig_king_train")
local devMode = aipGetModConfig("dev_mode") == "enabled"
local nextRunId = 0
local activeRuns = {}
local LOG_PREFIX = "[PigKingTrain][Runtime]"
local RETRYABLE_PLAN_ERRORS = {
	no_viewpoint = true,
	no_safe_path = true,
	rough_route_too_long = true,
	track_budget_exceeded = true,
}

-- 开发模式统一使用 AIP 日志输出运行生命周期信息。
local function Debug(...)
	if devMode then aipPrint(LOG_PREFIX, ...) end
end

-- 将运行坐标压缩成适合单行日志的文本。
local function FormatPoint(point)
	if point == nil then return "nil" end
	return string.format("(%.1f,%.1f,%.1f)", point.x, point.y or 0, point.z)
end

-- 生成不会展开整个玩家实体的日志标识。
local function PlayerLabel(doer)
	if doer == nil then return "nil" end
	return tostring(doer.userid or doer.name or doer.prefab or doer.GUID)
end

-- 将一组景点 ID 排序后压缩成单行日志。
local function ExcludedText(excludedSpotIds)
	local ids = {}
	for id in pairs(excludedSpotIds) do table.insert(ids, id) end
	table.sort(ids)
	return #ids > 0 and table.concat(ids, ",") or "none"
end

-- 记录本轮未被排除的景点，下一轮只替换一个故障候选。
local function RetainRouteSpots(routeMap, excludedSpotIds)
	local retained = {}
	for _, stop in ipairs(routeMap.stops) do
		if not excludedSpotIds[stop.id] then retained[stop.id] = true end
	end
	return retained
end

-- 为规划重试选择要换掉的景点，寻路失败优先换故障点，超预算优先换最远点。
local function FindRetrySpot(routeMap, routeError, excludedSpotIds)
	if routeError ~= nil and (routeError.code == "no_viewpoint" or routeError.code == "no_safe_path")
		and routeError.spot ~= nil then
		for _, stop in ipairs(routeMap.stops) do
			if stop.id == routeError.spot and not excludedSpotIds[stop.id] then return stop end
		end
	end
	local farthest, farthestDistanceSq
	for _, stop in ipairs(routeMap.stops) do
		if not excludedSpotIds[stop.id] then
			local dx = stop.point.x - routeMap.start.point.x
			local dz = stop.point.z - routeMap.start.point.z
			local distanceSq = dx * dx + dz * dz
			if farthestDistanceSq == nil or distanceSq > farthestDistanceSq then
				farthest, farthestDistanceSq = stop, distanceSq
			end
		end
	end
	return farthest
end

-- 向仍在本分片的乘客发送列车提示。
local function Say(doer, message)
	if doer ~= nil and doer:IsValid() and doer.components.talker ~= nil then
		doer.components.talker:Say(message)
	end
end

-- 只为真实消费的体验券返还一次，背包放不下时由物品栏组件放到总站。
local function Refund(doer, point)
	local ticket = SpawnPrefab("aip_train_ticket")
	if ticket == nil then return false end
	ticket.Transform:SetPosition(point.x, 0, point.z)
	if doer ~= nil and doer:IsValid() and doer.components.inventory ~= nil then
		doer.components.inventory:GiveItem(ticket, nil, Vector3(point.x, 0, point.z))
	end
	return true
end

-- 检查玩家是否可开始观光，拒绝幽灵、骑乘和已在驾驶的玩家。
local function CanStart(doer)
	if doer == nil or not doer:IsValid() or doer:IsInLimbo() or doer:HasTag("playerghost")
		or doer._aip_train_run ~= nil or doer._despawning then return false end
	local driver = doer.components.aipc_orbit_driver
	local rider = doer.components.rider
	local flyer = doer.components.aipc_flyer_sc
	return driver ~= nil and not driver:IsInvalidDriver() and not driver:isDriving()
		and (rider == nil or not rider:IsRiding()) and (flyer == nil or not flyer:IsFlying())
end

local PigKingTrain = Class(function(self, inst)
	self.inst = inst
	self.routeMap = nil
	self.lastRouteError = nil
	self.runs = {}

	-- 只截获正式体验券，其他物品继续走猪王原有的判定和收礼行为。
	local trader = inst.components.trader
	if trader ~= nil then
		local originalTest, originalAccept = trader.test, trader.onaccept
		trader:SetAcceptTest(function(king, item, giver, ...)
			if item.prefab == "aip_train_ticket" then return true end
			return originalTest == nil or originalTest(king, item, giver, ...)
		end)
		trader.onaccept = function(king, giver, item, ...)
			if item.prefab ~= "aip_train_ticket" and originalAccept ~= nil then
				return originalAccept(king, giver, item, ...)
			end
		end
	end

	-- 交易时物品已由原版移除；下一帧才上车，避免交付动作的收尾状态打断。
	self.inst:ListenForEvent("trade", function(_, data)
		if data ~= nil and data.giver ~= nil and data.item ~= nil and data.item.prefab == "aip_train_ticket" then
			self:StartTrain(data.giver, true)
		end
	end)
end)

-- 统一记录准备失败并返券，调试调用未付券时不会凭空获得物品。
function PigKingTrain:Fail(doer, routeError, paid)
	self.lastRouteError = routeError
	local refunded = paid and Refund(doer, self.inst:GetPosition()) or false
	Say(doer, paid and config.LANG.FAILED or config.LANG.BUSY)
	self.inst:PushEvent("aip_pig_king_train_route_failed", { doer = doer, error = routeError })
	Debug("failed", "player=" .. PlayerLabel(doer),
		"code=" .. tostring(routeError ~= nil and routeError.code),
		"priority=" .. tostring(routeError ~= nil and routeError.priority),
		"spot=" .. tostring(routeError ~= nil and routeError.spot),
		"detail=" .. tostring(routeError ~= nil and routeError.detail),
		"paid=" .. tostring(paid == true), "refunded=" .. tostring(refunded))
	return false, routeError
end

-- 开发模式输出六站配额、访问顺序、粗路线距离和实际铺轨预算。
function PigKingTrain:LogRoute(run)
	if not devMode then return end
	Debug("route-summary", "run=" .. run.id, "player=" .. PlayerLabel(run.doer),
		"origin=" .. FormatPoint(run.origin), "station=" .. FormatPoint(run.plan.station))
	for _, priority in ipairs(trainRoute.PRIORITIES) do
		local stats = run.routeMap.selectionStats[priority]
		Debug("quota", "run=" .. run.id, "priority=" .. priority,
			string.format("attempts=%d/%d", stats.attempts, stats.attemptLimit),
			"selected=" .. stats.selectedCount)
	end
	for i, stop in ipairs(run.routeMap.stops) do
		Debug("route-stop", "run=" .. run.id, "index=" .. i,
			"id=" .. stop.id, "name=" .. stop.name, "priority=" .. stop.priority,
			"prefab=" .. tostring(stop.prefab),
			"guid=" .. tostring(stop.anchor ~= nil and stop.anchor.GUID),
			"point=" .. FormatPoint(stop.point))
	end
	for i, leg in ipairs(run.routeMap.legs) do
		Debug("rough-leg", "run=" .. run.id, "index=" .. i,
			"from=" .. leg.from.id, "to=" .. leg.to.id,
			string.format("distance=%.1f", leg.distance))
	end
	for i, view in ipairs(run.plan.views or {}) do
		Debug("planned-view", "run=" .. run.id, "index=" .. i,
			"stop=" .. tostring(view.stop ~= nil and view.stop.id),
			"point=" .. FormatPoint(view.point),
			"dangerous=" .. tostring(view.dangerous == true))
	end
	for i, arc in ipairs(run.plan.arcs or {}) do
		Debug("planned-arc", "run=" .. run.id, "index=" .. i,
			"stop=" .. tostring(arc.stop ~= nil and arc.stop.id),
			"entry=" .. FormatPoint(arc.entry), "exit=" .. FormatPoint(arc.exit),
			string.format("radius=%.1f sweep=%.0f", arc.radius, arc.sweepDegrees),
			"segments=" .. tostring(arc.segmentCount),
			"direction=" .. (arc.direction > 0 and "positive" or "negative"),
			"heightMode=" .. tostring(arc.heightMode),
			string.format("height=%.1f", arc.height or 0))
	end
	Debug("track-summary", "run=" .. run.id,
		string.format("roughDistance=%.1f", run.routeMap.totalDistance),
		string.format("plannedDistance=%.1f/%d", run.plan.totalDistance, config.MAX_DISTANCE),
		string.format("ocean=%.1f/%d", run.plan.oceanDistance, config.MAX_OCEAN_DISTANCE),
		string.format("ground=%.1f elevated=%.1f transitions=%d",
			run.plan.groundDistance or 0, run.plan.elevatedDistance or 0,
			run.plan.heightTransitions or 0),
		"points=" .. #run.plan.points .. "/" .. config.MAX_POINTS,
		"visuals=" .. run.plan.visualCount .. "/" .. config.MAX_VISUALS,
		"optimizePasses=" .. run.routeMap.optimizePasses)
end

-- 经过景点时播报名称并播放短暂特效，不生成可战斗、可拾取的演出实体。
function PigKingTrain:VisitStop(run, stop)
	if run.ended then return end
	local spot = stop.spot
	Debug("visit-stop", "run=" .. run.id, "id=" .. spot.id,
		"priority=" .. spot.priority, "pointIndex=" .. tostring(run.pointIndex),
		"player=" .. PlayerLabel(run.doer))
	local name = aipGetModConfig("language") == "chinese" and spot.name
		or STRINGS.NAMES[string.upper(spot.prefab)] or spot.id
	Say(run.doer, string.format(config.LANG.STOP, name))
	local fx = SpawnPrefab("spawn_fx_small")
	if fx ~= nil then
		fx.persists = false
		fx._aip_train_run_id = run.id
		fx.Transform:SetPosition(run.doer.Transform:GetWorldPosition())
		table.insert(run.entities, fx)
	end
	self.inst:PushEvent("aip_pig_king_train_stop", { doer = run.doer, runId = run.id, stop = spot })
end

-- 清除监听、任务和自有实体；所有退出入口最终汇聚于此，且允许重复调用。
function PigKingTrain:EndRun(run, reason)
	if run.ended then return end
	local passenger = run.doer.components.aipc_pig_king_train_passenger
	if passenger ~= nil and passenger.run == run then
		Debug("end-delegate", "run=" .. tostring(run.id), "reason=" .. tostring(reason),
			"player=" .. PlayerLabel(run.doer))
		passenger:Finish(reason)
		return
	end
	Debug("end-begin", "run=" .. tostring(run.id), "reason=" .. tostring(reason),
		"boarded=" .. tostring(run.boarded == true), "player=" .. PlayerLabel(run.doer),
		"entities=" .. tostring(#run.entities), "points=" .. tostring(#run.points),
		"errorCode=" .. tostring(run.error ~= nil and run.error.code),
		"errorDetail=" .. tostring(run.error ~= nil and run.error.detail))
	run.ended = true
	run.endReason = reason
	if run.task ~= nil then run.task:Cancel() end
	if run.timeout ~= nil then run.timeout:Cancel() end
	for _, event in ipairs(run.events) do self.inst:RemoveEventCallback(event, run.onAbort, run.doer) end
	self.inst:RemoveEventCallback("death", run.onDeath, run.doer)
	self.inst:RemoveEventCallback("ms_playerdespawn", run.onDespawn, TheWorld)
	self.inst:RemoveEventCallback("ms_playerdespawnandmigrate", run.onMigrate, TheWorld)
	self.runs[run.id], activeRuns[run.id] = nil, nil
	if run.doer._aip_train_run == run then run.doer._aip_train_run = nil end
	if run.boarded and run.doer:IsValid() then
		-- 回村前重新查找空地，避开乘车期间新建的建筑与火焰。
		local ok, safePoint = pcall(function()
			local context = track.CreateContext()
			return track.FindStation(context, run.origin, run.plan.station, true)
		end)
		local point = ok and safePoint or run.plan.station
		point = point or run.plan.station
		run.doer.Physics:Stop()
		run.doer.Physics:Teleport(point.x, 0, point.z)
	end
	track.Cleanup(run)
	if not run.boarded and run.paid then
		run.paid = false
		Debug("refund", "run=" .. tostring(run.id), "player=" .. PlayerLabel(run.doer),
			"success=" .. tostring(Refund(run.doer, run.origin)),
			"point=" .. FormatPoint(run.origin))
	end
	if reason ~= "complete" and not run.boarded then
		self.lastRouteError = run.error or { code = reason }
		Say(run.doer, config.LANG.FAILED)
		self.inst:PushEvent("aip_pig_king_train_route_failed", { doer = run.doer, error = self.lastRouteError })
	else
		Say(run.doer, reason == "complete" and config.LANG.FINISH or config.LANG.ABORT)
	end
	self.inst:PushEvent("aip_pig_king_train_finished", { doer = run.doer, runId = run.id, reason = reason })
	Debug("end-complete", "run=" .. tostring(run.id), "reason=" .. tostring(reason),
		"entities=" .. tostring(#run.entities), "points=" .. tostring(#run.points),
		"playerValid=" .. tostring(run.doer ~= nil and run.doer:IsValid()))
end

-- 只创建总站附近的初始轨道窗口，后续轨道由乘客经过端点时继续展示。
function PigKingTrain:BuildInitialTrack(run)
	if run.ended then return end
	local ok, result = pcall(function()
		local window = track.UpdateWindow(run, 1)
		Debug("build-initial", "run=" .. run.id,
			string.format("points=%d->%d", window.firstPoint, window.lastPoint),
			string.format("segments=%d->%d", window.firstSegment, window.lastSegment),
			"plannedPoints=" .. #run.plan.points, "entities=" .. #run.entities)
		if not run.doer:IsValid() or run.doer._despawning then error("passenger_unavailable") end
		run.car = track.SpawnCar(run)
		local passenger = run.doer.components.aipc_pig_king_train_passenger
		if passenger == nil or not passenger:Begin(run) then error("boarding_failed") end
		run.boarded = true
		Say(run.doer, config.LANG.START)
		Debug("boarded", "run=" .. run.id, "player=" .. PlayerLabel(run.doer),
			"carGuid=" .. tostring(run.car.GUID), "station=" .. FormatPoint(run.plan.station))
		return true
	end)
	if not ok then
		run.error = { code = "track_build_failed", detail = tostring(result) }
		self:EndRun(run, "track_build_failed")
	end
end

-- 用有限轮次生成六站闭环与安全折线，再创建独立运行记录。
function PigKingTrain:StartTrain(doer, paid)
	local count = 0
	for _ in pairs(activeRuns) do count = count + 1 end
	Debug("start-request", "player=" .. PlayerLabel(doer), "paid=" .. tostring(paid == true),
		"activeRuns=" .. count .. "/" .. config.MAX_ACTIVE_RUNS,
		"king=" .. FormatPoint(self.inst:GetPosition()))
	if not CanStart(doer) or count >= config.MAX_ACTIVE_RUNS then
		return self:Fail(doer, { code = "train_busy" }, paid)
	end
	if TheWorld:HasTag("cave") then return self:Fail(doer, { code = "unsupported_shard" }, paid) end
	local routeMap, plan, lastError
	local excludedSpotIds = {}
	local preferredSpotIds = {}
	local preferNearest = false
	for attempt = 1, config.MAX_PLAN_ATTEMPTS do
		Debug("plan-attempt", tostring(attempt) .. "/" .. tostring(config.MAX_PLAN_ATTEMPTS),
			"excluded=" .. ExcludedText(excludedSpotIds),
			"retained=" .. ExcludedText(preferredSpotIds),
			"fill=" .. (preferNearest and "nearest" or "random"))
		local routeOK, candidateRoute, routeError = pcall(trainRoute.Create, self.inst, {
			excludedSpotIds = excludedSpotIds,
			preferredSpotIds = preferredSpotIds,
			preferNearest = preferNearest,
		})
		if not routeOK then
			return self:Fail(doer, { code = "route_generation_failed", detail = tostring(candidateRoute) }, paid)
		end
		self.routeMap = candidateRoute
		if candidateRoute == nil then
			lastError = routeError or { code = "route_generation_failed" }
			Debug("plan-stop", "attempt=" .. tostring(attempt),
				"code=" .. tostring(lastError.code), "reason=route-unavailable")
			break
		end
		local planOK, candidatePlan, planError = pcall(track.Plan, candidateRoute, {
			reference = doer:GetPosition(),
		})
		if not planOK then
			return self:Fail(doer, { code = "track_plan_failed", detail = tostring(candidatePlan) }, paid)
		end
		if candidatePlan ~= nil then
			routeMap, plan = candidateRoute, candidatePlan
			lastError = nil
			Debug("plan-selected", "attempt=" .. tostring(attempt),
				string.format("roughDistance=%.1f", routeMap.totalDistance),
				string.format("plannedDistance=%.1f", plan.totalDistance))
			break
		end
		lastError = planError or { code = "track_plan_failed" }
		local retrySpot = FindRetrySpot(candidateRoute, lastError, excludedSpotIds)
		local canRetry = RETRYABLE_PLAN_ERRORS[lastError.code] == true
			and attempt < config.MAX_PLAN_ATTEMPTS and retrySpot ~= nil
		Debug("plan-rejected", "attempt=" .. tostring(attempt),
			"code=" .. tostring(lastError.code), "spot=" .. tostring(lastError.spot),
			"detail=" .. tostring(lastError.detail),
			"retry=" .. tostring(canRetry),
			"excludeNext=" .. tostring(retrySpot ~= nil and retrySpot.id))
		if not canRetry then break end
		excludedSpotIds[retrySpot.id] = true
		preferredSpotIds = RetainRouteSpots(candidateRoute, excludedSpotIds)
		preferNearest = lastError.code == "rough_route_too_long"
			or lastError.code == "track_budget_exceeded"
		Debug("plan-retry", "next=" .. tostring(attempt + 1),
			"excluded=" .. ExcludedText(excludedSpotIds),
			"retained=" .. ExcludedText(preferredSpotIds),
			"fill=" .. (preferNearest and "nearest" or "random"))
	end
	self.lastRouteError = lastError
	if routeMap == nil or plan == nil then
		return self:Fail(doer, lastError or { code = "track_plan_failed" }, paid)
	end
	nextRunId = nextRunId + 1
	local run = {
		id = tostring(self.inst.GUID) .. ":" .. tostring(nextRunId), doer = doer,
		origin = self.inst:GetPosition(), routeMap = routeMap, plan = plan,
		entities = {}, points = {}, links = {}, paid = paid == true, boarded = false,
		events = { "onremove", "player_despawn" },
	}
	self.runs[run.id], activeRuns[run.id], doer._aip_train_run = run, run, run
	-- 所有监听均绑定本次运行，取消时只移除自己的回调。
	run.onAbort = function() self:EndRun(run, "interrupted") end
	run.onDeath = function() self:EndRun(run, "death") end
	run.onDespawn = function(_, player) if player == doer then self:EndRun(run, "disconnect") end end
	run.onMigrate = function(_, data) if data ~= nil and data.player == doer then self:EndRun(run, "migration") end end
	run.onFinish = function(reason) self:EndRun(run, reason) end
	run.onStop = function(stop) self:VisitStop(run, stop) end
	run.onAdvance = function(index) return track.UpdateWindow(run, index) end
	for _, event in ipairs(run.events) do self.inst:ListenForEvent(event, run.onAbort, doer) end
	self.inst:ListenForEvent("death", run.onDeath, doer)
	self.inst:ListenForEvent("ms_playerdespawn", run.onDespawn, TheWorld)
	self.inst:ListenForEvent("ms_playerdespawnandmigrate", run.onMigrate, TheWorld)
	run.timeout = self.inst:DoTaskInTime(config.MAX_DURATION, function() self:EndRun(run, "timeout") end)
	run.task = self.inst:DoTaskInTime(0, function() self:BuildInitialTrack(run) end)
	self:LogRoute(run)
	Say(doer, config.LANG.PREPARING)
	self.inst:PushEvent("aip_pig_king_train_route_ready", { doer = doer, routeMap = routeMap, plan = plan, runId = run.id })
	Debug("start-ready", "run=" .. run.id, "player=" .. PlayerLabel(doer),
		"plannedPoints=" .. #plan.points, "plannedVisuals=" .. plan.visualCount,
		"lookahead=" .. config.TRACK_LOOKAHEAD, "retainBehind=" .. config.TRACK_RETAIN_BEHIND)
	return true, routeMap
end

-- 猪王移除或组件卸载时，逐个结束运行，避免遍历期间修改原表漏清理。
function PigKingTrain:OnRemoveFromEntity()
	local runs = {}
	for _, run in pairs(self.runs) do table.insert(runs, run) end
	for _, run in ipairs(runs) do self:EndRun(run, "station_removed") end
end

PigKingTrain.OnRemoveEntity = PigKingTrain.OnRemoveFromEntity

return PigKingTrain
