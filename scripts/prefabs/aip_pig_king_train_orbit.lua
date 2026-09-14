local config = require("configurations/aip_pig_king_train")
local fade = require("aip_pig_king_train_fade")
local devMode = aipGetModConfig("dev_mode") == "enabled"
local assets = {
	Asset("ANIM", "anim/aip_glass_orbit.zip"),
	Asset("ANIM", "anim/aip_glass_orbit_point.zip"),
	Asset("ANIM", "anim/aip_glass_minecar.zip"),
}
local prefabs = { "aip_glass_orbit" }

-- 停止当前连接的淡入任务，避免网络重同步时多个任务同时修改新轨道。
local function StopTrackFade(linker)
	if linker._aip_train_fade_task ~= nil then
		linker._aip_train_fade_task:Cancel()
		linker._aip_train_fade_task = nil
	end
end

-- 让观光连接中的月光轨道从起点到终点依次透明渐入。
local function StartTrackFade(linker)
	if not fade.AppliesToPrefab(linker.inst.prefab) then return end
	local count = #linker.orbits
	if count == 0 then return end
	local elapsed = 0
	for _, orbit in ipairs(linker.orbits) do
		if orbit:IsValid() then orbit.AnimState:SetMultColour(1, 1, 1, 0) end
	end
	if devMode then fade.ObserveTelemetry(TheWorld, linker.orbits, true, false) end
	linker._aip_train_fade_task = linker.inst:DoPeriodicTask(FRAMES, function()
		elapsed = elapsed + FRAMES
		local complete = true
		for index, orbit in ipairs(linker.orbits) do
			local delay = config.TRACK_FADE_STAGGER * (index - 1) / math.max(1, count - 1)
			local alpha = math.min(1, math.max(0,
				(elapsed - delay) / config.TRACK_FADE_DURATION))
			if orbit:IsValid() then orbit.AnimState:SetMultColour(1, 1, 1, alpha) end
			if alpha < 1 then complete = false end
		end
		if devMode then fade.ObserveTelemetry(TheWorld, linker.orbits, false, complete) end
		if complete then StopTrackFade(linker) end
	end)
end

-- 观光专用端点复用月亮轨道贴图，不提供安装矿车、拆卸或自动吸附行为。
local function PointFn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()
	inst.AnimState:SetBank("aip_glass_orbit")
	inst.AnimState:SetBuild("aip_glass_orbit")
	inst.AnimState:PlayAnimation("loop", true)
	inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
	inst:AddTag("NOCLICK")
	inst:AddTag("aip_train_temporary")
	inst.persists = false
	inst.entity:SetPristine()
	return inst
end

-- 观光连接沿用既有客户端绘轨器，不加入永久轨道的端点与连接搜索池。
local function LinkFn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddNetwork()
	inst:AddTag("NOCLICK")
	inst:AddTag("aip_train_temporary")
	inst.persists = false
	inst:AddComponent("aipc_orbit_link")
	local linker = inst.components.aipc_orbit_link
	local originalSyncPath = linker.SyncPath
	local originalUnlink = linker.Unlink
	-- 观光连接销毁或重绘前一并清理淡入任务。
	linker.Unlink = function(self)
		StopTrackFade(self)
		return originalUnlink(self)
	end
	-- 客户端可能先收到唤醒再收到端点字符串，此时等网络数据到齐再绘制。
	linker.SyncPath = function(self)
		if self.pointStr:value() == "" then return end
		local result = originalSyncPath(self)
		StartTrackFade(self)
		return result
	end
	inst.entity:SetPristine()
	return inst
end

-- 专用矿车只供观光动画使用，普通端点不会把它识别为可安装的玻璃矿车。
local function CarFn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()
	MakeInventoryPhysics(inst)
	inst.AnimState:SetBank("aip_glass_minecar")
	inst.AnimState:SetBuild("aip_glass_minecar")
	inst.AnimState:PlayAnimation("idle")
	inst:AddTag("NOCLICK")
	inst:AddTag("aip_train_temporary")
	inst.persists = false
	inst.entity:SetPristine()
	return inst
end

-- 创建跟随观光乘客的大范围冷色灯，实体本身不可见且不参与永久存档。
local function LightFn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddLight()
	inst.entity:AddNetwork()
	inst:AddTag("FX")
	inst:AddTag("NOCLICK")
	inst:AddTag("aip_train_temporary")
	inst:AddTag("aip_train_ride_light")
	inst.Light:SetRadius(config.RIDE_LIGHT_RADIUS)
	inst.Light:SetFalloff(config.RIDE_LIGHT_FALLOFF)
	inst.Light:SetIntensity(config.RIDE_LIGHT_INTENSITY)
	inst.Light:SetColour(config.RIDE_LIGHT_COLOUR[1], config.RIDE_LIGHT_COLOUR[2],
		config.RIDE_LIGHT_COLOUR[3])
	inst.Light:Enable(true)
	inst.persists = false
	inst.entity:SetPristine()
	return inst
end

return Prefab("aip_pig_king_train_point", PointFn, assets),
	Prefab("aip_pig_king_train_link", LinkFn, nil, prefabs),
	Prefab("aip_pig_king_train_car", CarFn, assets),
	Prefab("aip_pig_king_train_light", LightFn)
