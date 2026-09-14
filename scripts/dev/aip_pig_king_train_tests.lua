if aipGetModConfig("dev_mode") ~= "enabled" then return {} end

local scenarios = require("dev/aip_pig_king_train_scenarios")
local e2e = require("dev/aip_pig_king_train_e2e")
local config = require("configurations/aip_pig_king_train")
local Tests = {}
local active = nil
local generation = 0
local REPORT_BATCH = 3
local REPORT_DELAY = 0.15
local TOTAL_STEPS = 36
local E2E_STEP_INDEX = {
	setup = 11,
	quest1_dialogue = 12,
	quest1_grant = 13,
	quest1_trade = 14,
	quest1_reward = 15,
	quest2_dialogue = 16,
	quest2_grant = 17,
	quest2_trade = 18,
	quest2_reward = 19,
	quest3_dialogue = 20,
	quest3_grant = 21,
	quest3_trade = 22,
	quest3_reward = 23,
	merge = 24,
	king_trade = 25,
}
local PROBE_NAMES = {
	initial = "客户端发车前镜头、提示与任务标记",
	driving = "客户端乘车提示、轨道渐入与夜间随身灯",
	ended = "客户端下车后提示、驾驶状态与随身灯清理",
}

-- 第一次切换测试时段前保存完整时钟，后续白天与夜晚共用同一份恢复点。
local function SaveClock(session)
	if session.clockSnapshot ~= nil and session.clock ~= nil then return session.clock end
	local clock = TheWorld.net ~= nil and TheWorld.net.components ~= nil
		and TheWorld.net.components.clock or nil
	assert(clock ~= nil and type(clock.OnSave) == "function" and type(clock.OnLoad) == "function",
		"世界时钟组件不可用")
	session.clock = clock
	session.clockSnapshot = assert(clock:OnSave(), "无法保存当前世界时间")
	return clock
end

-- 临时改为全白天，让真实猪屋居民保持清醒并可交互。
local function BeginDay(session)
	local clock = SaveClock(session)
	TheWorld:PushEvent("ms_setclocksegs", { day = 16, dusk = 0, night = 0 })
	TheWorld:PushEvent("ms_setphase", "day")
	session.forcedPhase = "day"
	local current = clock:OnSave()
	assert(current ~= nil and current.phase == "day", "服务端时钟未接受白天阶段")
end

-- 临时改为全夜，保证任何世界时段配置都能进入真实夜晚。
local function BeginNight(session)
	local clock = SaveClock(session)
	TheWorld:PushEvent("ms_setclocksegs", { day = 0, dusk = 0, night = 16 })
	TheWorld:PushEvent("ms_setphase", "night")
	session.forcedPhase = "night"
	local current = clock:OnSave()
	assert(current ~= nil and current.phase == "night", "服务端时钟未接受夜晚阶段")
end

-- 记录每个分帧步骤的起止与下一步等待时间，便于定位卡帧点。
local function StepLog(session, index, name, state, result, nextDelay)
	aipPrint("[PigKingTrain][TestStep]", "generation=" .. tostring(session.generation),
		string.format("step=%d/%d", index, TOTAL_STEPS), "name=" .. tostring(name),
		"state=" .. tostring(state), "result=" .. tostring(result or "pending"),
		string.format("nextWait=%.2f", nextDelay or 0))
end

-- 恢复测试前的完整时钟快照，包括时段进度与月相。
local function RestoreClock(session)
	if session.clockSnapshot == nil or session.clock == nil then return true end
	local snapshot = session.clockSnapshot
	session.clockSnapshot = nil
	session.clock:OnLoad(snapshot)
	if session.clock.LongUpdate ~= nil then session.clock:LongUpdate(0) end
	session.forcedPhase = nil
	return true
end

