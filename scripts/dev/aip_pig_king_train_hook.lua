local _G = GLOBAL
if _G.aipGetModConfig("dev_mode") ~= "enabled" then return end
local PCall, Assert = _G.pcall, _G.assert

table.insert(PrefabFiles, "aip_pig_king_train_test_ticket")
local tests = _G.require("dev/aip_pig_king_train_tests")
local driverCamera = _G.require("aip_driver_camera")
local fade = _G.require("aip_pig_king_train_fade")
local indicator = _G.require("aip_pig_village_indicator")
local config = _G.require("configurations/aip_pig_king_train")

-- 分批报告同步给使用测试券的客户端，玩家可在本地控制台和日志中查看。
AddClientModRPCHandler(modname, "aipPigTrainTestReport", function(chunk)
	_G.aipPrint("[PigKingTrain][TestReport]", chunk)
end)

-- 用合成鼠标位置验证第三视角偏移立即生效，同时保留轨道朝向的过渡字段。
local function ProbeCamera()
	Assert(_G.TheCamera ~= nil and type(_G.TheCamera.SetFlyView) == "function", "第三视角相机扩展未安装")
	local width = 1000
	local left = driverCamera.GetMouseTargetOffset(0, width)
	local quarter = driverCamera.GetMouseTargetOffset(width * 0.25, width)
	local nearLeft = driverCamera.GetMouseTargetOffset(width * 0.49, width)
	local center = driverCamera.GetMouseTargetOffset(width * 0.5, width)
	local nearRight = driverCamera.GetMouseTargetOffset(width * 0.51, width)
	local threeQuarter = driverCamera.GetMouseTargetOffset(width * 0.75, width)
	local right = driverCamera.GetMouseTargetOffset(width, width)
	local fakeCamera = {
		heading = 350, headingtarget = 34, headingdelta = 1, lastheadingdelta = 2,
		Apply = function(self) self.appliedHeading = self.heading end,
	}
	local heading, restoredHeading = driverCamera.ApplyHeadingOffset(fakeCamera, right)
	local height = 1000
	local pitchBottom = driverCamera.GetMouseTargetPitch(0, height)
	local pitchQuarter = driverCamera.GetMouseTargetPitch(height * 0.25, height)
	local pitchCenter = driverCamera.GetMouseTargetPitch(height * 0.5, height)
	local pitchThreeQuarter = driverCamera.GetMouseTargetPitch(height * 0.75, height)
	local pitchTop = driverCamera.GetMouseTargetPitch(height, height)
	Assert(left > quarter and quarter > nearLeft and nearLeft > center
		and center > nearRight and nearRight > threeQuarter and threeQuarter > right,
		"整个屏幕没有连续映射到镜头偏角")
	Assert(left == driverCamera.MOUSE_MAX_OFFSET and center == 0
		and right == -driverCamera.MOUSE_MAX_OFFSET, "鼠标左右方向映射错误")
	Assert(math.abs(heading - 275) < 0.001 and fakeCamera.appliedHeading == heading
		and restoredHeading == 350 and fakeCamera.heading == 350
		and fakeCamera.headingtarget == 34 and fakeCamera.headingdelta == 1
		and fakeCamera.lastheadingdelta == 2,
		"鼠标偏角未立即应用或破坏了轨道过渡状态")
	Assert(pitchBottom > pitchQuarter and pitchQuarter > pitchCenter
		and pitchCenter > pitchThreeQuarter and pitchThreeQuarter > pitchTop,
		"整个屏幕高度没有连续映射到俯仰角")
	Assert(pitchBottom == driverCamera.PITCH_BOTTOM and pitchCenter == driverCamera.PITCH_CENTER
		and pitchTop == driverCamera.PITCH_TOP, "鼠标纵向映射范围错误")
	return string.format("yaw=%.1f/%.1f,pitch=%.1f/%.1f/%.1f,trackLerp=true,offsetInstant=true",
		left, right, driverCamera.PITCH_TOP, driverCamera.PITCH_CENTER, driverCamera.PITCH_BOTTOM)
end

-- 查找客户端上真实绑定本地乘客的观光随身灯。
local function FindRideLight(player)
	for _, entity in pairs(_G.Ents or {}) do
		if entity.prefab == "aip_pig_king_train_light" and entity:IsValid()
			and entity.entity ~= nil and entity.entity:GetParent() == player then
			return entity
		end
	end
end

