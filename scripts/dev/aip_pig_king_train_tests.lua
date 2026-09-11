if aipGetModConfig("dev_mode") ~= "enabled" then return {} end

local scenarios = require("dev/aip_pig_king_train_scenarios")
local config = require("configurations/aip_pig_king_train")
local Tests = {}
local active = nil
local generation = 0
local REPORT_BATCH = 3
local REPORT_DELAY = 0.15

-- 报告每条最多一行，避免错误堆栈或超长实体字符串撑满控制台。
local function Line(value)
	local text = tostring(value):gsub("[\r\n]+", " | ")
	if #text <= 1200 then return text end
	local last = 1200
	-- 截断报告时保留完整 UTF-8 字符，避免中文错误信息出现半个字节序列。
	while text:byte(last + 1) >= 128 and text:byte(last + 1) < 192 do last = last - 1 end
	return text:sub(1, last) .. "..."
end

-- 使用静态任务分批输出，全部写完后再触发可选的安全暂停回调。
function Tests.Output(report, userid, onComplete, isCurrent)
	local index = 1
	-- 每批只打印少量短行，同一批同步给测试发起者的客户端。
	local function NextBatch()
		if isCurrent ~= nil and not isCurrent() then return end
		local lines = {}
		for _ = 1, REPORT_BATCH do
			if report.lines[index] == nil then break end
			table.insert(lines, report.lines[index])
			index = index + 1
		end
		if #lines > 0 then
			local chunk = table.concat(lines, "\n")
			aipPrint("[PigKingTrain][TestReport]", chunk)
			if Tests.reporter ~= nil then pcall(Tests.reporter, userid, chunk) end
		end
		if report.lines[index] ~= nil then
			TheWorld:DoStaticTaskInTime(REPORT_DELAY, NextBatch)
		elseif onComplete ~= nil then
			onComplete()
		end
	end
	NextBatch()
end

-- 统一取消测试任务、事件与真实行程；重启时只清理，不输出旧报告或暂停。
local function Cleanup(session, endReason)
	if session.cleaned then return true end
	session.finished = true
	for _, task in ipairs(session.tasks) do task:Cancel() end
	local cleanupError = nil
	if session.run ~= nil and not session.run.ended then
		local ok, err = pcall(session.manager.EndRun, session.manager, session.run,
			endReason or "test_finished")
		if not ok then
			cleanupError = Line(err)
		end
	end
	for _, event in ipairs({ "death", "onremove", "player_despawn" }) do
		TheWorld:RemoveEventCallback(event, session.onInterrupted, session.doer)
	end
	if active == session then active = nil end
	session.cleaned = true
	return cleanupError == nil, cleanupError
end

-- 无论成功、断言失败或运行时异常，均先回收运行，完整输出报告后再安全暂停。
local function Finish(session, success, detail)
	if session.finished then return end
	local cleaned, cleanupError = Cleanup(session, "test_finished")
	if not cleaned then
		success = false
		table.insert(session.lines, "[FAIL] 测试运行清理：" .. cleanupError)
	end
	local report = { success = success, passed = session.passed, detail = detail, lines = {} }
	table.insert(report.lines, "[AIP TRAIN TEST] " .. (success and "成功" or "失败") .. "；通过 " .. session.passed .. " 项")
	for _, entry in ipairs(session.lines) do table.insert(report.lines, entry) end
	table.insert(report.lines, "[RESULT] " .. Line(detail))
	table.insert(report.lines, "[REPORT] 完整报告输出后将自动请求安全暂停；请回到 Codex 告知测试完成。")
	TheWorld._aipTrainLastTestReport = report
	local sessionGeneration = session.generation
	Tests.Output(report, session.userid, function()
		if generation ~= sessionGeneration then return end
		local ok, requested = false, false
		if Tests.pauser ~= nil then ok, requested = pcall(Tests.pauser, session.userid) end
		if not ok or requested == false then
			aipPrint("[PigKingTrain][TestReport]", "[FAIL] 自动暂停请求未发送；日志已经完整保存。")
		end
	end, function() return generation == sessionGeneration end)