-- 报告每条最多一行，避免错误堆栈或超长实体字符串撑满控制台。
local function Line(value)
	local text = tostring(value):gsub("[\r\n]+", " | ")
	-- DST 的 #LUA ERROR 是引擎错误界面控制标记，测试报告绝不能原样回放。
	text = text:gsub("#LUA ERROR", "Lua traceback"):gsub("#stack traceback", "stack traceback")
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
	local e2eCallOK, e2eCleaned, e2eError = pcall(e2e.Cleanup, session)
	if not e2eCallOK and cleanupError == nil then
		cleanupError = Line(e2eCleaned)
	elseif e2eCleaned == false and cleanupError == nil then
		cleanupError = Line(e2eError or "E2E 场景清理后仍有实体残留")
	end
	local restored, restoreError = pcall(RestoreClock, session)
	if not restored and cleanupError == nil then cleanupError = Line(restoreError) end
	if session.onInterrupted ~= nil then
		for _, event in ipairs({ "death", "onremove", "player_despawn" }) do
			TheWorld:RemoveEventCallback(event, session.onInterrupted, session.doer)
		end
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
		session.failed = session.failed + 1
		table.insert(session.lines, "[FAIL] 测试运行清理：" .. cleanupError)
	end
	success = success and session.failed == 0
	local report = { success = success, passed = session.passed, failed = session.failed,
		skipped = session.skipped, detail = detail, lines = {} }
	table.insert(report.lines, "[AIP TRAIN TEST] " .. (success and "成功" or "失败")
		.. "；通过 " .. session.passed .. " 项；失败 " .. session.failed
		.. " 项；跳过 " .. session.skipped .. " 项")
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

-- 所有异步步骤都经过安全异常保护；不生成会触发引擎错误界面的 traceback 标记。
local function Later(session, delay, fn)
	local task = TheWorld:DoStaticTaskInTime(delay, function()
		if session.finished then return end
		local ok, err = pcall(fn)
		if not ok then Finish(session, false, err) end
	end)
	table.insert(session.tasks, task)
end

-- 记录已经完成的检查结果，供同步断言和异步状态等待共用。
local function RecordCheck(session, name, ok, detail)
	if not ok then
		session.failed = session.failed + 1
		table.insert(session.lines, "[FAIL] " .. name .. "：" .. Line(detail))
		return false
	end
	session.passed = session.passed + 1
	table.insert(session.lines, "[PASS] " .. name)
	return true
end

-- 每个独立检查都记录结果；普通断言失败只累计，不阻断后续可执行覆盖。
local function Check(session, name, fn)
	local ok, err = pcall(fn)
	return RecordCheck(session, name, ok, err)
end

-- 把 E2E 阶段 key 映射为稳定的步骤编号与玩家可读名称。
local function E2EStepData(key)
	return assert(E2E_STEP_INDEX[key], "未知 E2E 步骤：" .. tostring(key)),
		assert(e2e.STEPS[key], "E2E 步骤缺少名称：" .. tostring(key))
end

-- 记录真实 E2E 阶段开始，动作细节由 E2E 模块的专用日志补充。
local function BeginE2EStep(session, key)
	local index, name = E2EStepData(key)
	StepLog(session, index, name, "start")
end

-- 记录真实 E2E 阶段完成，同时保留本次实体、物品与动作诊断。
local function PassE2EStep(session, key, detail)
	local index, name = E2EStepData(key)
	RecordCheck(session, name, true, detail)
	table.insert(session.lines, "[INFO] E2E stage=" .. tostring(key) .. "；" .. Line(detail))
	local nextDelay = key == "merge" and config.TEST_HEAVY_STEP_DELAY
		or key == "king_trade" and 0.5 or 0.75
	StepLog(session, index, name, "complete", "pass", nextDelay)
end

-- E2E 任一必需阶段失败后立即进入统一清理、报告和暂停路径。
local function FailE2EStep(session, key, detail)
	local index, name = E2EStepData(key)
	RecordCheck(session, name, false, detail)
	StepLog(session, index, name, "complete", "fail")
	Finish(session, false, "真实 E2E 在 " .. name .. " 失败：" .. Line(detail))
end

-- 完成一个客户端阶段探针，并在阶段回调中继续后续收尾。
local function CompleteClientProbe(session, phase, success, detail)
	local probe = session.clientProbes[phase]
	if probe == nil or probe.finished then return false end
	probe.finished = true
	local passed = success == true or success == "true"
	Check(session, PROBE_NAMES[phase] or ("客户端探针 " .. tostring(phase)), function()
		assert(passed, Line(detail))
	end)
	table.insert(session.lines, "[INFO] 客户端探针 phase=" .. tostring(phase) .. "；" .. Line(detail))
	if probe.onComplete ~= nil then probe.onComplete() end
	return true
end

