-- 在独立 Lua 5.1 环境验证选点、障碍绕行、预算和乘车生命周期，不启动游戏或编译资源。
package.path = "./scripts/?.lua;" .. package.path
local tests = 0

-- 每项验证都给出独立结果，失败直接停止，方便本地复现。
local function Test(name, fn)
	fn()
	tests = tests + 1
	print("PASS " .. name)
end

-- 提供 DST 的基础 Class 构造语义。
function Class(ctor)
	local class = {}
	class.__index = class
	return setmetatable(class, { __call = function(_, ...)
		local self = setmetatable({}, class)
		ctor(self, ...)
		return self
	end })
end

-- 测试坐标只需要公开 x/y/z 字段。
function Vector3(x, y, z) return { x = x, y = y, z = z } end

-- 与模组工具一致：默认只计算水平距离，显式 includeY 时才纳入高度。
function aipDist(a, b, includeY)
	local dx, dy, dz = a.x - b.x, a.y - b.y, a.z - b.z
	return includeY and math.pow(dx * dx + dy * dy + dz * dz, 1 / 3)
		or math.sqrt(dx * dx + dz * dz)
end

-- 兼容没有 math.atan2 的独立 Lua 运行器。
local function Atan2(y, x)
	if math.atan2 ~= nil then return math.atan2(y, x) end
	if x > 0 then return math.atan(y / x) end
	if x < 0 then return math.atan(y / x) + (y >= 0 and math.pi or -math.pi) end
	if y > 0 then return math.pi / 2 end
	if y < 0 then return -math.pi / 2 end
	return 0
end

-- 计算测试实体朝向，供真实矿车驱动器选择和跟随下一端点。
function aipGetAngle(a, b) return math.deg(Atan2(b.z - a.z, b.x - a.x)) end

-- 返回两个测试角度的最小差值。
function aipDiffAngle(a, b) return math.abs((a - b + 180) % 360 - 180) end

-- 固定测试语言且禁用开发输出。
function aipGetModConfig(name) return name == "language" and "chinese" or "disabled" end

-- 离线环境将 AIP 多参数日志拼成一行，保持与游戏控制台的可读输出一致。
function aipPrint(...)
	local values = {...}
	for index, value in ipairs(values) do values[index] = tostring(value) end
	return print(table.concat(values, " "))
end

-- 模拟本测试所需的网络字段。
function net_bool()
	return { set = function(self, value) self.val = value end, value = function(self) return self.val or false end }
end

-- 字符串网络字段支持真实轨道连接组件。
function net_string()
	return { val = "", set = function(self, value) self.val = value end, value = function(self) return self.val end }
end

-- 测试仅记录物理模式，不接触游戏引擎。
function MakeCharacterPhysics(inst) inst.physicsMode, inst.physicsActive = "character", true end

-- 记录幽灵物理模式，供死亡回退验证。
function MakeGhostPhysics(inst) inst.physicsMode, inst.physicsActive = "ghost", true end

-- 临时观光车只需保留可传送的物理接口。
function MakeInventoryPhysics(inst) inst.physicsMode, inst.physicsActive = "inventory", true end

-- 序列化连接端点，保持原连接组件的数据协议。
function aipCommonStr(_, separator, ...) return table.concat({...}, separator) end

STRINGS = { NAMES = {}, CHARACTERS = { GENERIC = { DESCRIBE = {} } } }
TheNet = { IsDedicated = function() return true end }
TheSim = { GetTick = function() return 0 end }
local nextGUID = 0
local tasks = {}
local factories = {}
local spawnFailure = nil
local spawned = {}
local Entity = {}
Entity.__index = Entity

-- 创建带事件、坐标和最小物理接口的测试实体。
local function NewEntity(prefab, x, z, tags)
	nextGUID = nextGUID + 1
	local inst = setmetatable({ prefab = prefab, GUID = nextGUID, x = x or 0, y = 0, z = z or 0,
		components = {}, tags = tags or {}, listeners = {}, valid = true, physicsActive = true }, Entity)
	inst.Transform = {
		GetWorldPosition = function() return inst.x, inst.y, inst.z end,
		SetPosition = function(_, px, py, pz) inst.x, inst.y, inst.z = px, py, pz end,
		GetRotation = function() return inst.rotation or 0 end,
		SetRotation = function(_, rotation) inst.rotation = rotation end,
	}
	inst.Physics = {
		Teleport = function(_, px, py, pz) inst.x, inst.y, inst.z = px, py, pz end,
		Stop = function() inst.motorX, inst.motorY, inst.motorZ = 0, 0, 0 end,
		ClearCollisionMask = function() inst.physicsMode = "none" end,
		SetActive = function(_, active) inst.physicsActive = active end,
		IsActive = function() return inst.physicsActive end,
		SetMotorVel = function(_, x, y, z) inst.motorX, inst.motorY, inst.motorZ = x, y, z end,
		GetMotorVel = function() return inst.motorX or 0, inst.motorY or 0, inst.motorZ or 0 end,
		GetMotorSpeed = function() return math.abs(inst.motorX or 0) end,
		GetVelocity = function() return inst.motorX or 0, inst.motorY or 0, inst.motorZ or 0 end,
	}
	inst.AnimState = setmetatable({}, { __index = function() return function() end end })
	inst.entity = setmetatable({}, { __index = function() return function() end end })
	inst.sg = { currentstate = { name = "idle" }, tags = {},
		GoToState = function(self, state) self.currentstate.name = state self.tags = {} end,
		AddStateTag = function(self, tag) self.tags[tag] = true end }
	return inst
end

-- 查询实体是否仍然存在。
function Entity:IsValid() return self.valid end
-- 查询实体是否处于物品栏等不可见状态。
function Entity:IsInLimbo() return self.limbo == true end
-- 查询实体标签。
function Entity:HasTag(tag) return self.tags[tag] == true end
-- 添加实体标签。
function Entity:AddTag(tag) self.tags[tag] = true end
-- 移除实体标签。
function Entity:RemoveTag(tag) self.tags[tag] = nil end
-- 获取坐标副本。
function Entity:GetPosition() return Vector3(self.x, self.y, self.z) end
-- 获取测试障碍的碰撞半径。
function Entity:GetPhysicsRadius() return self.radius or 0 end
-- 记录朝向，使矿车速度向量能在独立测试中推进真实坐标。
function Entity:ForceFacePoint(x, _, z) self.rotation = aipGetAngle(self:GetPosition(), Vector3(x, self.y, z)) end
-- 隐藏临时矿车。
function Entity:Hide() self.hidden = true end
-- 显示普通矿车。
function Entity:Show() self.hidden = false end
-- 注册正在更新的组件，允许乘客观察器与原矿车驱动器同时运行。
function Entity:StartUpdatingComponent(component)
	self.updating = self.updating or {}
	self.updating[component] = true