end

-- 所有异步步骤都经过异常保护；不让断言或 nil 访问逃出任务回调。
local function Later(session, delay, fn)
	local task = TheWorld:DoStaticTaskInTime(delay, function()
		if session.finished then return end
		local ok, err = xpcall(fn, debug.traceback)
		if not ok then Finish(session, false, err) end
	end)
	table.insert(session.tasks, task)
end

-- 每个检查只记录一行结果，失败时保留具体断言信息。
local function Check(session, name, fn)
	local ok, err = xpcall(fn, debug.traceback)
	if not ok then
		table.insert(session.lines, "[FAIL] " .. name .. "：" .. Line(err))
		Finish(session, false, name .. "失败：" .. Line(err))
		return false
	end
	session.passed = session.passed + 1
	table.insert(session.lines, "[PASS] " .. name)
	return true
end

-- 接收当前发起客户端的第三视角合成鼠标探针，过期会话结果直接丢弃。
function Tests.CameraProbeResult(player, sessionGeneration, success, detail)
	local session = active
	if session == nil or session.finished or session.generation ~= tonumber(sessionGeneration)
		or player == nil or player ~= session.doer or session.cameraProbeFinished then return false end
	session.cameraProbeFinished = true
	local passed = success == true or success == "true"
	if not Check(session, "客户端第三视角鼠标直控", function()
		assert(passed, Line(detail))
	end) then return false end
	session.cameraProbePassed = true
	table.insert(session.lines, "[INFO] 第三视角镜头探针：" .. Line(detail))
	return true
end

-- 找到当前分片最近的猪王，测试不会补造真实原版景点。
local function FindKing(doer)
	local closest, distance
	local point = doer:GetPosition()
	for _, inst in pairs(Ents) do
		if inst.prefab == "pigking" and inst:IsValid() and inst.components.aipc_pig_king_train ~= nil then
			local dist = aipDist(point, inst:GetPosition())
			if distance == nil or dist < distance then closest, distance = inst, dist end
		end
	end
	return closest
end

-- 临时测试三维零值入口，并在同一次回调内恢复原数值，不给乘客永久补给。
local function ProbeVitals(doer)
	local snapshots = {}
	for _, name in ipairs({ "health", "hunger", "sanity" }) do
		local component = doer.components[name]
		if component ~= nil then snapshots[name] = name == "health" and component.currenthealth or component.current end
	end
	local ok, err = pcall(function()
		for name in pairs(snapshots) do
			local component = doer.components[name]
			component:SetPercent(0)
			local value = name == "health" and component.currenthealth or component.current
			assert(value >= 1, name .. " 被归零")
		end
	end)
	for name, value in pairs(snapshots) do
		local component = doer.components[name]
		if name == "health" then component:SetCurrentHealth(value)
		elseif name == "hunger" then component:SetCurrent(value)
		else component:DoDelta(value - component.current) end
	end
	assert(ok, err)
end