-- 请求当前发起客户端执行有限轮询探针，无法发送或超时也只记录本项失败。
local function RequestClientProbe(session, phase, onComplete)
	if session.clientProbes[phase] ~= nil then return false end
	session.clientProbes[phase] = { finished = false, onComplete = onComplete }
	local ok, requested = false, false
	if Tests.clientProber ~= nil then
		ok, requested = pcall(Tests.clientProber, session.doer, session.generation, phase)
	end
	if not ok or requested == false then
		CompleteClientProbe(session, phase, false, "无法发送客户端阶段探针")
		return false
	end
	if not session.clientProbes[phase].finished then
		Later(session, config.TEST_CLIENT_PROBE_TIMEOUT, function()
			CompleteClientProbe(session, phase, false,
				"客户端阶段探针 " .. tostring(config.TEST_CLIENT_PROBE_TIMEOUT) .. " 秒内未返回")
		end)
	end
	return true
end

-- 只接收当前代数、当前发起者和已请求阶段的客户端探针结果。
function Tests.ClientProbeResult(player, sessionGeneration, phase, success, detail)
	local session = active
	if session == nil or session.finished or session.generation ~= tonumber(sessionGeneration)
		or player == nil or player ~= session.doer or PROBE_NAMES[phase] == nil then return false end
	return CompleteClientProbe(session, phase, success, detail)
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

