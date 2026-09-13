local Fade = {}

-- 只允许观光列车专用连接启用透明渐入，普通月亮轨道保持原有显示。
function Fade.AppliesToPrefab(prefab)
	return prefab == "aip_pig_king_train_link"
end

-- 重置当前客户端的透明渐入观测数据，供一次测试会话独占使用。
function Fade.ResetTelemetry(world)
	if world == nil then return nil end
	world._aipTrainFadeProbe = {
		startCount = 0,
		completedCount = 0,
		sawTransparent = false,
		sawPartial = false,
		sawStaggered = false,
		finalAlphaOne = false,
	}
	return world._aipTrainFadeProbe
end

-- 返回现有观测数据，不在读取时伪造一次测试结果。
function Fade.GetTelemetry(world)
	return world ~= nil and world._aipTrainFadeProbe or nil
end

-- 从实际 AnimState 回读透明度并累计渐入阶段，避免只验证计算公式。
function Fade.ObserveTelemetry(world, orbits, started, completed)
	local telemetry = Fade.GetTelemetry(world)
	if telemetry == nil then return end
	if started then telemetry.startCount = telemetry.startCount + 1 end
	local minAlpha, maxAlpha, validCount = nil, nil, 0
	for _, orbit in ipairs(orbits or {}) do
		if orbit:IsValid() then
			local _, _, _, alpha = orbit.AnimState:GetMultColour()
			alpha = alpha or 1
			validCount = validCount + 1
			minAlpha = minAlpha == nil and alpha or math.min(minAlpha, alpha)
			maxAlpha = maxAlpha == nil and alpha or math.max(maxAlpha, alpha)
			if alpha <= 0.001 then telemetry.sawTransparent = true end
			if alpha > 0.001 and alpha < 0.999 then telemetry.sawPartial = true end
		end
	end
	if minAlpha ~= nil and maxAlpha - minAlpha > 0.001 then telemetry.sawStaggered = true end
	if completed and validCount > 0 then
		telemetry.completedCount = telemetry.completedCount + 1
		telemetry.finalAlphaOne = telemetry.finalAlphaOne or minAlpha >= 0.999
	end
end

return Fade