-- 读取随身灯的真实 Light 状态，供乘车与清理阶段共用。
local function LightSnapshot(player)
	local light = FindRideLight(player)
	if light == nil or light.Light == nil then return nil, "light=false" end
	local enabled = light.Light:IsEnabled()
	local radius = light.Light:GetRadius()
	local falloff = light.Light:GetFalloff()
	local intensity = light.Light:GetIntensity()
	return {
		entity = light,
		enabled = enabled,
		radius = radius,
		falloff = falloff,
		intensity = intensity,
	}, string.format("light=true,enabled=%s,radius=%.2f,falloff=%.2f,intensity=%.2f",
		tostring(enabled), radius, falloff, intensity)
end

-- 读取本地驾驶网络状态、HUD 提示、轨道渐入和随身灯观测值。
local function VisualSnapshot()
	local player = Assert(_G.ThePlayer, "本地玩家不存在")
	local hud = Assert(player.HUD, "本地 HUD 不存在")
	local controls = Assert(hud.controls, "HUD controls 不存在")
	local hint = Assert(controls.aipOrbitDriverHint, "驾驶提示控件不存在")
	local driver = Assert(player.components.aipc_orbit_driver_client, "客户端驾驶组件不存在")
	local telemetry = fade.GetTelemetry(_G.TheWorld)
	local driving = driver.isDriving:value()
	local visible = hint:IsVisible()
	local light, lightDetail = LightSnapshot(player)
	local night = _G.TheWorld.state ~= nil and _G.TheWorld.state.isnight == true
	local detail = string.format(
		"night=%s,driving=%s,hint=%s,fade=%d/%d,transparent=%s,partial=%s,staggered=%s,alphaOne=%s;%s",
		tostring(night), tostring(driving), tostring(visible), telemetry ~= nil and telemetry.startCount or 0,
		telemetry ~= nil and telemetry.completedCount or 0,
		tostring(telemetry ~= nil and telemetry.sawTransparent == true),
		tostring(telemetry ~= nil and telemetry.sawPartial == true),
		tostring(telemetry ~= nil and telemetry.sawStaggered == true),
		tostring(telemetry ~= nil and telemetry.finalAlphaOne == true), lightDetail)
	return driving, visible, telemetry, light, night, detail
end

-- 发车前验证镜头映射、HUD 初始隐藏、普通轨道排除和猪村标记头像钩子。
local function ProbeInitial()
	local cameraDetail = ProbeCamera()
	fade.ResetTelemetry(_G.TheWorld)
	local driving, visible, _, light, _, visualDetail = VisualSnapshot()
	Assert(not driving and not visible, "发车前驾驶提示或网络状态没有隐藏")
	Assert(light == nil, "发车前残留上一趟观光随身灯")
	Assert(fade.AppliesToPrefab("aip_pig_king_train_link")
		and not fade.AppliesToPrefab("aip_glass_orbit_link"), "透明渐入错误影响普通月亮轨道")
	local markerData = indicator.Resolve({ prefab = "aip_pig_village_quest_marker" }, nil)
	Assert(markerData ~= nil and markerData.image == "poi_question.tex"
		and markerData.atlas == "images/avatars.xml", "猪村任务标记没有使用原版问号头像")
	Assert(_G.ThePlayer.HUD._aipPigVillageIndicatorHook == true, "猪村任务标记 HUD 钩子未安装")
	return cameraDetail .. ",marker=poi_question;" .. visualDetail
end

-- 将一个客户端阶段结果回传给当前服务端测试会话。
local function SendProbeResult(sessionGeneration, phase, success, detail)
	_G.aipRPC("aipPigTrainTestClientProbeResult", sessionGeneration, phase,
		success and "true" or "false", tostring(detail))
end