-- 检查当前运行确实由独立、非持久化的临时月光玻璃轨道组成。
local function InspectRun(session)
	local run = session.run
	assert(run.routeMap.spotCount == 6, "六站配额错误")
	for _, priority in ipairs({ "P0", "P1", "P2" }) do
		assert(#run.routeMap.selectedByPriority[priority] == 2, priority .. " 配额错误")
	end
	assert(#run.plan.arcs == 6, "观景圆弧数量错误")
	assert((run.plan.groundDistance or 0) > 0, "路线没有生成地面轨道")
	assert(math.abs((run.plan.groundDistance or 0) + (run.plan.elevatedDistance or 0)
		- run.plan.totalDistance) < 0.1, "地面与抬升里程统计不完整")
	local scenicSegments = 0
	for _ in pairs(run.plan.scenicSegments or {}) do scenicSegments = scenicSegments + 1 end
	assert(scenicSegments == 6 * config.SCENIC_ARC_SEGMENTS, "观景圆弧分段错误")
	for _, arc in ipairs(run.plan.arcs) do
		assert(arc.sweepDegrees == config.SCENIC_ARC_FRACTION * 360, "观景圆弧角度错误")
		assert(arc.heightMode ~= nil and arc.height ~= nil, "观景圆弧缺少高度模式")
		assert(arc.segmentCount == config.SCENIC_ARC_SEGMENTS
			and #arc.points == config.SCENIC_ARC_SEGMENTS + 1, "观景圆弧节点错误")
		local expectedChord = 2 * arc.radius * math.sin(
			config.SCENIC_ARC_FRACTION * math.pi / config.SCENIC_ARC_SEGMENTS)
		for _, point in ipairs(arc.points) do
			assert(math.abs(aipDist(point, arc.center) - arc.radius) < 0.01, "观景圆弧半径不稳定")
		end
		for index = 2, #arc.points do
			assert(math.abs(aipDist(arc.points[index - 1], arc.points[index]) - expectedChord) < 0.01,
				"观景圆弧弦长错误")
		end
	end
	for _, entity in ipairs(run.entities) do
		assert(entity:IsValid() and not entity.persists and entity._aip_train_run_id == run.id, "临时实体归属错误")
	end
	assert(run.car.prefab == "aip_pig_king_train_car", "不是月光玻璃观光车")
	assert(session.doer.Physics:IsActive(), "观光期间原矿车物理未启用")
	local activePoints, activeLinks = 0, 0
	for _, point in pairs(run.points) do if point:IsValid() then activePoints = activePoints + 1 end end
	for _, link in pairs(run.links) do if link:IsValid() then activeLinks = activeLinks + 1 end end
	assert(activePoints == config.TRACK_LOOKAHEAD + 1 and activeLinks == config.TRACK_LOOKAHEAD,
		"初始轨道没有按窗口展示")
	assert(run.points[#run.plan.points] == nil, "发车前错误生成了完整路线")
	assert(run.plan.totalDistance <= config.MAX_DISTANCE and run.plan.visualCount <= config.MAX_VISUALS, "轨道超预算")
	local record = session.doer:GetSaveRecord()
	assert(record.y == nil and record.x == run.plan.station.x and record.z == run.plan.station.z, "存档未回退到陆地总站")
end

-- 记录当前有效轨道窗口大小，并确认驶过的第一段已经从世界中移除。
local function SampleTrackWindow(session)
	local run = session.run
	local activePoints, activeLinks = 0, 0
	for _, point in pairs(run.points) do if point:IsValid() then activePoints = activePoints + 1 end end
	for _, link in pairs(run.links) do if link:IsValid() then activeLinks = activeLinks + 1 end end
	session.maxActivePoints = math.max(session.maxActivePoints or 0, activePoints)
	session.maxActiveLinks = math.max(session.maxActiveLinks or 0, activeLinks)
	assert(activePoints <= config.TRACK_LOOKAHEAD + config.TRACK_RETAIN_BEHIND + 1,
		"同时显示的轨道端点过多：" .. tostring(activePoints))
	assert(activeLinks <= config.TRACK_LOOKAHEAD + config.TRACK_RETAIN_BEHIND,
		"同时显示的轨道连接过多：" .. tostring(activeLinks))
	if run.pointIndex >= 3 and run.links[1] ~= nil and not run.links[1]:IsValid() then
		session.sawTrackRetired = true
	end
end

-- 采样人物显示高度与轨道净空目标，记录整趟行程的最大偏差。
local function SampleRideHeight(session)
	local run = session.run
	if not run.boarded or run.position == nil then return end
	local _, actualY = session.doer.Transform:GetWorldPosition()
	local clearance = run.position.y > config.GROUND_HEIGHT and config.RIDE_CLEARANCE or 0
	local expectedY = run.position.y + clearance
	session.heightSamples = (session.heightSamples or 0) + 1
	session.maxHeightError = math.max(session.maxHeightError or 0, math.abs(actualY - expectedY))
end

-- 观察真实六站往返；早退、死亡、掉线、节点失效及超时都会输出失败报告。
local function Observe(session)
	local run, doer = session.run, session.doer
	assert(doer:IsValid(), "乘客实体已移除")
	if run.ended then
		if not session.cameraProbePassed then
			Finish(session, false, "客户端第三视角鼠标直控探针未返回")
			return
		end
		if not Check(session, "六站自动往返与清理", function()
			assert(run.endReason == "complete", "运行中止：" .. tostring(run.endReason))
			assert(#run.entities == 0 and #run.points == 0 and doer._aip_train_run == nil, "临时运行有残留")
			assert(doer:GetPosition().y == 0, "未安全落地")
			assert(doer.Physics:IsActive(), "结束后人物物理未恢复")
			assert((session.heightSamples or 0) > 0 and (session.maxHeightError or math.huge) < 0.25,
				"乘车高度偏差过大：" .. tostring(session.maxHeightError))
			assert(session.sawScenicSpeed and session.sawCruiseAfterArc, "未完整观察到圆弧减速与巡航恢复")
			assert(session.sawTrackRetired, "驶过的轨道没有流式回收")
		end) then return end
		local diagnostics = run.rideDiagnostics or {}
		table.insert(session.lines, string.format(
			"[INFO] 原矿车运动=active；轨道窗口=%d点/%d段；地面/抬升=%.1f/%.1f；高度切换=%d；圆弧减速=%d；巡航=%d；高度采样=%d；最大垂直偏差=%.4f；最大单帧高度变化=%.4f；垂直换向=%d；结束物理=active",
			session.maxActivePoints or 0, session.maxActiveLinks or 0,
			run.plan.groundDistance or 0, run.plan.elevatedDistance or 0,
			run.plan.heightTransitions or 0,
			config.SCENIC_SPEED, config.SPEED,
			session.heightSamples or 0, session.maxHeightError or 0,
			diagnostics.maxVerticalStep or 0, diagnostics.directionChanges or 0))
		Finish(session, true, "全部检查完成，已回到猪王村。")
		return
	end
	SampleRideHeight(session)
	if run.boarded then SampleTrackWindow(session) end
	if run.boarded then
		local speed = doer.components.aipc_orbit_driver.speed
		if speed == config.SCENIC_SPEED then
			session.sawScenicSpeed = true
		elseif session.sawScenicSpeed and speed == config.SPEED then
			session.sawCruiseAfterArc = true
		end
	end
	if run.boarded and not session.probed then
		session.probed = true
		if not Check(session, "真实轨道、六段观景圆弧、月光玻璃车与存档", function() InspectRun(session) end) then return end
		if not Check(session, "实际乘客三维保底", function() ProbeVitals(doer) end) then return end
		if not Check(session, "受击和旧矿车中止回调不下车", function()
			doer:PushEvent("attacked", { attacker = doer, damage = 0, original_damage = 0 })
			doer.components.aipc_orbit_driver:AbortDrive()
			assert(not run.ended and doer._aip_train_run == run, "受击后意外下车")
		end) then return end
		-- 用普通状态覆盖模拟击退后的状态变化，不触发真实落水或死亡流程。
		doer.sg:GoToState("idle")
		session.checkState = true
	elseif session.checkState and not TheNet:IsServerPaused(true) then
		session.checkState = false
		if not Check(session, "状态被覆盖后恢复乘车", function()
			assert(doer.sg.currentstate.name == "aip_drive" and not run.ended, "未恢复驾驶状态")
		end) then return end
	end
	Later(session, 0.5, function() Observe(session) end)
end

-- 完成隔离场景后发起真实观光；失败配额和无安全路线同样是可报告的测试结果。
local function StartRide(session)
	local king = FindKing(session.doer)
	if king == nil then
		Finish(session, false, "本分片找不到猪王")
		return
	end
	session.manager = king.components.aipc_pig_king_train
	local ok, result = session.manager:StartTrain(session.doer, false)
	if not ok then
		Finish(session, false, "无法开始观光：" .. tostring(result ~= nil and result.code)
			.. "；" .. tostring(result ~= nil and result.detail))
		return
	end
	session.run = session.doer._aip_train_run
	if session.run == nil then
		Finish(session, false, "观光启动后缺少运行记录")
		return
	end
	Later(session, 0.5, function() Observe(session) end)
end

-- 每次静态任务只跑一个隔离场景，避免一次执行全部测试阻塞模拟线程。
local function RunScenario(session, index)
	local cases = {
		{ "猪村每日补位、同日锁定与任务去重", scenarios.PigVillageDailyFill },
		{ "猪村交付、奖励礼物与猪人逻辑恢复", scenarios.PigVillageDelivery },
		{ "体验券碎片去重调度与三合一", scenarios.TrainTicketFragmentMerge },
		{ "三维正常变化及最低值保护", scenarios.VitalFloor },
		{ "独立对象显式死亡", scenarios.ForcedDeath },
		{ "组件与状态图移除后的重复退出", scenarios.RemovedPassenger },
		{ "死亡、掉线、换分片与跨运行清理隔离", scenarios.RuntimeCleanup },
	}
	local case = cases[index]
	if case == nil then StartRide(session) return end
	if not Check(session, case[1], case[2]) then return end
	Later(session, 0.1, function() RunScenario(session, index + 1) end)
end

-- 使用测试券后启动唯一测试会话，所有成功、失败和突发退出统一进入 Finish。
function Tests.Start(doer)
	if not TheWorld.ismastersim or doer == nil or not doer:IsValid() then return false end
	generation = generation + 1
	local restarted = active ~= nil
	if active ~= nil then
		local cleaned, cleanupError = Cleanup(active, "test_restarted")
		if not cleaned then
			aipPrint("[PigKingTrain][TestReport]", "[FAIL] 重启前清理异常：" .. tostring(cleanupError))
		end
	end
	TheWorld._aipTrainLastTestReport = nil
	local session = { doer = doer, userid = doer.userid, tasks = {}, lines = {}, passed = 0,
		generation = generation }
	active = session
	if restarted then table.insert(session.lines, "[INFO] 已清理上一次测试并从头重新开始") end
	aipPrint("[PigKingTrain][TestReport]", "[START] 自动测试会话=" .. tostring(generation)
		.. (restarted and "；已重启" or ""))
	session.onInterrupted = function() Finish(session, false, "实际乘客死亡、掉线或离开了当前分片。") end
	for _, event in ipairs({ "death", "onremove", "player_despawn" }) do
		TheWorld:ListenForEvent(event, session.onInterrupted, doer)
	end
	local probeOk, probeRequested = false, false
	if Tests.cameraProber ~= nil then
		probeOk, probeRequested = pcall(Tests.cameraProber, doer, session.generation)
	end
	if not probeOk or probeRequested == false then
		Later(session, 0, function() Finish(session, false, "无法启动客户端第三视角镜头探针") end)
	end
	Later(session, 5, function()
		if not session.cameraProbeFinished then
			Finish(session, false, "客户端第三视角镜头探针 5 秒内未返回")
		end
	end)
	if doer.components.talker ~= nil then
		doer.components.talker:Say(restarted and "已重新开始自动测试；结束后会自动暂停。"
			or "开始自动测试；结束后会暂停并分批输出报告。")
	end
	Later(session, config.MAX_DURATION + 30, function() Finish(session, false, "测试超时") end)
	-- 等使用物品的动作收尾后再开始，避免初始 idle 覆盖上车状态。
	Later(session, 0.5, function()
		if doer._aip_train_run ~= nil then
			Finish(session, false, "已经在观光中，请先退出再测试")
			return
		end
		RunScenario(session, 1)
	end)
	return true
end

-- 重新发送最近报告，暂停期间也可使用。
function Tests.Replay(doer)
	local report = TheWorld._aipTrainLastTestReport
	if report == nil then aipPrint("[PigKingTrain][TestReport]", "尚无测试报告。") return end
	Tests.Output(report, doer ~= nil and doer.userid or nil)
end

return Tests