end
-- 停止指定组件的更新。
function Entity:StopUpdatingComponent(component)
	if self.updating == nil then return end
	self.updating[component] = nil
	if next(self.updating) == nil then self.updating = nil end
end
-- 模拟含船只偏移的原始存档，以检验观光存档的修正。
function Entity:GetSaveRecord() return { x = self.x, y = self.y, z = self.z, puid = 99, rx = 1, rz = 2 }, { 123 } end

-- 事件绑定到来源实体，与 DST 的跨实体监听保持一致。
function Entity:ListenForEvent(event, fn, source)
	source = source or self
	source.listeners[event] = source.listeners[event] or {}
	table.insert(source.listeners[event], { owner = self, fn = fn })
end

-- 只移除调用者自己的回调。
function Entity:RemoveEventCallback(event, fn, source)
	local list = (source or self).listeners[event] or {}
	for i = #list, 1, -1 do
		if list[i].owner == self and list[i].fn == fn then table.remove(list, i) end
	end
end

-- 分发前复制监听列表，允许回调在执行过程中退订自己。
function Entity:PushEvent(event, data)
	local callbacks = {}
	for _, entry in ipairs(self.listeners[event] or {}) do table.insert(callbacks, entry.fn) end
	for _, fn in ipairs(callbacks) do fn(self, data) end
end

-- 保存延迟任务，测试控制其触发时机。
function Entity:DoTaskInTime(delay, fn)
	local task = { delay = delay, fn = fn, Cancel = function(self) self.cancelled = true end }
	table.insert(tasks, task)
	return task
end

-- 模拟实体移除时的组件清理。
function Entity:Remove()
	if not self.valid then return end
	self:PushEvent("onremove")
	for _, component in pairs(self.components) do
		if component.OnRemoveEntity ~= nil then component:OnRemoveEntity() end
	end
	self.valid = false
end

-- 直接加载真实组件实现。
function Entity:AddComponent(name)
	self.components[name] = require("components/" .. name)(self)
end

-- 注册真实临时轨道 prefab，测试其持久化标记及连接初始化。
function Asset(...) return {...} end
-- 记录 prefab 构造器。
function Prefab(name, fn) factories[name] = fn return fn end
-- 提供 prefab 创建所需的引擎实体。
function CreateEntity() return NewEntity("pending") end
ANIM_ORIENTATION = { OnGround = 1 }

-- 模拟生成失败，验证部分铺轨后的回滚行为。
function SpawnPrefab(name)
	if name == spawnFailure then return nil end
	local inst = factories[name] ~= nil and factories[name]() or NewEntity(name)
	inst.prefab = name
	table.insert(spawned, inst)
	return inst
end

-- 只执行下一帧任务，超时任务由具体测试手动触发。
local function FlushBuild()
	for _ = 1, 100 do
		local pending = tasks
		tasks = {}
		local executed = false
		for _, task in ipairs(pending) do
			if not task.cancelled then
				if task.delay == 0 then task.fn() executed = true else table.insert(tasks, task) end
			end
		end
		if not executed then return end
	end
	error("Unbounded build tasks")
end

-- 统计流式轨道表中仍有效的端点或连接实体。
local function CountValid(entities)
	local count = 0
	for _, entity in pairs(entities or {}) do
		if entity:IsValid() then count = count + 1 end
	end
	return count
end

local landMap = {
	IsPassableAtPoint = function() return true end,
	IsOceanTileAtPoint = function() return false end,
}
TheWorld = NewEntity("world")
TheWorld.ismastersim, TheWorld.Map = true, landMap
Ents = {}
require("prefabs/aip_pig_king_train_orbit")
local route = require("aip_pig_king_train_route")
local track = require("aip_pig_king_train_track")
local config = require("configurations/aip_pig_king_train")
local Driver = require("components/aipc_orbit_driver")
local Passenger = require("components/aipc_pig_king_train_passenger")
local Runtime = require("aip_pig_king_train_runtime")

-- 构造六处互不重叠的地标，固定随机抽取顺序便于验证降级和不足配额。
local function WorldFixture()
	local king = NewEntity("pigking", 0, 0)
	local spots = {
		NewEntity("moonbase", 100, 0), NewEntity("dragonfly_spawner", 200, 100),
		NewEntity("walrus_camp", 100, 200), NewEntity("resurrectionstone", -100, 200),
		NewEntity("charlie_stage_post", -200, 100), NewEntity("terrariumchest", -100, 0),
	}
	Ents = { king }
	for _, spot in ipairs(spots) do table.insert(Ents, spot) end
	return king, spots
end

-- 创建真实矿车及观光组件，只有游戏引擎 API 使用替身。
local function PlayerFixture(x)
	local player = NewEntity("wilson", x or 10, 0, { player = true })
	player.components.health = { currenthealth = 40, IsDead = function(self) return player.dead == true or self.currenthealth <= 0 end,
		SetCurrentHealth = function(self, value) self.currenthealth = value end,
		SetVal = function(self, value)
			self.currenthealth = math.max(0, value)
			if self.currenthealth == 0 then player:PushEvent("death") end
		end,
		DoDelta = function(self, delta) self:SetVal(self.currenthealth + delta) end,
		SetPercent = function(self, percent) self:SetVal(percent * 100) end,
		ForceKill = function(self) self:DoDelta(-self.currenthealth) end }
	player.components.hunger = { current = 40, SetCurrent = function(self, value) self.current = math.max(0, value) end,
		DoDelta = function(self, delta) self:SetCurrent(self.current + delta) end,
		SetPercent = function(self, percent) self:SetCurrent(percent * 100) end }
	player.components.sanity = { current = 40, DoDelta = function(self, delta) self.current = math.max(0, self.current + delta) end,
		SetPercent = function(self, percent) self:DoDelta(percent * 100 - self.current) end }
	player.components.talker = { Say = function(_, message) player.message = message end }
	player.components.inventory = { GiveItem = function(_, item) player.refunds = (player.refunds or 0) + 1 item:Remove() end }
	player.components.drownable = { enabled = true }
	player.components.aipc_orbit_driver_client = { isDriving = net_bool() }
	player.components.aipc_orbit_driver = Driver(player)
	player.components.aipc_pig_king_train_passenger = Passenger(player)
	return player
