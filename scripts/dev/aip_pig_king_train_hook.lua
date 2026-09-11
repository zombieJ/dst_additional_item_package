local _G = GLOBAL
if _G.aipGetModConfig("dev_mode") ~= "enabled" then return end
local PCall, Assert = _G.pcall, _G.assert

table.insert(PrefabFiles, "aip_pig_king_train_test_ticket")
local tests = _G.require("dev/aip_pig_king_train_tests")
local driverCamera = _G.require("aip_driver_camera")

-- 分批报告同步给使用测试券的客户端，玩家可在本地控制台和日志中查看。
AddClientModRPCHandler(modname, "aipPigTrainTestReport", function(chunk)
	_G.aipPrint("[PigKingTrain][TestReport]", chunk)
end)

-- 在发券客户端用合成鼠标位置验证第三视角转向，不要求开发者实际移动鼠标观察。
AddClientModRPCHandler(modname, "aipPigTrainTestCameraProbe", function(sessionGeneration)
	local ok, detail = PCall(function()
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
			heading = 350,
			headingtarget = 34,
			headingdelta = 1,
			lastheadingdelta = 2,
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
		Assert(driverCamera.GetMouseTargetPitch(height, height) == pitchTop,
			"俯仰没有立即采用鼠标纵向映射")
		return string.format("yawLeft=%.1f,yawRight=%.1f,trackLerp=true,offsetInstant=true,pitch=%.1f/%.1f/%.1f,nearCenter=%.1f",
			left, right,
			driverCamera.PITCH_TOP, driverCamera.PITCH_CENTER, driverCamera.PITCH_BOTTOM,
			nearRight)
	end)
	_G.aipRPC("aipPigTrainTestCameraProbeResult", sessionGeneration, ok and "true" or "false", tostring(detail))
end)

-- 服务端只接收当前会话、当前发起者的客户端探针结果。
AddModRPCHandler(modname, "aipPigTrainTestCameraProbeResult", function(player, sessionGeneration, success, detail)
	tests.CameraProbeResult(player, sessionGeneration, success, detail)
end)

-- 报告全部送达后由客户端墙钟更新阶段请求暂停，避免在服务端 Update 中途切换暂停状态。
AddClientModRPCHandler(modname, "aipPigTrainTestPause", function()
	if _G.TheNet:GetIsServerAdmin() then
		_G.SetServerPaused(true)
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
tests.cameraProber = function(doer, sessionGeneration)
	if doer == nil or doer.userid == nil then return false end
	_G.aipRPCClient("aipPigTrainTestCameraProbe", doer.userid, sessionGeneration)
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