-- 有限轮询乘车与下车阶段，等待网络状态、HUD 和渐入动画都落到可断言状态。
local function PollVisualProbe(sessionGeneration, phase, attempt)
	local ok, passed, detail = PCall(function()
		local driving, visible, telemetry, light, night, snapshot = VisualSnapshot()
		if phase == "driving" then
			return night and driving and visible and telemetry ~= nil and telemetry.startCount > 0
				and telemetry.sawTransparent and telemetry.sawPartial and telemetry.sawStaggered
				and telemetry.completedCount > 0 and telemetry.finalAlphaOne
				and light ~= nil and light.enabled
				and light.radius >= config.RIDE_LIGHT_RADIUS
				and math.abs(light.falloff - config.RIDE_LIGHT_FALLOFF) < 0.001
				and math.abs(light.intensity - config.RIDE_LIGHT_INTENSITY) < 0.001, snapshot
		elseif phase == "ended" then
			return night and not driving and not visible and light == nil, snapshot
		end
		return false, "未知客户端探针阶段：" .. tostring(phase)
	end)
	if not ok then
		SendProbeResult(sessionGeneration, phase, false, passed)
	elseif passed then
		SendProbeResult(sessionGeneration, phase, true, detail)
	elseif attempt >= 45 or phase ~= "driving" and phase ~= "ended" then
		SendProbeResult(sessionGeneration, phase, false, detail)
	else
		_G.TheWorld:DoStaticTaskInTime(0.1, function()
			PollVisualProbe(sessionGeneration, phase, attempt + 1)
		end)
	end
end

-- 在发券客户端执行发车前、乘车中和下车后三阶段自动探针。
AddClientModRPCHandler(modname, "aipPigTrainTestClientProbe", function(sessionGeneration, phase)
	if phase == "initial" then
		local ok, detail = PCall(ProbeInitial)
		SendProbeResult(sessionGeneration, phase, ok, detail)
	else
		PollVisualProbe(sessionGeneration, phase, 0)
	end
end)

-- 服务端只接收当前会话、当前发起者和已请求阶段的客户端探针结果。
AddModRPCHandler(modname, "aipPigTrainTestClientProbeResult",
	function(player, sessionGeneration, phase, success, detail)
		tests.ClientProbeResult(player, sessionGeneration, phase, success, detail)
	end)

local TEST_PAUSE_RETRY_DELAY = 0.1
local TEST_PAUSE_ATTEMPTS = 3

-- 使用原版服务器暂停接口并有限确认，避免请求丢失后只留下静止画面。
local function RequestConfirmedPause(attempt)
	_G.SetServerPaused(true)
	if _G.TheNet:IsServerPaused(true) then
		_G.aipPrint("[PigKingTrain][TestPause]", "state=confirmed",
			"attempt=" .. tostring(attempt), "native=true")
	elseif attempt >= TEST_PAUSE_ATTEMPTS then
		_G.aipPrint("[PigKingTrain][TestPause]", "state=failed",
			"attempts=" .. tostring(attempt), "native=false")
	else
		_G.TheWorld:DoStaticTaskInTime(TEST_PAUSE_RETRY_DELAY, function()
			RequestConfirmedPause(attempt + 1)
		end)
	end
end

-- 报告全部送达后由客户端墙钟更新阶段请求暂停，避免在服务端 Update 中途切换暂停状态。
AddClientModRPCHandler(modname, "aipPigTrainTestPause", function()
	if _G.TheNet:GetIsServerAdmin() then
		RequestConfirmedPause(1)
	else
		_G.aipPrint("[PigKingTrain][TestReport]", "[FAIL] 测试发起者不是管理员，无法自动暂停服务器。")
	end
end)
tests.reporter = function(userid, chunk)
	if userid ~= nil and (_G.ThePlayer == nil or _G.ThePlayer.userid ~= userid) then
		_G.aipRPCClient("aipPigTrainTestReport", userid, chunk)
	end
end
tests.pauser = function(userid)
	if userid == nil then return false end
	_G.aipRPCClient("aipPigTrainTestPause", userid)
	return true
end
tests.clientProber = function(doer, sessionGeneration, phase)
	if doer == nil or doer.userid == nil or doer.userid == "" then return false end
	_G.aipRPCClient("aipPigTrainTestClientProbe", doer.userid, sessionGeneration, phase)
	return true
end

-- 开发模式登录后发一张可重复使用的券；背包已持有时不重复发放。
AddPlayerPostInit(function(inst)
	if not _G.TheWorld.ismastersim then return end
	inst:DoTaskInTime(2, function()
		if not inst:IsValid() or inst.components.inventory == nil then return end
		if not inst.components.inventory:Has("aip_pig_king_train_test_ticket", 1) then
			local ticket = _G.SpawnPrefab("aip_pig_king_train_test_ticket")
			if ticket ~= nil then inst.components.inventory:GiveItem(ticket) end
		end
	end)
end)

-- 暂停后可重复分批打印最近一份报告，完整结果也保存在世界实体字段中。
function _G.c_aip_train_report()
	if not _G.TheWorld.ismastersim then return _G.c_remote("c_aip_train_report()") end
	tests.Replay(_G.ConsoleCommandPlayer())
end