end

-- 先运行原矿车组件，再按其运动向量推进物理，最后由观光组件观察端点和高度。
local function StepRide(player, dt)
	local driver = player.components.aipc_orbit_driver
	local passenger = player.components.aipc_pig_king_train_passenger
	if player.updating ~= nil and player.updating[driver] then driver:OnUpdate(dt) end
	if player.Physics:IsActive() then
		local speed, verticalSpeed = player.motorX or 0, player.motorY or 0
		local angle = math.rad(player.rotation or 0)
		player.x = player.x + math.cos(angle) * speed * dt
		player.z = player.z + math.sin(angle) * speed * dt
		player.y = player.y + verticalSpeed * dt
	end
	if player.updating ~= nil and player.updating[passenger] then passenger:OnUpdate(dt) end
end

Test("complete quotas and finite retries", function()
	local king = WorldFixture()
	local result = assert(route.Create(king, { randomFn = function() return 1 end }))
	assert(result.spotCount == 6 and #result.nodes == 8 and #result.legs == 7)
	for _, priority in ipairs(route.PRIORITIES) do
		assert(#result.selectedByPriority[priority] == 2)
		assert(result.selectionStats[priority].attempts <= 12)
	end
	Ents = { king }
	local missing, err = route.Create(king)
	assert(missing == nil and err.code == "not_enough_spots" and err.priority == "P0")
end)

Test("failed scenic spots can be excluded from the next selection", function()
	local king = WorldFixture()
	table.insert(Ents, NewEntity("cave_entrance", 150, -100))
	local result = assert(route.Create(king, {
		randomFn = function() return 1 end,
		excludedSpotIds = { resurrectionstone = true },
	}))
	for _, stop in ipairs(result.stops) do assert(stop.id ~= "resurrectionstone") end
	assert(#result.selectedByPriority.P1 == 2)
end)

Test("retry selection retains valid stops and fills the missing quota with the nearest candidate", function()
	local king = WorldFixture()
	table.insert(Ents, NewEntity("stagehand", 20, 0))
	local result = assert(route.Create(king, {
		randomFn = function() return 1 end,
		excludedSpotIds = { dragonfly_arena = true },
		preferredSpotIds = {
			moonbase = true, walrus_camp = true, resurrectionstone = true,
			charlie_stage = true, terrarium = true,
		},
		preferNearest = true,
	}))
	local selected = {}
	for _, stop in ipairs(result.stops) do selected[stop.id] = true end
	for _, id in ipairs({ "moonbase", "walrus_camp", "resurrectionstone", "charlie_stage", "terrarium" }) do
		assert(selected[id], "preferred stop was not retained: " .. id)
	end
	assert(selected.stagehand and not selected.dragonfly_arena, "nearest replacement was not selected")
end)

Test("preferred anchors and nearby stage exclusion", function()
	local king = WorldFixture()
	table.insert(Ents, NewEntity("lava_pond", 1, 1))
	table.insert(Ents, NewEntity("statueharp_hedgespawner", -199, 100))
	local result = assert(route.Create(king, { randomFn = function() return 1 end }))
	assert(result.selectedByPriority.P0[2].prefab == "dragonfly_spawner")
	assert(result.selectedByPriority.P2[2].id == "terrarium")
	king.x = 0 / 0
	local invalid, err = route.Create(king)
	assert(invalid == nil and err.code == "invalid_start")
end)

Test("held and moved eyebones are not landmarks", function()
	local king = WorldFixture()
	Ents[#Ents] = nil
	local eye = NewEntity("chester_eyebone", -100, 0)
	eye.components.inventoryitem = { GetGrandOwner = function() return king end }
	table.insert(Ents, eye)
	assert(route.Create(king) == nil)
	eye.components.inventoryitem = nil
	eye._aip_train_moved = true
	assert(route.Create(king) == nil)
end)

Test("safe viewpoints and closed ground-first track with limited elevation", function()
	local king = WorldFixture()
	local result = assert(route.Create(king))
	local plan = assert(track.Plan(result))
	assert(plan.points[1].y == 0 and plan.points[#plan.points].y == 0)
	assert(aipDist(plan.points[1], plan.points[#plan.points]) == 0)
	for index = 2, #plan.points do
		assert(aipDist(plan.points[index - 1], plan.points[index]) > 0.01,
			"original driver cannot traverse a vertical-only segment")
	end
	local stops, scenicSegments, groundArcs, elevatedArcs = 0, 0, 0, 0
	for index, stop in pairs(plan.stops) do
		stops = stops + 1
		assert(aipDist(plan.points[index], stop.spot.point) >= 10 and stop.canPark == false)
	end
	for _ in pairs(plan.scenicSegments) do scenicSegments = scenicSegments + 1 end
	assert(#plan.arcs == 6 and scenicSegments == 6 * config.SCENIC_ARC_SEGMENTS)
	for _, arc in ipairs(plan.arcs) do
		assert(arc.sweepDegrees == 270 and #arc.points == config.SCENIC_ARC_SEGMENTS + 1)
		assert(arc.heightMode ~= nil and arc.height ~= nil)
		if arc.elevated then elevatedArcs = elevatedArcs + 1 else groundArcs = groundArcs + 1 end
		local measuredSweep = 0
		for _, point in ipairs(arc.points) do
			assert(math.abs(aipDist(point, arc.center) - arc.radius) < 0.01)
			assert(math.abs(point.y - arc.height) < 0.01)
		end
		for index = 2, #arc.points do
			local previous, point = arc.points[index - 1], arc.points[index]
			local ax, az = previous.x - arc.center.x, previous.z - arc.center.z
			local bx, bz = point.x - arc.center.x, point.z - arc.center.z
			measuredSweep = measuredSweep + math.abs(Atan2(ax * bz - az * bx, ax * bx + az * bz))
		end
		assert(math.abs(math.deg(measuredSweep) - 270) < 0.01)
	end
	assert(stops == 6 and plan.visualCount <= config.MAX_VISUALS)
	assert(groundArcs > 0 and elevatedArcs > 0, "fixture did not exercise both height modes")
	assert(plan.groundDistance > plan.elevatedDistance and plan.heightTransitions > 0,
		"land route was not primarily kept on the ground")
	for index = 2, #plan.points do
		assert(aipDist(plan.points[index - 1], plan.points[index]) <= config.MAX_SEGMENT + 0.01,
			"track endpoint spacing exceeded the configured limit")
		if math.abs(plan.points[index - 1].y - plan.points[index].y) > 0.01 then
			assert(aipDist(plan.points[index - 1], plan.points[index])
				<= config.ELEVATION_RAMP_DISTANCE + 0.01, "elevation ramp is too long")
		end
	end
	assert(plan.totalDistance > result.totalDistance * 0.5)
end)

Test("track streams in a bounded window instead of prebuilding the full route", function()
	assert(config.TRACK_LOOKAHEAD >= 4, "too few upcoming segments are visible")
	local king = WorldFixture()
	local runtime, player = Runtime(king), PlayerFixture()
	assert(runtime:StartTrain(player, true))
	local run = player._aip_train_run
	FlushBuild()
	assert(run.boarded and #run.plan.points > config.TRACK_LOOKAHEAD + 1)
	assert(CountValid(run.points) == config.TRACK_LOOKAHEAD + 1)
	assert(CountValid(run.links) == config.TRACK_LOOKAHEAD)
	assert(run.points[#run.plan.points] == nil, "full route was created before departure")
	for _ = 1, 3000 do
		if run.ended or run.pointIndex >= 5 then break end
		StepRide(player, 1 / 30)
	end
	assert(not run.ended and run.pointIndex >= 5)
	assert(not run.points[1]:IsValid() and not run.links[1]:IsValid(), "passed track was not retired")
	assert(CountValid(run.points) <= config.TRACK_LOOKAHEAD + config.TRACK_RETAIN_BEHIND + 1)
	assert(CountValid(run.links) <= config.TRACK_LOOKAHEAD + config.TRACK_RETAIN_BEHIND)
	assert(run.points[#run.plan.points] == nil, "distant route became visible too early")
	local driver = player.components.aipc_orbit_driver
	run.links[run.pointIndex]:Remove()
	assert(#driver.routeProvider(driver.orbitPoint, nil) == 0,
		"route provider continued without a visible link")
	player.components.aipc_pig_king_train_passenger:Finish("test_finished")
end)

Test("dense landmarks use the bounded extended viewpoint search", function()
	local king = WorldFixture()
	local result = assert(route.Create(king, { randomFn = function() return 1 end }))
	local center
	for _, stop in ipairs(result.stops) do
		if stop.id == "resurrectionstone" then center = stop.point end
	end
	assert(center ~= nil)
	local map = {
		IsPassableAtPoint = function(_, x, _, z)
			return (x - center.x)^2 + (z - center.z)^2 >= 18^2
		end,
		IsOceanTileAtPoint = function() return false end,
	}
	local plan = assert(track.Plan(result, { map = map }))
	local found = false
	for _, view in ipairs(plan.views) do
		if view.stop ~= nil and view.stop.id == "resurrectionstone" then
			found = true
			assert(aipDist(view.point, center) >= 18)
		end
	end
	assert(found)
end)

Test("impossible rough routes are rejected before the world obstacle scan", function()
	local king = WorldFixture()
	local result = assert(route.Create(king, { randomFn = function() return 1 end }))
	result.totalDistance = 10000
	local missing, err = track.Plan(result, {
		map = { IsPassableAtPoint = function() error("map should not be scanned") end },
	})
	assert(missing == nil and err.code == "rough_route_too_long")
end)

Test("dangerous obstacles cause detours without entity changes", function()
	local king = WorldFixture()
	local result = assert(route.Create(king, { randomFn = function() return 1 end }))
	local initial = assert(track.Plan(result))
	local a, b = initial.points[3], initial.points[4]
	local obstacle = NewEntity("wall", (a.x+b.x)/2, (a.z+b.z)/2, { structure = true, hostile = true })
	obstacle.radius = 4
	table.insert(Ents, obstacle)
	local detour = assert(track.Plan(result))
	assert(obstacle.valid and detour.totalDistance >= initial.totalDistance)
	for i = 2, #detour.points do
		local first, last = detour.points[i-1], detour.points[i]
		for sample = 0, 20 do
			local t = sample / 20
			local x, z = first.x + (last.x-first.x)*t, first.z + (last.z-first.z)*t
			assert((x-obstacle.x)^2+(z-obstacle.z)^2 >= 6^2)
		end
	end
end)

Test("ordinary ground clutter is avoided without forcing the full route elevated", function()
	local king = WorldFixture()
	local result = assert(route.Create(king, { randomFn = function() return 1 end }))
	local initial = assert(track.Plan(result))
	local a, b
	for index = 2, #initial.points do
		local first, last = initial.points[index - 1], initial.points[index]
		if first.y <= config.GROUND_HEIGHT and last.y <= config.GROUND_HEIGHT
			and aipDist(first, last) > 4 then a, b = first, last break end
	end
	assert(a ~= nil, "fixture has no usable ground segment")
	local tree = NewEntity("evergreen", (a.x+b.x)/2, (a.z+b.z)/2, { CHOP_workable = true })
	tree.radius = 2
	table.insert(Ents, tree)
	local detour = assert(track.Plan(result))
	assert(tree.valid and detour.groundDistance > detour.elevatedDistance)
	for index = 2, #detour.points do
		local first, last = detour.points[index - 1], detour.points[index]
		if first.y <= config.GROUND_HEIGHT and last.y <= config.GROUND_HEIGHT then
			for sample = 0, 20 do
				local t = sample / 20
				local x, z = first.x + (last.x-first.x)*t, first.z + (last.z-first.z)*t
				assert((x-tree.x)^2+(z-tree.z)^2 >= 3^2)
			end
		end
	end
end)

Test("ocean enabled with independent distance and visual budgets", function()
	local king = WorldFixture()
	local result = assert(route.Create(king))
	local map = {
		IsPassableAtPoint = function(_, x) return x < 40 end,
		IsOceanTileAtPoint = function(_, x) return x >= 40 end,
	}
	local plan = assert(track.Plan(result, { map = map }))
	assert(plan.oceanDistance > 0 and plan.elevatedDistance > 0)
	assert(track.Plan(result, { map = map, allowOcean = false }) == nil)
	local old = config.MAX_OCEAN_DISTANCE
	config.MAX_OCEAN_DISTANCE = 1
	local missing, err = track.Plan(result, { map = map })
	assert(missing == nil and err.code == "track_budget_exceeded")
	config.MAX_OCEAN_DISTANCE = old
	old = config.MAX_VISUALS
	config.MAX_VISUALS = 1
	assert(track.Plan(result) == nil)
	config.MAX_VISUALS = old
end)

Test("trade wrappers preserve ordinary pig king trades", function()
	local king = WorldFixture()
	local accepted = 0
	king.components.trader = {
		test = function(_, item) return item.prefab == "meat" end,
		onaccept = function() accepted = accepted + 1 end,
		SetAcceptTest = function(self, fn) self.test = fn end,
	}
	Runtime(king)
	local trader = king.components.trader
	assert(trader.test(king, { prefab = "aip_train_ticket" }))
	assert(trader.test(king, { prefab = "meat" }))
	assert(not trader.test(king, { prefab = "twigs" }))
	trader.onaccept(king, nil, { prefab = "aip_train_ticket" })
	trader.onaccept(king, nil, { prefab = "meat" })
	assert(accepted == 1)
end)

Test("automatic round trip, safe save position and state restoration", function()
	local king = WorldFixture()
	local runtime, player = Runtime(king), PlayerFixture()
	assert(runtime:StartTrain(player, true))
	local run = player._aip_train_run
	assert(not run.boarded)
	FlushBuild()
	assert(run.boarded and player.components.drownable.enabled == false,
		run.error ~= nil and (tostring(run.error.code) .. ": " .. tostring(run.error.detail)) or "boarding did not finish")
	local driver = player.components.aipc_orbit_driver
	assert(driver.routeProvider ~= nil and driver.nextOrbitPoint == run.points[2])
	assert(CountValid(run.links) == config.TRACK_LOOKAHEAD
		and CountValid(run.points) == config.TRACK_LOOKAHEAD + 1)
	for _, entity in ipairs(run.entities) do assert(entity.persists == false) end
	local passenger = player.components.aipc_pig_king_train_passenger
	StepRide(player, 1 / 30)
	local record, references = player:GetSaveRecord()
	assert(record.x == run.plan.station.x and record.z == run.plan.station.z)
	assert(record.y == nil and record.puid == nil and references[1] == 123)
	local sawScenicSpeed, sawCruiseAfterArc = false, false
	for _ = 1, 30000 do
		if run.ended then break end
		StepRide(player, 1 / 30)
		if driver.speed == config.SCENIC_SPEED then
			sawScenicSpeed = true
		elseif sawScenicSpeed and driver.speed == config.SPEED then
			sawCruiseAfterArc = true
		end
	end
	assert(run.ended and #run.entities == 0 and player.refunds == nil)
	assert(sawScenicSpeed and sawCruiseAfterArc)
	assert(player.y == 0 and player.components.drownable.enabled == true)
	assert(not player:HasTag("notarget") and not driver:isDriving() and driver.routeProvider == nil)
end)

Test("invalid motor velocity aborts instead of trapping the passenger", function()
	local king = WorldFixture()
	local runtime, player = Runtime(king), PlayerFixture()
	assert(runtime:StartTrain(player, true))
	local run = player._aip_train_run
	FlushBuild()
	player.motorY = math.huge
	player.components.aipc_pig_king_train_passenger:OnUpdate(1 / 30)
	assert(run.ended and run.endReason == "invalid_motion" and run.error.code == "invalid_motion")
	assert(#run.entities == 0 and player.y == 0)
end)

Test("stalled physics aborts within the bounded watchdog timeout", function()
	local king = WorldFixture()
	local runtime, player = Runtime(king), PlayerFixture()
	assert(runtime:StartTrain(player, true))
	local run = player._aip_train_run
	FlushBuild()
	local driver = player.components.aipc_orbit_driver
	local passenger = player.components.aipc_pig_king_train_passenger
	for _ = 1, math.ceil(config.RIDE_STALL_TIMEOUT * 30) + 2 do
		if run.ended then break end
		if player.updating ~= nil and player.updating[driver] then driver:OnUpdate(1 / 30) end
		if player.updating ~= nil and player.updating[passenger] then passenger:OnUpdate(1 / 30) end
	end
	assert(run.ended and run.endReason == "ride_stalled" and run.error.code == "ride_stalled")
	assert(#run.entities == 0 and player.y == 0)
end)

Test("runtime retries a failed viewpoint with a replacement scenic spot", function()
	local king = WorldFixture()
	table.insert(Ents, NewEntity("cave_entrance", 150, -100))
	local originalCreate, originalPlan = route.Create, track.Plan
	local planCalls = 0
	local firstStops
	local ok, err = pcall(function()
		route.Create = function(start, options)
			options.randomFn = function() return 1 end
			return originalCreate(start, options)
		end
		track.Plan = function(routeMap, options)
			planCalls = planCalls + 1
			if planCalls == 1 then
				firstStops = {}
				for _, stop in ipairs(routeMap.stops) do firstStops[stop.id] = true end
				return nil, { code = "no_viewpoint", spot = "resurrectionstone", detail = "fixture" }
			end
			return originalPlan(routeMap, options)
		end
		local runtime, player = Runtime(king), PlayerFixture()
		assert(runtime:StartTrain(player, false))
		assert(planCalls == 2 and player._aip_train_run ~= nil)
		local retained = 0
		for _, stop in ipairs(player._aip_train_run.routeMap.stops) do
			assert(stop.id ~= "resurrectionstone")
			if firstStops[stop.id] then retained = retained + 1 end
		end
		assert(retained == 5, "retry changed more than the failed scenic spot")
		runtime:EndRun(player._aip_train_run, "test_finished")
	end)
	route.Create, track.Plan = originalCreate, originalPlan
	assert(ok, err)
end)

Test("logged world route fits after expanding the six-arc distance budget", function()
	local king = NewEntity("pigking", -106, 170)
	Ents = {
		king,
		NewEntity("dragonfly_spawner", 342.3, 633.4),
		NewEntity("statueglommer", -52, 159),
		NewEntity("multiplayer_portal", -100, 170),
		NewEntity("hermithouse_construction1", 266.3, -113.9),
		NewEntity("walrus_camp", -455.1, 263.4),
		NewEntity("chester_eyebone", -47.2, 224.8),
		NewEntity("balatro_machine", 40, 308),
	}
	local originalCreate, originalPlan = route.Create, track.Plan
	local picks, pickIndex = { 2, 4, 8, 2, 5, 4 }, 0
	local planCalls = 0
	local ok, err = pcall(function()
		route.Create = function(start, options)
			options.randomFn = function(limit)
				pickIndex = pickIndex + 1
				local value = assert(picks[pickIndex], "unexpected random selection")
				assert(value <= limit, "fixture selection outside candidate pool")
				return value
			end
			return originalCreate(start, options)
		end
		track.Plan = function(routeMap, options)
			planCalls = planCalls + 1
			return originalPlan(routeMap, options)
		end
		local runtime, player = Runtime(king), PlayerFixture()
		assert(runtime:StartTrain(player, false))
		local run = assert(player._aip_train_run)
		assert(planCalls == 1)
		local selected = {}
		for _, stop in ipairs(run.routeMap.stops) do
			selected[stop.id] = true
		end
		assert(selected.dragonfly_arena and not selected.portal)
		assert(run.plan.totalDistance <= config.MAX_DISTANCE)
		runtime:EndRun(run, "test_finished")
	end)
	route.Create, track.Plan = originalCreate, originalPlan
	assert(ok, err)
end)

Test("exhausted planning retries fail normally and refund once", function()
	local king = WorldFixture()
	local fixedRoute = assert(route.Create(king, { randomFn = function() return 1 end }))
	local originalCreate, originalPlan = route.Create, track.Plan
	local planCalls = 0
	local ok, err = pcall(function()
		route.Create = function() return fixedRoute end
		track.Plan = function()
			planCalls = planCalls + 1
			return nil, { code = "track_budget_exceeded", detail = "fixture" }
		end
		local runtime, player = Runtime(king), PlayerFixture()
		local started, routeError = runtime:StartTrain(player, true)
		assert(not started and routeError.code == "track_budget_exceeded")
		assert(planCalls == config.MAX_PLAN_ATTEMPTS)
		assert(player._aip_train_run == nil and player.refunds == 1)
	end)
	route.Create, track.Plan = originalCreate, originalPlan
	assert(ok, err)
end)

Test("partial spawn failure refunds once and cleans all owned entities", function()
	local king = WorldFixture()
	local runtime, player = Runtime(king), PlayerFixture()
	assert(runtime:StartTrain(player, true))
	local run = player._aip_train_run
	spawnFailure = "aip_pig_king_train_link"
	FlushBuild()
	spawnFailure = nil
	assert(run.ended and #run.entities == 0 and player.refunds == 1)
	runtime:EndRun(run, "repeat")
	assert(player.refunds == 1)
end)

Test("concurrent tours and permanent tracks remain isolated", function()
	local king = WorldFixture()
	local runtime, first, second = Runtime(king), PlayerFixture(), PlayerFixture(11)
	local permanent = NewEntity("aip_glass_orbit_point")
	assert(runtime:StartTrain(first, true) and runtime:StartTrain(second, true))
	FlushBuild()
	local firstRun, secondRun = first._aip_train_run, second._aip_train_run
	assert(firstRun.id ~= secondRun.id)
	first.components.aipc_orbit_driver:DriveTo(0, 0, true)
	assert(firstRun.ended and not secondRun.ended and permanent:IsValid())
	assert(first.components.aipc_orbit_driver.routeProvider == nil
		and second.components.aipc_orbit_driver.routeProvider ~= nil)
	for _, entity in ipairs(secondRun.entities) do assert(entity:IsValid()) end
		second:PushEvent("attacked")
	assert(not secondRun.ended)
	second.components.aipc_orbit_driver:DriveTo(0, 0, true)
	assert(secondRun.ended)
end)

Test("disconnect, migration, death and station removal clean up", function()
	for _, reason in ipairs({ "disconnect", "migration", "death", "station" }) do
		local king = WorldFixture()
		local runtime, player = Runtime(king), PlayerFixture()
		assert(runtime:StartTrain(player, true))
		FlushBuild()
		local run = player._aip_train_run
		if reason == "disconnect" then TheWorld:PushEvent("ms_playerdespawn", player)
		elseif reason == "migration" then TheWorld:PushEvent("ms_playerdespawnandmigrate", { player = player })
		elseif reason == "death" then player.dead = true player:PushEvent("death")
		else runtime:OnRemoveFromEntity() end
		assert(run.ended and #run.entities == 0 and player.y == 0)
	end
end)

Test("pre-existing protection survives a cancelled trip", function()
	local king = WorldFixture()
	local runtime, player = Runtime(king), PlayerFixture()
	player:AddTag("notarget")
	player.components.drownable.enabled = false
	assert(runtime:StartTrain(player, true))
	FlushBuild()
	player.components.aipc_pig_king_train_passenger:Finish("interrupted")
	assert(player:HasTag("notarget") and player.components.drownable.enabled == false)
end)

Test("planning exceptions refund without creating a run", function()
	local king = WorldFixture()
	local runtime, player = Runtime(king), PlayerFixture()
	TheWorld.Map = { IsPassableAtPoint = function() error("map unavailable") end }
	local ok, err = runtime:StartTrain(player, true)
	TheWorld.Map = landMap
	assert(not ok and err.code == "track_plan_failed" and player.refunds == 1)
	assert(player._aip_train_run == nil)
end)

Test("return station is rechecked after the world changes", function()
	local king = WorldFixture()
	local runtime, player = Runtime(king), PlayerFixture()
	assert(runtime:StartTrain(player, true))
	FlushBuild()
	local run = player._aip_train_run
	local fire = NewEntity("fire", 0, 0, { fire = true })
	fire.radius = 18
	table.insert(Ents, fire)
	player.components.aipc_pig_king_train_passenger:Finish("interrupted")
	assert(player.x^2 + player.z^2 > 20^2 and player.y == 0)
end)

Test("duplicate camera notifications preserve the original view", function()
	local king = WorldFixture()
	local runtime, player = Runtime(king), PlayerFixture()
	ThePlayer = player
	TheNet.IsDedicated = function() return false end
	TheCamera = { _aipFlyModes = { driver = false }, SetFlyView = function(self, active, mode) self._aipFlyModes[mode] = active end }
	assert(runtime:StartTrain(player, true))
	-- 该测试只关注镜头，将专服模式保留到轨道绘制结束。
	TheNet.IsDedicated = function() return true end
	FlushBuild()
	TheNet.IsDedicated = function() return false end
	player:PushEvent("aip_train_passenger_dirty")
	player:PushEvent("aip_train_passenger_dirty")
	assert(TheCamera._aipFlyModes.driver == true)
	player.components.aipc_pig_king_train_passenger:Finish("interrupted")
	assert(TheCamera._aipFlyModes.driver == false)
	ThePlayer = nil
	TheNet.IsDedicated = function() return true end
end)

local driverCamera = require("aip_driver_camera")

Test("third-person mouse camera maps the full screen to view offsets", function()
	local width = 1000
	assert(driverCamera.GetMouseTargetOffset(0, width) == 75)
	assert(driverCamera.GetMouseTargetOffset(250, width) == 37.5)
	assert(math.abs(driverCamera.GetMouseTargetOffset(499, width) - 0.15) < 0.001)
	assert(driverCamera.GetMouseTargetOffset(500, width) == 0)
	assert(math.abs(driverCamera.GetMouseTargetOffset(501, width) + 0.15) < 0.001)
	assert(driverCamera.GetMouseTargetOffset(750, width) == -37.5)
	assert(driverCamera.GetMouseTargetOffset(width, width) == -75)
end)

Test("third-person mouse offset is instant while track heading state remains smooth", function()
	local camera = {
		heading = 350,
		headingtarget = 34,
		headingdelta = 1,
		lastheadingdelta = 2,
		Apply = function(self) self.appliedHeading = self.heading end,
	}
	local heading, baseHeading = driverCamera.ApplyHeadingOffset(camera, 75)
	assert(math.abs(heading - 65) < 0.001 and camera.appliedHeading == heading)
	assert(baseHeading == 350 and camera.heading == 350 and camera.headingtarget == 34)
	assert(camera.headingdelta == 1 and camera.lastheadingdelta == 2)
	camera.heading = 355
	heading, baseHeading = driverCamera.ApplyHeadingOffset(camera, 15)
	assert(math.abs(heading - 10) < 0.001 and camera.appliedHeading == heading)
	assert(baseHeading == 355 and camera.heading == 355 and camera.headingtarget == 34)
end)

Test("third-person mouse camera maps full height and applies pitch without delay", function()
	local height = 1000
	assert(driverCamera.GetMouseTargetPitch(0, height) == 42)
	assert(driverCamera.GetMouseTargetPitch(250, height) == 36)
	assert(driverCamera.GetMouseTargetPitch(499, height) > 30)
	assert(driverCamera.GetMouseTargetPitch(500, height) == 30)
	assert(driverCamera.GetMouseTargetPitch(501, height) < 30)
	assert(driverCamera.GetMouseTargetPitch(750, height) == 24)
	assert(driverCamera.GetMouseTargetPitch(height, height) == 18)
	assert(driverCamera.GetMouseTargetPitch(height, height) == 18)
	assert(driverCamera.GetMouseTargetPitch(0, height) == 42)
end)

Test("attacks, sink callbacks and displaced state do not eject the passenger", function()
	local king = WorldFixture()
	local runtime, player = Runtime(king), PlayerFixture()
	assert(runtime:StartTrain(player, true))
	FlushBuild()
	local run, passenger = player._aip_train_run, player.components.aipc_pig_king_train_passenger
	for _ = 1, 30 do StepRide(player, 1 / 30) end
	player.y = player.y - 0.2
	player.sg:GoToState("hit")
	player:PushEvent("attacked", { damage = 0 })
	player:PushEvent("onsink")
	for _ = 1, 30 do StepRide(player, 1 / 30) end
	assert(not run.ended and player.sg.currentstate.name == "aip_drive"
		and math.abs(player.y - run.position.y) < 0.25)
	assert(player.Physics:IsActive() and math.abs(player.motorX or 0) > 0 and player.sg.tags.nointerrupt)
	player.components.aipc_orbit_driver:DriveTo(0, 0, true)
	assert(run.ended and run.endReason == "cancelled" and player.Physics:IsActive())
end)

Test("vitals decrease, recover and keep a floor until exit", function()
	local king = WorldFixture()
	local runtime, player = Runtime(king), PlayerFixture()
	assert(runtime:StartTrain(player, true))
	FlushBuild()
	for _, name in ipairs({ "health", "hunger", "sanity" }) do
		local component, field = player.components[name], name == "health" and "currenthealth" or "current"
		component:DoDelta(-10)
		assert(component[field] == 30)
		component:SetPercent(0)
		assert(component[field] == 1)
		component:DoDelta(9)
		assert(component[field] == 10)
	end
	local run = player._aip_train_run
	player.components.health:ForceKill()
	assert(run.ended and run.endReason == "death" and player.components.health.currenthealth == 0)
	player.components.hunger:SetPercent(0)
	assert(player.components.hunger.current == 0)
end)

Test("development test modules are disabled outside dev mode", function()
	assert(next(require("dev/aip_pig_king_train_tests")) == nil)
	assert(next(require("dev/aip_pig_king_train_scenarios")) == nil)
	package.loaded["dev/aip_pig_king_train_tests"] = nil
	package.loaded["dev/aip_pig_king_train_scenarios"] = nil
end)

Test("half-finished boarding clears the original driver's car reference", function()
	local king = WorldFixture()
	local runtime, player = Runtime(king), PlayerFixture()
	player.sg.GoToState = function() error("stategraph unavailable during boarding") end
	assert(runtime:StartTrain(player, true))
	local run = player._aip_train_run
	FlushBuild()
	assert(run.ended and player.refunds == 1)
	assert(player.components.aipc_orbit_driver.minecar == nil)
	assert(player.components.aipc_orbit_driver.routeProvider == nil)
	assert(player.components.aipc_pig_king_train_passenger.run == nil)
	assert(player.components.drownable.enabled == true)
end)

Test("partial vital protection installation rolls back all wrappers", function()
	local king = WorldFixture()
	local runtime, player = Runtime(king), PlayerFixture()
	local setter = player.components.health.SetVal
	player.components.sanity.DoDelta = function() error("sanity component unavailable") end
	assert(runtime:StartTrain(player, true))
	local run = player._aip_train_run
	FlushBuild()
	assert(run.ended and player.refunds == 1)
	assert(player.components.health.SetVal == setter)
	assert(player.components.aipc_orbit_driver.minecar == nil)
end)

local originalConfig = aipGetModConfig
-- 以下仅在独立测试环境开启开发入口，不改变游戏的实际配置。
aipGetModConfig = function(name) return name == "dev_mode" and "enabled" or originalConfig(name) end
local devTests = require("dev/aip_pig_king_train_tests")
local devScenarios = require("dev/aip_pig_king_train_scenarios")

Test("pig village quests fill daily without same-day replacement", devScenarios.PigVillageDailyFill)
Test("pig village delivery restores pig behavior and wraps rewards", devScenarios.PigVillageDelivery)
Test("train ticket fragments merge once per frame in groups of three", devScenarios.TrainTicketFragmentMerge)

-- 推进静态与模拟时间；模拟暂停后仍执行报告任务，以验证不会漏掉后续报告批次。
local function ExerciseDevRunner(hasKing)
	WorldFixture()
	local king = Ents[1]
	king.components.aipc_pig_king_train = Runtime(king)
	if not hasKing then Ents = {} end
	local player = PlayerFixture()
	local staticTasks, now, paused, outputs = {}, 0, false, {}
	local oldStatic, oldPaused, oldPrint, oldSetPause, oldPauser, oldCameraProber = TheWorld.DoStaticTaskInTime,
		TheNet.IsServerPaused, print, SetServerPaused, devTests.pauser, devTests.cameraProber
	TheWorld.DoStaticTaskInTime = function(_, delay, fn)
		local task = { due = now + delay, fn = fn, Cancel = function(self) self.cancelled = true end }
		table.insert(staticTasks, task)
		return task
	end
	TheNet.IsServerPaused = function() return paused end
	SetServerPaused = function(value) paused = value end
	devTests.pauser = function()
		assert(outputs[#outputs]:find("回到 Codex", 1, true), "paused before the final report batch")
		SetServerPaused(true)
		return true
	end
	devTests.cameraProber = function(doer, sessionGeneration)
		assert(devTests.CameraProbeResult(doer, sessionGeneration, true,
			"yawLeft=75.0,yawRight=-75.0,trackLerp=true,offsetInstant=true,pitch=18.0/30.0/42.0,nearCenter=-1.5"))
		return true
	end
	print = function(chunk) table.insert(outputs, chunk) end
	TheWorld._aipTrainLastTestReport = nil
	local ok, err = pcall(function()
		assert(devTests.Start(player))
		assert(devTests.Start(player), "repeated ticket use did not restart the active test")
		local restartedAfterReport = false
		for _ = 1, 1600 do
			now = now + 0.5
			FlushBuild()
			if not paused and player.updating ~= nil then
				for _ = 1, 15 do StepRide(player, 1 / 30) end
			end
			local pending = staticTasks
			staticTasks = {}
			for _, task in ipairs(pending) do
				if not task.cancelled then
					if task.due <= now then task.fn() else table.insert(staticTasks, task) end
				end
			end
			if not restartedAfterReport and not paused and TheWorld._aipTrainLastTestReport ~= nil then
				restartedAfterReport = true
				assert(devTests.Start(player), "ticket did not restart while the old report was pending")
				assert(TheWorld._aipTrainLastTestReport == nil, "new session kept the stale report")
			end
			if paused and #staticTasks == 0 then break end
		end
		local report = assert(TheWorld._aipTrainLastTestReport, "report missing")
		assert(restartedAfterReport, "report-generation restart path was not exercised")
		assert(paused and report.success == hasKing, string.format(
			"%s; paused=%s success=%s expected=%s", tostring(report.detail),
			tostring(paused), tostring(report.success), tostring(hasKing)))
		assert(player._aip_train_run == nil)
		assert(#outputs > 1, "report was not batched")
		for _, chunk in ipairs(outputs) do
			local _, count = chunk:gsub("\n", "")
			assert(count < 3, "too many report lines in one batch")
		end
		assert(outputs[#outputs]:find("回到 Codex", 1, true), "last batch was lost while paused")
	end)
	TheWorld.DoStaticTaskInTime, TheNet.IsServerPaused, print, SetServerPaused, devTests.pauser,
		devTests.cameraProber = oldStatic, oldPaused, oldPrint, oldSetPause, oldPauser, oldCameraProber
	assert(ok, err)
end

Test("dev coupon suite succeeds, pauses and emits all report batches", function() ExerciseDevRunner(true) end)
Test("dev coupon failure also pauses and emits all report batches", function() ExerciseDevRunner(false) end)
aipGetModConfig = originalConfig

Test("client camera probe works in the restricted mod environment", function()
	local oldAipRPC, oldCamera, oldConfig = aipRPC, TheCamera, aipGetModConfig
	local oldReporter, oldPauser, oldCameraProber = devTests.reporter, devTests.pauser, devTests.cameraProber
	local clientHandlers, result = {}, nil
	TheCamera = { SetFlyView = function() end }
	aipGetModConfig = function(name) return name == "dev_mode" and "enabled" or oldConfig(name) end
	aipRPC = function(name, sessionGeneration, success, detail)
		result = { name, sessionGeneration, success, detail }
	end
	local ok, err = pcall(function()
		local modEnvironment = {
			GLOBAL = _G,
			PrefabFiles = {},
			modname = "aip_test",
			AddClientModRPCHandler = function(_, name, fn) clientHandlers[name] = fn end,
			AddModRPCHandler = function() end,
			AddPlayerPostInit = function() end,
			pairs = pairs,
			ipairs = ipairs,
			print = print,
			math = math,
			table = table,
			type = type,
			string = string,
			tostring = tostring,
			require = require,
			Class = Class,
		}
		local chunk = assert(loadfile("scripts/dev/aip_pig_king_train_hook.lua", "t", modEnvironment))
		chunk()
		assert(clientHandlers.aipPigTrainTestCameraProbe ~= nil)
		clientHandlers.aipPigTrainTestCameraProbe(7)
		assert(result ~= nil and result[1] == "aipPigTrainTestCameraProbeResult")
		assert(result[2] == 7 and result[3] == "true", tostring(result[4]))
	end)
	aipRPC, TheCamera, aipGetModConfig = oldAipRPC, oldCamera, oldConfig
	devTests.reporter, devTests.pauser, devTests.cameraProber = oldReporter, oldPauser, oldCameraProber
	assert(ok, err)
end)

print(string.format("%d train regression checks passed", tests))