-- 上车完成时立即记录初始轨道窗口，避免夜间同步期间行驶推进污染初始断言。
local function CaptureInitialTrackWindow(session)
	local run = session.run
	local activePoints, activeLinks = 0, 0
	for _, point in pairs(run.points) do if point:IsValid() then activePoints = activePoints + 1 end end
	for _, link in pairs(run.links) do if link:IsValid() then activeLinks = activeLinks + 1 end end
	session.initialTrackPoints = activePoints
	session.initialTrackLinks = activeLinks
	session.initialFullRouteVisible = run.points[#run.plan.points] ~= nil
end

-- 当前窗口中的轨道实体必须仍有效且属于本次临时运行。
local function AssertActiveOwnedEntity(run, entity, label)
	assert(entity ~= nil and entity:IsValid(), label .. "已失效")
	assert(not entity.persists and entity._aip_train_run_id == run.id,
		label .. "归属错误")
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
		assert(arc.heightMode ~= nil and arc.heightReason ~= nil and arc.height ~= nil
			and arc.groundSearch ~= nil, "观景圆弧缺少高度决策诊断")
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
	for segmentIndex = 1, #run.plan.points - 1 do
		local profile = run.plan.segmentProfiles ~= nil and run.plan.segmentProfiles[segmentIndex] or nil
		assert(profile ~= nil and profile.mode ~= nil and profile.distance ~= nil,
			"轨道分段缺少高度模式诊断：" .. tostring(segmentIndex))
	end
	local modeDistance = 0
	for _, distance in pairs(run.plan.modeDistances or {}) do modeDistance = modeDistance + distance end
	assert(math.abs(modeDistance - run.plan.totalDistance) < 0.1,
		"轨道高度模式里程统计不完整")
	local blockers = assert(run.plan.blockerDiagnostics, "路线缺少判障策略诊断")
	assert(blockers.policy == "ghost-physics-aligned" and blockers.landmarkCores == 6
		and blockers.hardBlockers >= blockers.landmarkCores
		and blockers.indexedBlockers >= blockers.hardBlockers,
		"路线判障没有与观光幽灵物理保持一致")
	for index, entity in ipairs(run.entities) do
		assert(not entity.persists and entity._aip_train_run_id == run.id,
			string.format("临时实体历史归属错误：index=%d,prefab=%s,valid=%s",
				index, tostring(entity.prefab), tostring(entity:IsValid())))
	end
	local window = assert(run.trackWindow, "当前轨道窗口不存在")
	for index = window.firstPoint, window.lastPoint do
		AssertActiveOwnedEntity(run, run.points[index], "当前轨道端点 " .. tostring(index))
	end
	for index = window.firstSegment, window.lastSegment do
		AssertActiveOwnedEntity(run, run.links[index], "当前轨道连接 " .. tostring(index))
	end
	assert(run.car.prefab == "aip_pig_king_train_car", "不是月光玻璃观光车")
	local light = assert(run.light, "观光随身灯未创建")
	assert(light:IsValid() and light.prefab == "aip_pig_king_train_light", "观光随身灯实体无效")
	assert(light.entity:GetParent() == session.doer, "观光随身灯未绑定乘客")
	assert(light.Light ~= nil and light.Light:IsEnabled(), "观光随身灯未启用")
	assert(light.Light:GetRadius() >= config.RIDE_LIGHT_RADIUS, "观光随身灯范围不足")
	assert(math.abs(light.Light:GetFalloff() - config.RIDE_LIGHT_FALLOFF) < 0.001,
		"观光随身灯衰减参数错误")
	assert(math.abs(light.Light:GetIntensity() - config.RIDE_LIGHT_INTENSITY) < 0.001,
		"观光随身灯亮度参数错误")
	assert(session.doer.Physics:IsActive(), "观光期间原矿车物理未启用")
	assert(session.initialTrackPoints == config.TRACK_LOOKAHEAD + 1
		and session.initialTrackLinks == config.TRACK_LOOKAHEAD,
		"初始轨道没有按窗口展示")
	assert(session.initialFullRouteVisible == false, "发车前错误生成了完整路线")
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

-- 在下车客户端探针返回后输出统一口径的逐帧诊断，并按累计失败决定最终结果。
local function FinishRideReport(session)
	local run = session.run
	local diagnostics = run.rideDiagnostics or {}
	local buckets = diagnostics.errorBuckets or { 0, 0, 0, 0, 0 }
	local ground = run.plan.groundDistance or 0
	local elevated = run.plan.elevatedDistance or 0
	local measured = ground + elevated
	local groundRatio = measured > 0 and ground / measured or 0
	table.insert(session.lines, string.format(
		"[INFO] 原矿车运动=active；轨道窗口=%d点/%d段；地面/抬升=%.1f/%.1f；地面占比=%.1f%%；坡道=%.1f；高度切换=%d；圆弧减速=%d；巡航=%d；逐帧高度采样=%d；最大垂直偏差=%.4f/%.2f；有符号范围=%+.4f/%+.4f；最大单帧高度变化=%.4f；垂直换向=%d(平地=%d/坡道=%d)；结束物理=active",
		session.maxActivePoints or 0, session.maxActiveLinks or 0,
		ground, elevated, groundRatio * 100, run.plan.rampDistance or 0, run.plan.heightTransitions or 0,
		config.SCENIC_SPEED, config.SPEED,
		diagnostics.samples or 0, diagnostics.maxVerticalError or 0,
		config.TEST_MAX_RIDE_VERTICAL_ERROR,
		diagnostics.minNegativeError or 0, diagnostics.maxPositiveError or 0,
		diagnostics.maxVerticalStep or 0, diagnostics.directionChanges or 0,
		diagnostics.flatDirectionChanges or 0, diagnostics.rampDirectionChanges or 0))
	local modeDistances = run.plan.modeDistances or {}
	table.insert(session.lines, string.format(
		"[INFO] 高度模式里程：ground=%.1f；ground-scenic=%.1f；elevated-fallback=%.1f；elevated-scenic=%.1f；ocean-elevated=%.1f；landingSearch=%.0f->%.0f/step%.0f/directions%d",
		modeDistances.ground or 0, modeDistances["ground-scenic"] or 0,
		modeDistances["elevated-fallback"] or 0, modeDistances["elevated-scenic"] or 0,
		run.plan.oceanElevatedDistance or 0, config.ELEVATION_RAMP_DISTANCE,
		config.GROUND_TRANSITION_MAX_DISTANCE, config.GROUND_TRANSITION_STEP,
		config.GROUND_TRANSITION_DIRECTIONS))
	local blockers = run.plan.blockerDiagnostics or {}
	table.insert(session.lines, string.format(
		"[INFO] 判障策略：%s；扫描=%d；索引障碍=%d；硬障碍=%d；高架障碍=%d；危险地标=%d；危险实体=%d；角色=%d；景点核心=%d；忽略普通障碍=%d",
		tostring(blockers.policy), blockers.scannedEntities or 0, blockers.indexedBlockers or 0,
		blockers.hardBlockers or 0,
		blockers.elevatedBlockers or 0, blockers.dangerBlockers or 0,
		blockers.hazardBlockers or 0, blockers.characterBlockers or 0,
		blockers.landmarkCores or 0,
		blockers.ignoredGroundClutter or 0))
	table.insert(session.lines, string.format(
		"[INFO] 垂直误差分桶：<=0.05=%d；<=0.10=%d；<=0.15=%d；<=0.25=%d；>0.25=%d；控制参数 gain=%.1f/feedForward=true/gravity=%.2f/clearance=%.2f",
		buckets[1] or 0, buckets[2] or 0, buckets[3] or 0, buckets[4] or 0, buckets[5] or 0,
		session.doer.components.aipc_orbit_driver.ySpeed,
		config.RIDE_VERTICAL_GRAVITY_COMPENSATION, config.RIDE_CLEARANCE))
	local regimeValues = {}
	for _, name in ipairs({ "ground-flat", "elevated-flat", "up-ramp", "down-ramp" }) do
		local regime = diagnostics.regimes ~= nil and diagnostics.regimes[name] or nil
		local samples = regime ~= nil and regime.samples or 0
		local divisor = math.max(1, samples)
		table.insert(regimeValues, string.format("%s=%d/%+.4f/%.4f/%.4f", name, samples,
			regime ~= nil and regime.errorSum / divisor or 0,
			regime ~= nil and regime.absoluteErrorSum / divisor or 0,
			regime ~= nil and regime.maxAbsoluteError or 0))
	end
	table.insert(session.lines, "[INFO] 垂直工况(samples/meanSigned/meanAbs/maxAbs)："
		.. table.concat(regimeValues, "；"))
	for _, arc in ipairs(run.plan.arcs or {}) do
		local rejects = arc.groundSearch or {}
		local elevatedRejects = arc.elevatedSearch or {}
		table.insert(session.lines, string.format(
			"[INFO] 景点高度：%s/%s mode=%s reason=%s radius=%.1f height=%.1f groundSearch=c%d/o%d/v%d/b%d elevatedSearch=c%d/v%d/b%d landings=%.1f/%.1f",
			tostring(arc.stop.id), tostring(arc.stop.priority), tostring(arc.heightMode),
			tostring(arc.heightReason), arc.radius or 0, arc.height or 0,
			rejects.candidates or 0, rejects.ocean or 0, rejects.void or 0,
			rejects["ground-blocker"] or 0,
			elevatedRejects.candidates or 0, elevatedRejects.void or 0,
			elevatedRejects["elevated-blocker"] or 0,
			arc.entryGroundDistance or -1, arc.exitGroundDistance or -1))
	end
	Finish(session, true, session.failed == 0 and "全部检查完成，已回到猪王村。"
		or "全部可执行检查已完成；存在失败项，已安全回到猪王村。")
end

-- 行程结束后每次只跑一组断言，组间让出模拟帧。
local function CheckCompletedRide(session, index)
	index = index or 1
	local run, doer = session.run, session.doer
	local diagnostics = run.rideDiagnostics or {}
	local cases = {
		{ "六站自动往返与安全清理", function()
			assert(run.endReason == "complete", "运行中止：" .. tostring(run.endReason))
			assert(#run.entities == 0 and #run.points == 0 and doer._aip_train_run == nil, "临时运行有残留")
			for entity in pairs(session.e2e ~= nil and session.e2e.entities or {}) do
				assert(not entity:IsValid(), "E2E 临时实体有残留：" .. tostring(entity.prefab))
			end
			assert(doer:GetPosition().y == 0, "未安全落地")
			assert(doer.Physics:IsActive(), "结束后人物物理未恢复")
		end },
		{ "逐帧乘客高度稳定", function()
			assert((diagnostics.samples or 0) > 0, "逐帧乘客诊断没有样本")
			assert((diagnostics.maxVerticalError or math.huge) < config.TEST_MAX_RIDE_VERTICAL_ERROR,
				string.format("最大垂直偏差 %.4f 超过阈值 %.2f",
					diagnostics.maxVerticalError or math.huge, config.TEST_MAX_RIDE_VERTICAL_ERROR))
		end },
		{ "路线多数贴地且仅少量抬升", function()
			local ground = run.plan.groundDistance or 0
			local elevated = run.plan.elevatedDistance or 0
			local total = ground + elevated
			local ratio = total > 0 and ground / total or 0
			assert(total > 0 and math.abs(total - run.plan.totalDistance) < 0.1, "路线里程统计不完整")
			assert(config.TEST_MIN_GROUND_RATIO == config.MIN_GROUND_RATIO,
				"自动测试阈值与正式规划阈值不一致")
			assert(ratio >= config.TEST_MIN_GROUND_RATIO,
				string.format("地面占比 %.1f%% 低于 %.1f%%", ratio * 100, config.TEST_MIN_GROUND_RATIO * 100))
			assert(elevated == 0 or (run.plan.heightTransitions or 0) > 0,
				"存在抬升里程但没有完整高度切换")
		end },
		{ "圆弧减速与巡航恢复", function()
			assert(session.sawScenicSpeed and session.sawCruiseAfterArc, "未完整观察到圆弧减速与巡航恢复")
		end },
		{ "轨道流式回收与窗口上限", function()
			assert(session.trackWindowError == nil, session.trackWindowError)
			assert(session.sawTrackRetired, "驶过的轨道没有流式回收")
		end },
	}
	local case = cases[index]
	if case == nil then
		RequestClientProbe(session, "ended", function() FinishRideReport(session) end)
		return
	end
	local stepIndex = 31 + index
	StepLog(session, stepIndex, case[1], "start")
	local passed = Check(session, case[1], case[2])
	StepLog(session, stepIndex, case[1], "complete", passed and "pass" or "fail",
		config.TEST_STEP_DELAY)
	Later(session, config.TEST_STEP_DELAY, function() CheckCompletedRide(session, index + 1) end)
end

-- 乘车中每次只执行一组真实玩家断言，避免同帧连续改动状态。
local function RunBoardedCheck(session)
	local run, doer = session.run, session.doer
	local index = session.boardedCheckIndex or 1
	local cases = {
		{ "真实轨道、六段观景圆弧、月光玻璃车与存档", function()
			RequestClientProbe(session, "driving")
			InspectRun(session)
		end },
		{ "实际乘客三维保底", function() ProbeVitals(doer) end },
		{ "受击和旧矿车中止回调不下车", function()
			doer:PushEvent("attacked", { attacker = doer, damage = 0, original_damage = 0 })
			doer.components.aipc_orbit_driver:AbortDrive()
			assert(not run.ended and doer._aip_train_run == run, "受击后意外下车")
		end },
		{ "乘车状态恢复准备", function()
			-- 用普通状态覆盖模拟击退后的状态变化，不触发真实落水或死亡流程。
			doer.sg:GoToState("idle")
		end, true },
		{ "状态被覆盖后恢复乘车", function()
			assert(not TheNet:IsServerPaused(true), "恢复乘车状态前服务器已暂停")
			assert(doer.sg.currentstate.name == "aip_drive" and not run.ended, "未恢复驾驶状态")
		end },
	}
	local case = cases[index]
	if case == nil then return end
	local stepIndex = 26 + index
	StepLog(session, stepIndex, case[1], "start")
	local passed
	if case[3] then
		local ok, err = pcall(case[2])
		passed = ok
		if not ok then
			session.failed = session.failed + 1
			table.insert(session.lines, "[FAIL] " .. case[1] .. "：" .. Line(err))
		end
	else
		passed = Check(session, case[1], case[2])
	end
	StepLog(session, stepIndex, case[1], "complete", passed and "pass" or "fail", 0.5)
	session.boardedCheckIndex = index + 1
end

-- 观察真实六站往返；早退、死亡、掉线、节点失效及超时都会输出失败报告。
local function Observe(session)
	local run, doer = session.run, session.doer
	assert(doer:IsValid(), "乘客实体已移除")
	if run.ended then
		if not session.rideEndedObserved then
			session.rideEndedObserved = true
			CheckCompletedRide(session)
		end
		return
	end
	if run.boarded then
		local ok, err = pcall(function() SampleTrackWindow(session) end)
		if not ok and session.trackWindowError == nil then session.trackWindowError = Line(err) end
	end
	if run.boarded then
		local speed = doer.components.aipc_orbit_driver.speed
		if speed == config.SCENIC_SPEED then
			session.sawScenicSpeed = true
		elseif session.sawScenicSpeed and speed == config.SPEED then
			session.sawCruiseAfterArc = true
		end
	end
	if run.boarded then RunBoardedCheck(session) end
	Later(session, 0.5, function() Observe(session) end)
end

local StartNightRide

-- 白天把正式体验券真实交给猪王；确认上车后再进入夜间灯光场景。
local function StartPaidRide(session, king, ticket)
	session.manager = king.components.aipc_pig_king_train
	local hooks = {
		later = function(delay, fn) Later(session, delay, fn) end,
		begin = function(key) BeginE2EStep(session, key) end,
		pass = function(key, detail) PassE2EStep(session, key, detail) end,
		fail = function(key, detail) FailE2EStep(session, key, detail) end,
		rideReady = function(run)
			session.run = run
			if session.run == nil or session.run.paid ~= true then
				FailE2EStep(session, "king_trade", "猪王交易没有创建付券运行记录")
				return
			end
			CaptureInitialTrackWindow(session)
			Later(session, 0.5, function() StartNightRide(session) end)
		end,
	}
	if Tests.paidRideStarter ~= nil then
		Tests.paidRideStarter(session, king, ticket, hooks)
	else
		e2e.GiveTicketToKing(session, king, ticket, hooks)
	end
end

-- 上车后完成夜间准备检查，再留出冷却让客户端灯光与时钟状态稳定。
local function CompleteNightSetup(session, name, passed, detail)
	RecordCheck(session, name, passed, detail)
	if passed then
		table.insert(session.lines, "[INFO] 夜间场景已准备；originalPhase="
			.. tostring(session.clockSnapshot.phase) .. "；phase=night；sync=confirmed")
	end
	StepLog(session, 26, name, "complete", passed and "pass" or "fail",
		config.TEST_HEAVY_STEP_DELAY)
	if passed then
		Later(session, config.TEST_HEAVY_STEP_DELAY, function() Observe(session) end)
	else
		Finish(session, false, "无法准备真实夜间环境：" .. Line(detail))
	end
end

-- 有界等待网络时钟脏数据更新到 TheWorld.state，避免在 ms_setphase 同帧误判。
local function WaitForNight(session, name, attempt)
	local current = session.clock ~= nil and session.clock:OnSave() or nil
	if current ~= nil and current.phase == "night"
		and TheWorld.state ~= nil and TheWorld.state.isnight == true then
		CompleteNightSetup(session, name, true, "night")
	elseif attempt >= config.TEST_NIGHT_SYNC_ATTEMPTS then
		CompleteNightSetup(session, name, false, string.format(
			"夜晚状态同步超时；clock=%s；world=%s；attempts=%d",
			tostring(current ~= nil and current.phase or nil),
			tostring(TheWorld.state ~= nil and TheWorld.state.phase or nil), attempt))
	else
		Later(session, config.TEST_NIGHT_SYNC_INTERVAL, function()
			WaitForNight(session, name, attempt + 1)
		end)
	end
end

-- 白天真实交券并完成上车后切换夜晚，避免原版猪王睡眠禁用交易。
StartNightRide = function(session)
	local name = "真实夜间环境准备与时钟恢复点"
	StepLog(session, 26, name, "start")
	local prepared, prepareError = pcall(BeginNight, session)
	if not prepared then
		CompleteNightSetup(session, name, false, prepareError)
	else
		Later(session, config.TEST_NIGHT_SYNC_INTERVAL, function()
			WaitForNight(session, name, 1)
		end)
	end
end

-- 白天同步完成后启动真实猪屋、猪人、交付、拆包和碎片合成链路。
local function StartE2ERunner(session, king)
	local hooks = {
		later = function(delay, fn) Later(session, delay, fn) end,
		begin = function(key) BeginE2EStep(session, key) end,
		pass = function(key, detail) PassE2EStep(session, key, detail) end,
		fail = function(key, detail) FailE2EStep(session, key, detail) end,
		done = function(ticket, detail)
			session.e2eTicket = ticket
			table.insert(session.lines, "[INFO] E2E chain=complete；" .. Line(detail))
			Later(session, config.TEST_HEAVY_STEP_DELAY, function()
				StartPaidRide(session, king, ticket)
			end)
		end,
	}
	if Tests.e2eRunner ~= nil then
		Tests.e2eRunner(session, king, hooks)
	else
		e2e.Start(session, king, hooks)
	end
end

-- 有界等待白天网络状态，避免猪人在时钟复制完成前重新回屋。
local function WaitForDay(session, king, attempt)
	local current = session.clock ~= nil and session.clock:OnSave() or nil
	if current ~= nil and current.phase == "day"
		and TheWorld.state ~= nil and TheWorld.state.isday == true then
		StartE2ERunner(session, king)
	elseif attempt >= config.TEST_NIGHT_SYNC_ATTEMPTS then
		FailE2EStep(session, "setup", string.format(
			"白天状态同步超时；clock=%s；world=%s；attempts=%d",
			tostring(current ~= nil and current.phase or nil),
			tostring(TheWorld.state ~= nil and TheWorld.state.phase or nil), attempt))
	else
		Later(session, config.TEST_NIGHT_SYNC_INTERVAL, function()
			WaitForDay(session, king, attempt + 1)
		end)
	end
end

-- 完成隔离场景后先准备白天，再运行只包含必需交互的真实 E2E。
local function StartRide(session)
	local king = FindKing(session.doer)
	if king == nil then
		Finish(session, false, "本分片找不到猪王")
		return
	end
	BeginE2EStep(session, "setup")
	local prepared, prepareError = pcall(BeginDay, session)
	if not prepared then
		FailE2EStep(session, "setup", prepareError)
	else
		Later(session, config.TEST_NIGHT_SYNC_INTERVAL, function()
			WaitForDay(session, king, 1)
		end)
	end
end

-- 每次静态任务只跑一个隔离场景，避免一次执行全部测试阻塞模拟线程。
local function RunScenario(session, index)
	local cases = {
		{ "猪村每日补位、同日锁定与任务去重", scenarios.PigVillageDailyFill },
		{ "猪村交付、奖励礼物与猪人逻辑恢复", scenarios.PigVillageDelivery },
		{ "体验券碎片去重调度与三合一", scenarios.TrainTicketFragmentMerge },
		{ "碎片与正式体验券 prefab、图标及合成入口", scenarios.TrainTicketPrefabs },
		{ "正式体验券交易扣除、原版兼容与失败返券", scenarios.PaidTicketTrade },
		{ "实机运行时规划失败后的有限重试", function() scenarios.RoutePlanningRetry(session.doer) end },
		{ "三维正常变化及最低值保护", scenarios.VitalFloor },
		{ "独立对象显式死亡", scenarios.ForcedDeath },
		{ "组件与状态图移除后的重复退出", scenarios.RemovedPassenger },
		{ "死亡、掉线、换分片与跨运行清理隔离", scenarios.RuntimeCleanup },
	}
	local case = cases[index]
	if case == nil then
		Later(session, config.TEST_HEAVY_STEP_DELAY, function() StartRide(session) end)
		return
	end
	local lastScenario = index == #cases
	local nextDelay = lastScenario and config.TEST_HEAVY_STEP_DELAY or config.TEST_STEP_DELAY
	StepLog(session, index, case[1], "start")
	local passed = Check(session, case[1], case[2])
	StepLog(session, index, case[1], "complete", passed and "pass" or "fail",
		nextDelay)
	Later(session, nextDelay, function()
		if lastScenario then StartRide(session) else RunScenario(session, index + 1) end
	end)
end

-- 使用测试券后启动唯一测试会话；首代会话自动触发一次内部重启以验证旧任务可取消。
function Tests.Start(doer, internalRestart)
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
		failed = 0, skipped = 0, clientProbes = {}, generation = generation }
	active = session
	if restarted then table.insert(session.lines, "[INFO] 已清理上一次测试并从头重新开始") end
	aipPrint("[PigKingTrain][TestReport]", "[START] 自动测试会话=" .. tostring(generation)
		.. (restarted and "；已重启" or ""))
	if not internalRestart then
		Later(session, 0, function()
			if active == session then Tests.Start(doer, true) end
		end)
		return true
	end
	Check(session, "活动测试会话自动重启与旧任务取消", function()
		assert(restarted and session.generation >= 2, "内部重启没有创建新会话代数")
	end)
	session.onInterrupted = function() Finish(session, false, "实际乘客死亡、掉线或离开了当前分片。") end
	for _, event in ipairs({ "death", "onremove", "player_despawn" }) do
		TheWorld:ListenForEvent(event, session.onInterrupted, doer)
	end
	RequestClientProbe(session, "initial")
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
