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

-- 物品漂浮配置不影响离线行为，只记录 prefab 构造调用成功。
function MakeInventoryFloatable(inst) inst.inventoryFloatable = true end

-- 闹鬼弹射不影响离线行为，只记录 prefab 构造调用成功。
function MakeHauntableLaunch(inst) inst.hauntableLaunch = true end

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
	local animState = { multColour = { 1, 1, 1, 1 } }
	-- 记录动画 bank。
	function animState:SetBank(bank) self.bank = bank end
	-- 记录动画 build。
	function animState:SetBuild(build) self.build = build end
	-- 记录当前播放动画。
	function animState:PlayAnimation(animation) self.animation = animation end
	-- 判断 prefab 是否播放目标动画。
	function animState:IsCurrentAnimation(animation) return self.animation == animation end
	-- 记录实际乘色与透明度。
	function animState:SetMultColour(r, g, b, a) self.multColour = { r, g, b, a } end
	-- 返回当前乘色与透明度。
	function animState:GetMultColour() return self.multColour[1], self.multColour[2], self.multColour[3], self.multColour[4] end
	inst.AnimState = setmetatable(animState, { __index = function() return function() end end })
	local engineEntity = { owner = inst }
	-- 为随身灯提供可回读的 Light 组件替身。
	function engineEntity:AddLight()
		local light = { radius = 0, falloff = 0, intensity = 0, colour = { 1, 1, 1 }, enabled = false }
		function light:SetRadius(value) self.radius = value end
		function light:GetRadius() return self.radius end
		function light:SetFalloff(value) self.falloff = value end
		function light:GetFalloff() return self.falloff end
		function light:SetIntensity(value) self.intensity = value end
		function light:GetIntensity() return self.intensity end
		function light:SetColour(r, g, b) self.colour = { r, g, b } end
		function light:GetColour() return self.colour[1], self.colour[2], self.colour[3] end
		function light:Enable(value) self.enabled = value end
		function light:IsEnabled() return self.enabled end
		inst.Light = light
	end
	-- 按 DST 语义保存引擎实体父级，回读时返回 EntityScript。
	function engineEntity:SetParent(parentEntity)
		self.parent = parentEntity ~= nil and parentEntity.owner or nil
	end
	function engineEntity:GetParent() return self.parent end
	inst.entity = setmetatable(engineEntity, { __index = function() return function() end end })
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

-- 提供真实 Trader:AcceptGift 所需的最小行为，验证物品扣除和事件顺序。
local function MakeTrader(inst)
	local trader = { inst = inst, enabled = true, deleteitemonaccept = true, acceptnontradable = false }
	-- 安装收礼过滤函数。
	function trader:SetAcceptTest(fn) self.test = fn end
	-- 安装收礼成功回调。
	function trader:SetOnAccept(fn) self.onaccept = fn end
	-- 安装拒绝物品回调。
	function trader:SetOnRefuse(fn) self.onrefuse = fn end
	-- 判断替身是否具备接收物品的基础条件。
	function trader:AbleToAccept(item) return self.enabled and item ~= nil end
	-- 按真实过滤函数判断是否需要物品。
	function trader:WantsToAccept(item, giver, count)
		return self.enabled and (self.test == nil or self.test(self.inst, item, giver, count))
	end
	-- 复刻真实扣物、成功回调与 trade 事件顺序。
	function trader:AcceptGift(giver, item, count)
		if not self:AbleToAccept(item, giver, count) then return false end
		if not self:WantsToAccept(item, giver, count) then
			if self.onrefuse ~= nil then self.onrefuse(self.inst, giver, item) end
			return false
		end
		item.components.inventoryitem:RemoveFromOwner(true)
		if self.deleteitemonaccept then item:Remove() end
		if self.onaccept ~= nil then self.onaccept(self.inst, giver, item, count or 1) end
		self.inst:PushEvent("trade", { giver = giver, item = item })
		return true
	end
	return trader
end

-- 加载真实行为组件，并为物品与 Trader 提供等价的轻量离线替身。
function Entity:AddComponent(name)
	if name == "inspectable" or name == "tradable" then
		self.components[name] = { inst = self }
	elseif name == "inventoryitem" then
		self.components[name] = { inst = self,
			SetOnPutInInventoryFn = function(component, fn) component.onputininventoryfn = fn end,
			RemoveFromOwner = function(component) component.removedFromOwner = true end }
	elseif name == "stackable" then
		self.components[name] = { inst = self, stacksize = 1,
			SetStackSize = function(component, size) component.stacksize = size end }
	elseif name == "trader" then
		self.components[name] = MakeTrader(self)
	else
		self.components[name] = require("components/" .. name)(self)
	end
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
TheWorld.state = { phase = "day", isday = true, isdusk = false, isnight = false }
local clockState = { phase = "day", remainingtimeinphase = 37,
	totaltimeinphase = 100, cycles = 12, segs = { day = 10, dusk = 4, night = 2 } }

-- 更新延迟复制后的世界阶段状态。
local function ApplyWorldPhase(phase)
	TheWorld.state.phase = phase
	TheWorld.state.isday = phase == "day"
	TheWorld.state.isdusk = phase == "dusk"
	TheWorld.state.isnight = phase == "night"
end

-- 提供可保存、切换和恢复的世界时钟，并把 world state 模拟成下一帧才同步。
TheWorld.components.clock = {
	OnSave = function()
		return { phase = clockState.phase, remainingtimeinphase = clockState.remainingtimeinphase,
			totaltimeinphase = clockState.totaltimeinphase, cycles = clockState.cycles,
			segs = { day = clockState.segs.day, dusk = clockState.segs.dusk, night = clockState.segs.night } }
	end,
	OnLoad = function(_, data)
		clockState.phase = data.phase or "day"
		clockState.remainingtimeinphase = data.remainingtimeinphase or 37
		clockState.totaltimeinphase = data.totaltimeinphase or 100
		clockState.cycles = data.cycles or 12
		clockState.segs = data.segs or { day = 10, dusk = 4, night = 2 }
		ApplyWorldPhase(clockState.phase)
	end,
	LongUpdate = function() end,
}
TheWorld.net = { components = { clock = TheWorld.components.clock } }
TheWorld:ListenForEvent("ms_setclocksegs", function(_, segs)
	clockState.segs = { day = segs.day, dusk = segs.dusk, night = segs.night }
end)
TheWorld:ListenForEvent("ms_setphase", function(_, phase)
	clockState.phase = phase
	if TheWorld.DoStaticTaskInTime ~= nil then
		TheWorld:DoStaticTaskInTime(0, function() ApplyWorldPhase(phase) end)
	else
		ApplyWorldPhase(phase)
	end
end)
Ents = {}
require("prefabs/aip_pig_king_train_orbit")
require("prefabs/aip_train_ticket")
require("prefabs/aip_train_ticket_fragment")
local route = require("aip_pig_king_train_route")
local track = require("aip_pig_king_train_track")
local config = require("configurations/aip_pig_king_train")
local Driver = require("components/aipc_orbit_driver")
local Passenger = require("components/aipc_pig_king_train_passenger")
local Runtime = require("aip_pig_king_train_runtime")
local fade = require("aip_pig_king_train_fade")
local indicator = require("aip_pig_village_indicator")

Test("train fade telemetry is limited to temporary links and observes real alpha stages", function()
	assert(fade.AppliesToPrefab("aip_pig_king_train_link"))
	assert(not fade.AppliesToPrefab("aip_glass_orbit_link"))
	local telemetry = fade.ResetTelemetry(TheWorld)
	local first, second = NewEntity("orbit"), NewEntity("orbit")
	first.AnimState:SetMultColour(1, 1, 1, 0)
	second.AnimState:SetMultColour(1, 1, 1, 0)
	fade.ObserveTelemetry(TheWorld, { first, second }, true, false)
	first.AnimState:SetMultColour(1, 1, 1, 0.4)
	fade.ObserveTelemetry(TheWorld, { first, second }, false, false)
	first.AnimState:SetMultColour(1, 1, 1, 1)
	second.AnimState:SetMultColour(1, 1, 1, 1)
	fade.ObserveTelemetry(TheWorld, { first, second }, false, true)
	assert(telemetry.startCount == 1 and telemetry.completedCount == 1)
	assert(telemetry.sawTransparent and telemetry.sawPartial and telemetry.sawStaggered
		and telemetry.finalAlphaOne)
end)

Test("pig village quest marker resolves to an existing vanilla question icon", function()
	local data = indicator.Resolve({ prefab = "aip_pig_village_quest_marker" }, nil)
	assert(data.image == "poi_question.tex" and data.atlas == "images/avatars.xml")
	local explicit = { image = "custom.tex", atlas = "custom.xml" }
	assert(indicator.Resolve({ prefab = "aip_pig_village_quest_marker" }, explicit) == explicit)
	assert(indicator.Resolve({ prefab = "pigking" }, nil) == nil)
end)

Test("pig village HUD hook injects the question icon without changing explicit target data", function()
	local oldDedicated = TheNet.IsDedicated
	local callback, received = nil, nil
	TheNet.IsDedicated = function() return false end
	local ok, err = pcall(function()
		local environment = {
			GLOBAL = _G,
			AddClassPostConstruct = function(path, fn)
				assert(path == "screens/playerhud")
				callback = fn
			end,
		}
		local chunk = assert(loadfile("scripts/hooks/aip_pig_village_quest_hook.lua", "t", environment))
		chunk()
		assert(callback ~= nil)
		local hud = { AddTargetIndicator = function(_, target, data) received = { target, data } end }
		callback(hud)
		hud:AddTargetIndicator({ prefab = "aip_pig_village_quest_marker" })
		assert(hud._aipPigVillageIndicatorHook and received[2].image == "poi_question.tex")
		local explicit = { image = "custom.tex" }
		hud:AddTargetIndicator({ prefab = "aip_pig_village_quest_marker" }, explicit)
		assert(received[2] == explicit)
	end)
	TheNet.IsDedicated = oldDedicated
	assert(ok, err)
end)

-- 构造六处互不重叠的地标，固定随机抽取顺序便于验证降级和不足配额。
local function WorldFixture()
	TheWorld.components.clock:OnLoad({ phase = "day" })
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
	assert(groundArcs == 6 and elevatedArcs == 0,
		"safe land landmarks should not be raised only because they are dangerous")
	assert(plan.groundDistance > plan.elevatedDistance and plan.heightTransitions == 0,
		"fully passable land route was not kept on the ground")
	assert(plan.rampDistance == 0 and (plan.modeDistances.ground or 0) > 0
		and (plan.modeDistances["ground-scenic"] or 0) > 0,
		"height mode distance telemetry is incomplete")
	local modeDistance = 0
	for _, distance in pairs(plan.modeDistances) do modeDistance = modeDistance + distance end
	assert(math.abs(modeDistance - plan.totalDistance) < 0.01)
	for index = 2, #plan.points do
		assert(aipDist(plan.points[index - 1], plan.points[index]) <= config.MAX_SEGMENT + 0.01,
			"track endpoint spacing exceeded the configured limit")
		if math.abs(plan.points[index - 1].y - plan.points[index].y) > 0.01 then
			assert(aipDist(plan.points[index - 1], plan.points[index])
				<= config.ELEVATION_RAMP_DISTANCE + 0.01, "elevation ramp is too long")
		end
	end
	assert(plan.totalDistance > result.totalDistance * 0.5)
	local oldMinimumGroundRatio = config.MIN_GROUND_RATIO
	config.MIN_GROUND_RATIO = 1.01
	local missing, ratioError = track.Plan(result)
	config.MIN_GROUND_RATIO = oldMinimumGroundRatio
	assert(missing == nil and ratioError.code == "insufficient_ground_ratio"
		and ratioError.spot ~= nil, "low-ground route did not request a bounded landmark retry")
end)

Test("track streams in a bounded window instead of prebuilding the full route", function()
	assert(config.TRACK_LOOKAHEAD >= 4, "too few upcoming segments are visible")
	local king = WorldFixture()
	local runtime, player = Runtime(king), PlayerFixture()
	assert(runtime:StartTrain(player, true))
	local run = player._aip_train_run
	FlushBuild()
	assert(run.boarded and #run.plan.points > config.TRACK_LOOKAHEAD + 1,
		run.error ~= nil and (tostring(run.error.code) .. ": " .. tostring(run.error.detail))
		or "streaming ride did not board")
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
	assert(detour.blockerDiagnostics.hazardBlockers >= 1,
		"hostile obstacle was not retained as a hard blocker")
	for i = 2, #detour.points do
		local first, last = detour.points[i-1], detour.points[i]
		for sample = 0, 20 do
			local t = sample / 20
			local x, z = first.x + (last.x-first.x)*t, first.z + (last.z-first.z)*t
			assert((x-obstacle.x)^2+(z-obstacle.z)^2 >= 6^2)
		end
	end
end)

Test("ordinary ground clutter follows the tour ghost collision policy", function()
	local king = WorldFixture()
	local result = assert(route.Create(king, { randomFn = function() return 1 end }))
	local initial = assert(track.Plan(result))
	local stationTree = NewEntity("evergreen", initial.station.x, initial.station.z,
		{ CHOP_workable = true })
	stationTree.radius = 2
	local safeStation = assert(track.FindStation(
		track.CreateContext({ entities = { stationTree } }), result.start.point, initial.station))
	assert(aipDist(safeStation, stationTree:GetPosition()) >= 6,
		"strict return station overlapped ignored route clutter")
	local a, b
	for index = 2, #initial.points do
		local first, last = initial.points[index - 1], initial.points[index]
		if first.y <= config.GROUND_HEIGHT and last.y <= config.GROUND_HEIGHT
			and aipDist(first, last) > 4 then a, b = first, last break end
	end
	assert(a ~= nil, "fixture has no usable ground segment")
	local x, z = (a.x+b.x)/2, (a.z+b.z)/2
	local tree = NewEntity("evergreen", x, z, { CHOP_workable = true })
	tree.radius = 2
	local house = NewEntity("pighouse", x, z, { structure = true })
	house.radius = 2
	local item = NewEntity("boulder", x, z)
	item.radius = 2
	local pig = NewEntity("pigman", x, z, { character = true })
	pig.radius = 0.5
	local context = track.CreateContext({ entities = { tree, house, item, pig } })
	assert(context.blockerCount == 4 and context.elevatedBlockerCount == 1
		and context.blockerKinds.character == 1
		and context.ignoredGroundClutterCount == 3,
		"ordinary obstacles did not follow MakeGhostPhysics collision policy")
	table.insert(Ents, tree)
	table.insert(Ents, house)
	table.insert(Ents, item)
	local repeated = assert(track.Plan(result))
	assert(tree.valid and house.valid and item.valid
		and repeated.groundDistance > repeated.elevatedDistance)
	assert(repeated.blockerDiagnostics.ignoredGroundClutter >= 3
		and repeated.blockerDiagnostics.policy == "ghost-physics-aligned")
	assert(#repeated.points == #initial.points,
		"ignored ground clutter changed the deterministic route")
	for index, point in ipairs(repeated.points) do
		local expected = initial.points[index]
		assert(math.abs(point.x - expected.x) < 0.01
			and math.abs(point.y - expected.y) < 0.01
			and math.abs(point.z - expected.z) < 0.01,
			"ignored ground clutter changed a route point")
	end
end)

Test("ocean enabled with independent distance and visual budgets", function()
	local king = WorldFixture()
	local result = assert(route.Create(king))
	-- 本用例只验证海洋与视觉预算，地面比例门槛由独立用例覆盖。
	local oldGroundRatio = config.MIN_GROUND_RATIO
	config.MIN_GROUND_RATIO = 0
	local map = {
		IsPassableAtPoint = function(_, x) return x < 40 end,
		IsOceanTileAtPoint = function(_, x) return x >= 40 end,
	}
	local plan = assert(track.Plan(result, { map = map }))
	assert(plan.oceanDistance > 0 and plan.elevatedDistance > 0)
	local elevatedArcs = 0
	for _, arc in ipairs(plan.arcs) do
		assert(arc.heightReason ~= nil and arc.groundSearch ~= nil)
		if arc.elevated then
			elevatedArcs = elevatedArcs + 1
			assert(arc.heightMode == "elevated-fallback"
				and arc.heightReason == "ground-arc-unavailable")
		end
	end
	assert(elevatedArcs > 0 and (plan.modeDistances["elevated-scenic"] or 0) > 0)
	for pointIndex, stop in pairs(plan.stops) do
		for _, arc in ipairs(plan.arcs) do
			if arc.stop == stop.spot then
				assert(math.abs(plan.points[pointIndex].y - arc.entry.y) < 0.01,
					"short elevation path did not reach the scenic endpoint height")
			end
		end
	end
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
	config.MIN_GROUND_RATIO = oldGroundRatio
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

Test("tour vertical controller adds slope feed-forward without teleporting the player", function()
	WorldFixture()
	local player = PlayerFixture()
	local driver = player.components.aipc_orbit_driver
	local source, target = NewEntity("source", 0, 0), NewEntity("target", 32, 0)
	source.y, target.y = 0, 6
	local car = SpawnPrefab("aip_pig_king_train_car")
	assert(driver:UseMineCar(car, source))
	driver.groundHeight = config.GROUND_HEIGHT
	driver.rideClearance = config.RIDE_CLEARANCE
	driver.verticalGravityCompensation = config.RIDE_VERTICAL_GRAVITY_COMPENSATION
	driver.useVerticalFeedForward = true
	driver:SetRouteProvider(function(current)
		return current == source and { target } or {}
	end)
	driver:DriveFromPoint(0)
	player.x, player.y = 16, (target.y + config.RIDE_CLEARANCE) / 2
	local beforeX, beforeY, beforeZ = player.x, player.y, player.z
	driver:OnUpdate(1 / 30)
	local control = assert(driver.lastVerticalControl)
	assert(player.x == beforeX and player.y == beforeY and player.z == beforeZ,
		"driver update directly rewrote player coordinates")
	assert(control.slope > 0 and control.feedForward > 0
		and math.abs(control.rideY - beforeY) < 0.001
		and control.gravityCompensation == config.RIDE_VERTICAL_GRAVITY_COMPENSATION
		and player.motorY == control.motorY,
		"slope feed-forward was not applied to the original motor vector")
	driver:StopDrive()
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
	assert(driver.useVerticalFeedForward and driver.verticalGravityCompensation
		== config.RIDE_VERTICAL_GRAVITY_COMPENSATION)
	assert(CountValid(run.links) == config.TRACK_LOOKAHEAD
		and CountValid(run.points) == config.TRACK_LOOKAHEAD + 1)
	for _, entity in ipairs(run.entities) do assert(entity.persists == false) end
	local rideLight = assert(run.light)
	assert(rideLight:IsValid() and rideLight.entity:GetParent() == player and rideLight.Light:IsEnabled())
	assert(rideLight.Light:GetRadius() == config.RIDE_LIGHT_RADIUS
		and rideLight.Light:GetFalloff() == config.RIDE_LIGHT_FALLOFF
		and rideLight.Light:GetIntensity() == config.RIDE_LIGHT_INTENSITY)
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
	assert(not rideLight:IsValid(), "ride light survived a completed trip")
	assert(sawScenicSpeed and sawCruiseAfterArc)
	assert(player.y == 0 and player.components.drownable.enabled == true)
	assert(not player:HasTag("notarget") and not driver:isDriving() and driver.routeProvider == nil)
	assert(not driver.useVerticalFeedForward and driver.verticalGravityCompensation == 0)
	local diagnostics = assert(run.rideDiagnostics)
	assert(diagnostics.samples > 0 and #diagnostics.errorBuckets == 5
		and diagnostics.flatDirectionChanges + diagnostics.rampDirectionChanges
		== diagnostics.directionChanges)
	assert(diagnostics.regimes["ground-flat"].samples > 0,
		"vertical regime diagnostics missed the ground ride")
end)

Test("invalid motor velocity aborts instead of trapping the passenger", function()
	local king = WorldFixture()
	local runtime, player = Runtime(king), PlayerFixture()
	assert(runtime:StartTrain(player, true))
	local run = player._aip_train_run
	FlushBuild()
	local rideLight = assert(run.light)
	player.motorY = math.huge
	player.components.aipc_pig_king_train_passenger:OnUpdate(1 / 30)
	assert(run.ended and run.endReason == "invalid_motion" and run.error.code == "invalid_motion")
	assert(#run.entities == 0 and player.y == 0 and not rideLight:IsValid())
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
	-- 在本次真实总站上新增危险物，结束时必须重新选点而不是落回旧站。
	local station = run.plan.station
	local fire = NewEntity("fire", station.x, station.z, { fire = true })
	table.insert(Ents, fire)
	player.components.aipc_pig_king_train_passenger:Finish("interrupted")
	local fireDx, fireDz = player.x - fire.x, player.z - fire.z
	assert(fireDx^2 + fireDz^2 > 10^2 and player.y == 0)
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
	local disabledTests = require("dev/aip_pig_king_train_tests")
	local disabledScenarios = require("dev/aip_pig_king_train_scenarios")
	local disabledE2E = require("dev/aip_pig_king_train_e2e")
	assert(next(disabledTests) == nil)
	assert(next(disabledScenarios) == nil)
	assert(next(disabledE2E) == nil)
	package.loaded["dev/aip_pig_king_train_tests"] = nil
	package.loaded["dev/aip_pig_king_train_scenarios"] = nil
	package.loaded["dev/aip_pig_king_train_e2e"] = nil
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
local devE2E = require("dev/aip_pig_king_train_e2e")

Test("pig village quests fill daily without same-day replacement", devScenarios.PigVillageDailyFill)
Test("pig village delivery restores pig behavior and wraps rewards", devScenarios.PigVillageDelivery)
Test("train ticket fragments merge once per frame in groups of three", devScenarios.TrainTicketFragmentMerge)
Test("ticket prefabs expose icons, stacking and stacked merge hooks", devScenarios.TrainTicketPrefabs)
Test("paid ticket trade consumes once, preserves vanilla trades and refunds correctly", devScenarios.PaidTicketTrade)
Test("runtime retries one failed landmark while retaining valid selections", function()
	WorldFixture()
	devScenarios.RoutePlanningRetry(PlayerFixture())
end)

Test("ticket E2E keeps only the required real player actions", function()
	assert(table.concat(devE2E.ACTION_SEQUENCE, ">") ==
		"LOOKAT>GIVE>UNWRAP>LOOKAT>GIVE>UNWRAP>LOOKAT>GIVE>UNWRAP>GIVE")
	local counts = {}
	for _, action in ipairs(devE2E.ACTION_SEQUENCE) do
		assert(action == "LOOKAT" or action == "GIVE" or action == "UNWRAP",
			"E2E contains an unnecessary player action: " .. tostring(action))
		counts[action] = (counts[action] or 0) + 1
	end
	assert(counts.LOOKAT == 3 and counts.GIVE == 4 and counts.UNWRAP == 3,
		"E2E required action counts changed")
end)

Test("ticket E2E searches bounded pig king interaction tiers", function()
	WorldFixture()
	local oldFinder = FindWalkableOffset
	local calls = {}
	FindWalkableOffset = function(position, startAngle, radius, attempts,
		checkLOS, ignoreWalls, customCheck, allowWater, allowBoats)
		table.insert(calls, { radius = radius, attempts = attempts,
			checkLOS = checkLOS, ignoreWalls = ignoreWalls, allowWater = allowWater })
		return #calls == 2 and Vector3(radius, 0, 0) or nil
	end
	local ok, point, tier, radius = pcall(devE2E.FindKingInteractionPoint,
		NewEntity("pigking", 10, 20))
	FindWalkableOffset = oldFinder
	assert(ok, point)
	assert(point ~= nil and point.x == 13.25 and point.z == 20
		and tier == 2 and radius == 3.25, "E2E 没有使用第二级安全交互点")
	assert(#calls == 2 and calls[1].radius == 2.75 and calls[2].radius == 3.25,
		"E2E 猪王交互点没有按固定层级有限搜索")
	for _, call in ipairs(calls) do
		assert(call.attempts == 16 and call.checkLOS == false
			and call.ignoreWalls == true and call.allowWater == false,
			"E2E 猪王交互点搜索参数错误")
	end
end)

Test("ticket E2E restart cleanup cancels actions, merge work and temporary entities", function()
	local player = NewEntity("wilson", 40, 12, { player = true })
	local stopped, cleared, mergeCancelled = false, false, false
	local activeAction = {}
	player.components.locomotor = { Stop = function() stopped = true end }
	player.GetBufferedAction = function() return activeAction end
	player.ClearBufferedAction = function() cleared = true activeAction = nil end
	player._aipTrainTicketMergeTask = { Cancel = function() mergeCancelled = true end }
	local house, pig, gift = NewEntity("pighouse"), NewEntity("pigman"), NewEntity("gift")
	local session = { run = nil }
	session.e2e = {
		session = session,
		doer = player,
		pig = pig,
		entities = { [house] = true, [pig] = true, [gift] = true },
		stashed = {},
		savedPosition = Vector3(3, 0, 7),
		actionSerial = 4,
		activeAction = activeAction,
	}
	local cleaned, detail = devE2E.Cleanup(session)
	assert(cleaned and detail == nil and stopped and cleared and mergeCancelled)
	assert(player._aipTrainTicketMergeTask == nil and player.x == 3 and player.z == 7)
	assert(not house:IsValid() and not pig:IsValid() and not gift:IsValid())
	assert(devE2E.Cleanup(session), "E2E cleanup was not idempotent")
end)

-- 推进静态与模拟时间；模拟暂停后仍执行报告任务，以验证不会漏掉后续报告批次。
local function ExerciseDevRunner(hasKing, forceGroundFailure)
	WorldFixture()
	local king = Ents[1]
	king.components.aipc_pig_king_train = Runtime(king)
	if not hasKing then Ents = {} end
	local player = PlayerFixture()
	local staticTasks, now, paused, outputs, stepEvents = {}, 0, false, {}, {}
	local oldGroundRatio = config.TEST_MIN_GROUND_RATIO
	if forceGroundFailure then config.TEST_MIN_GROUND_RATIO = 1.1 end
	local oldStatic, oldPaused, oldPrint, oldSetPause, oldPauser, oldClientProber,
		oldE2ERunner, oldPaidRideStarter = TheWorld.DoStaticTaskInTime,
		TheNet.IsServerPaused, print, SetServerPaused, devTests.pauser, devTests.clientProber,
		devTests.e2eRunner, devTests.paidRideStarter
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
	devTests.clientProber = function(doer, sessionGeneration, phase)
		if phase == "driving" or phase == "ended" then
			assert(TheWorld.state.isnight == true, "client probe was not requested during night")
		end
		assert(devTests.ClientProbeResult(doer, sessionGeneration, phase, true,
			phase == "initial" and "night=false,camera=true,hint=false,marker=poi_question;light=false"
			or phase == "driving" and "night=true,driving=true,hint=true,fade=1/1,transparent=true,partial=true,staggered=true,alphaOne=true;light=true,enabled=true,radius=10.00,falloff=0.45,intensity=0.80"
			or "night=true,driving=false,hint=false;light=false"))
		return true
	end
	local e2eKeys = {
		"setup",
		"quest1_dialogue", "quest1_grant", "quest1_trade", "quest1_reward",
		"quest2_dialogue", "quest2_grant", "quest2_trade", "quest2_reward",
		"quest3_dialogue", "quest3_grant", "quest3_trade", "quest3_reward",
		"merge",
	}
	devTests.e2eRunner = function(session, _, hooks)
		local ticket = NewEntity("aip_train_ticket")
		local index = 1
		local function NextE2EStep()
			local key = e2eKeys[index]
			if key ~= "setup" then hooks.begin(key) end
			hooks.pass(key, key == "merge"
				and "fragments=3,tickets=1,actions=LOOKAT>GIVE>UNWRAP"
				or "requiredAction=true,directInventory=true")
			index = index + 1
			if e2eKeys[index] ~= nil then
				hooks.later(0.75, NextE2EStep)
			else
				hooks.done(ticket, "quests=3,fragments=3,tickets=1,actions=LOOKAT>GIVE>UNWRAP")
			end
		end
		NextE2EStep()
	end
	devTests.paidRideStarter = function(session, targetKing, _, hooks)
		hooks.begin("king_trade")
		assert(TheWorld.state.isday == true,
			"ticket must be given before the vanilla pig king sleeps and disables trading")
		local manager = targetKing.components.aipc_pig_king_train
		local started, routeError = manager:StartTrain(session.doer, true)
		if not started then
			hooks.fail("king_trade", tostring(routeError ~= nil and routeError.code))
			return
		end
		FlushBuild()
		local run = session.doer._aip_train_run
		assert(run ~= nil and run.boarded == true,
			"offline paid ride replacement did not complete real boarding")
		hooks.pass("king_trade", "action=GIVE,paid=" .. tostring(run ~= nil and run.paid == true))
		hooks.rideReady(run)
		local retiredHistory = NewEntity("aip_pig_king_train_point")
		retiredHistory.persists = false
		retiredHistory._aip_train_run_id = run.id
		retiredHistory:Remove()
		table.insert(run.entities, retiredHistory)
	end
	print = function(chunk)
		table.insert(outputs, chunk)
		if chunk:find("[PigKingTrain][TestStep]", 1, true) then
			table.insert(stepEvents, { at = now, text = chunk })
		end
	end
	TheWorld._aipTrainLastTestReport = nil
	local ok, err = pcall(function()
		assert(devTests.Start(player))
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
		local expectedSuccess = hasKing and not forceGroundFailure
		assert(paused and report.success == expectedSuccess, string.format(
			"%s; paused=%s success=%s expected=%s\n%s", tostring(report.detail),
			tostring(paused), tostring(report.success), tostring(expectedSuccess),
			table.concat(report.lines or {}, "\n")))
		assert(player._aip_train_run == nil)
		local joined = table.concat(report.lines, "\n")
		assert(joined:find("活动测试会话自动重启与旧任务取消", 1, true),
			"single coupon run did not verify its internal restart")
		if hasKing then
			assert(TheWorld.state.phase == "day" and TheWorld.state.isday == true,
				"test night did not restore the saved clock phase")
			local restoredClock = TheWorld.components.clock:OnSave()
			assert(restoredClock.segs.day == 10 and restoredClock.segs.dusk == 4
				and restoredClock.segs.night == 2, "test night did not restore the saved clock segments")
			assert(report.passed + report.failed + report.skipped == 39,
				"unexpected game-suite check count")
			assert(joined:find("E2E chain=complete", 1, true)
				and joined:find("actions=LOOKAT>GIVE>UNWRAP", 1, true)
				and joined:find("action=GIVE,paid=true", 1, true),
				"required E2E chain details were missing")
			assert(joined:find("真实夜间环境准备与时钟恢复点", 1, true),
				"night setup check missing")
			local tradeStep = joined:find("E2E stage=king_trade", 1, true)
			local nightStep = joined:find("夜间场景已准备", 1, true)
			assert(tradeStep ~= nil and nightStep ~= nil and tradeStep < nightStep,
				"night setup ran before the real pig king trade and boarding")
			assert(joined:find("night=true", 1, true) and joined:find("light=true", 1, true)
				and joined:find("light=false", 1, true), "night light probe details missing")
			assert(joined:find("高度模式里程", 1, true)
				and joined:find("判障策略：ghost-physics-aligned", 1, true)
				and joined:find("垂直误差分桶", 1, true)
				and joined:find("垂直工况", 1, true)
				and joined:find("景点高度：", 1, true),
				"route or vertical diagnostic report lines missing")
			for _, phase in ipairs({ "phase=initial", "phase=driving", "phase=ended" }) do
				assert(joined:find(phase, 1, true), "missing client probe " .. phase)
			end
		end
		if forceGroundFailure then
			assert(joined:find("[FAIL] 路线多数贴地且仅少量抬升", 1, true),
				"forced assertion failure was not recorded")
			assert(joined:find("[PASS] 圆弧减速与巡航恢复", 1, true),
				"suite stopped after a recoverable assertion failure")
		end
		assert(not joined:find("#LUA ERROR", 1, true) and not joined:find("stack traceback", 1, true),
			"caught test failure leaked an engine error marker into the report")
		assert(#outputs > 1, "report was not batched")
		for _, chunk in ipairs(outputs) do
			local _, count = chunk:gsub("\n", "")
			assert(count < 3, "too many report lines in one batch")
		end
		assert(outputs[#outputs]:find("回到 Codex", 1, true), "last batch was lost while paused")
		local lastCompleteByGeneration = {}
		local starts, heavyWaits = 0, 0
		for _, event in ipairs(stepEvents) do
			local eventGeneration = assert(event.text:match("generation=(%d+)"))
			if event.text:find("state=start", 1, true) then
				starts = starts + 1
				local previous = lastCompleteByGeneration[eventGeneration]
				if previous ~= nil then
					assert(event.at - previous >= 0.5,
						"adjacent game test steps executed without yielding frames")
				end
			elseif event.text:find("state=complete", 1, true) then
				lastCompleteByGeneration[eventGeneration] = event.at
				if event.text:find("nextWait=2.00", 1, true) then heavyWaits = heavyWaits + 1 end
			end
		end
		if hasKing then
			assert(starts >= 36, "not all paced test steps were observed")
			assert(heavyWaits >= 3, "heavy route steps did not receive a separate cooldown")
		end
	end)
	TheWorld.DoStaticTaskInTime, TheNet.IsServerPaused, print, SetServerPaused, devTests.pauser,
		devTests.clientProber, devTests.e2eRunner, devTests.paidRideStarter =
		oldStatic, oldPaused, oldPrint, oldSetPause, oldPauser, oldClientProber,
		oldE2ERunner, oldPaidRideStarter
	config.TEST_MIN_GROUND_RATIO = oldGroundRatio
	assert(ok, err)
end

Test("dev coupon suite succeeds, pauses and emits all report batches", function() ExerciseDevRunner(true) end)
Test("dev coupon failure also pauses and emits all report batches", function() ExerciseDevRunner(false) end)
Test("dev coupon continues after a recoverable assertion failure", function() ExerciseDevRunner(true, true) end)
aipGetModConfig = originalConfig

Test("three-phase client probe and native pause work in the restricted mod environment", function()
	local oldAipRPC, oldCamera, oldConfig, oldPlayer, oldEnts, oldWorldState, oldSetServerPaused =
		aipRPC, TheCamera, aipGetModConfig, ThePlayer, Ents, TheWorld.state, SetServerPaused
	local oldIsServerPaused, oldIsServerAdmin = TheNet.IsServerPaused, TheNet.GetIsServerAdmin
	local oldStaticTask = TheWorld.DoStaticTaskInTime
	local oldAipPrint = aipPrint
	local oldReporter, oldPauser, oldClientProber = devTests.reporter, devTests.pauser, devTests.clientProber
	local clientHandlers, results, outputs, hintVisible = {}, {}, {}, false
	local pauseTasks, pauseRequests, pausePolls = {}, 0, 0
	TheCamera = { SetFlyView = function() end }
	ThePlayer = NewEntity("wilson")
	ThePlayer.HUD = {
			_aipPigVillageIndicatorHook = true,
			controls = { aipOrbitDriverHint = { IsVisible = function() return hintVisible end } },
	}
	ThePlayer.components.aipc_orbit_driver_client = { isDriving = net_bool() }
	Ents = {}
	aipGetModConfig = function(name) return name == "dev_mode" and "enabled" or oldConfig(name) end
	aipRPC = function(name, sessionGeneration, phase, success, detail)
		table.insert(results, { name, sessionGeneration, phase, success, detail })
	end
	SetServerPaused = function(value)
		assert(value == true)
		pauseRequests = pauseRequests + 1
	end
	TheNet.IsServerPaused = function()
		pausePolls = pausePolls + 1
		return false
	end
	TheNet.GetIsServerAdmin = function() return true end
	aipPrint = function(...)
		local values = {...}
		for index, value in ipairs(values) do values[index] = tostring(value) end
		table.insert(outputs, table.concat(values, " "))
	end
	TheWorld.DoStaticTaskInTime = function(_, _, fn)
		local task = { fn = fn, Cancel = function(self) self.cancelled = true end }
		table.insert(pauseTasks, task)
		return task
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
		assert(clientHandlers.aipPigTrainTestClientProbe ~= nil)
		assert(clientHandlers.aipPigTrainTestPause ~= nil)
		clientHandlers.aipPigTrainTestClientProbe(7, "initial")
		local telemetry = fade.GetTelemetry(TheWorld)
		local rideLight = SpawnPrefab("aip_pig_king_train_light")
		rideLight.entity:SetParent(ThePlayer.entity)
		table.insert(Ents, rideLight)
		TheWorld.state = { phase = "night", isday = false, isdusk = false, isnight = true }
		ThePlayer.components.aipc_orbit_driver_client.isDriving:set(true)
		hintVisible = true
		telemetry.startCount, telemetry.completedCount = 1, 1
		telemetry.sawTransparent, telemetry.sawPartial = true, true
		telemetry.sawStaggered, telemetry.finalAlphaOne = true, true
		clientHandlers.aipPigTrainTestClientProbe(7, "driving")
		ThePlayer.components.aipc_orbit_driver_client.isDriving:set(false)
		hintVisible = false
		rideLight:Remove()
		clientHandlers.aipPigTrainTestClientProbe(7, "ended")
		assert(#results == 3)
		for index, phase in ipairs({ "initial", "driving", "ended" }) do
			local result = results[index]
			assert(result[1] == "aipPigTrainTestClientProbeResult" and result[2] == 7)
			assert(result[3] == phase and result[4] == "true", tostring(result[5]))
		end
		clientHandlers.aipPigTrainTestPause()
		assert(pauseRequests == 1, "client pause handler did not send exactly one native pause request")
		assert(#(TheWorld.listeners.serverpauseddirty or {}) == 1,
			"client pause handler did not install the native pause receipt listener")
		TheWorld:PushEvent("serverpauseddirty",
			{ pause = false, autopause = true, gameautopause = false, source = "autopause" })
		assert(#(TheWorld.listeners.serverpauseddirty or {}) == 1,
			"autopause was incorrectly accepted as a manual pause receipt")
		local firstPoll = table.remove(pauseTasks, 1)
		assert(firstPoll ~= nil and not firstPoll.cancelled, "pause receipt timeout was not scheduled")
		firstPoll.fn()
		assert(pauseRequests == 1, "pause receipt polling resent the native pause request")
		TheWorld:PushEvent("serverpauseddirty",
			{ pause = true, autopause = false, gameautopause = false, source = "admin" })
		assert(#(TheWorld.listeners.serverpauseddirty or {}) == 0,
			"confirmed pause receipt listener was not removed")
		assert(#pauseTasks == 1 and pauseTasks[1].cancelled,
			"confirmed pause did not cancel the pending timeout task")
		assert(pausePolls >= 2, "network pause state was not retained as auxiliary diagnostics")
		assert(pauseRequests == 1, "native pause request was sent more than once")
		local requested, confirmed = false, false
		for _, output in ipairs(outputs) do
			requested = requested or output:find(
				"state=requested via=serverpauseddirty native=pending", 1, true) ~= nil
			confirmed = confirmed or output:find(
				"state=confirmed via=serverpauseddirty native=true net=false pause=true", 1, true) ~= nil
				and output:find("autopause=false gameautopause=false source=admin", 1, true) ~= nil
		end
		assert(requested and confirmed,
			"native serverpauseddirty pause request and receipt diagnostics were incomplete")
		pauseTasks = {}
		local requestsBeforeTimeout = pauseRequests
		clientHandlers.aipPigTrainTestPause()
		local timeoutPolls = 0
		while #pauseTasks > 0 and timeoutPolls < 25 do
			local task = table.remove(pauseTasks, 1)
			if not task.cancelled then
				timeoutPolls = timeoutPolls + 1
				task.fn()
			end
		end
		assert(timeoutPolls == 20 and pauseRequests == requestsBeforeTimeout + 1,
			"pause receipt timeout did not remain bounded to one native request")
		assert(#pauseTasks == 0 and #(TheWorld.listeners.serverpauseddirty or {}) == 0,
			"pause receipt timeout left a task or event listener behind")
		local timeoutLogged = false
		for _, output in ipairs(outputs) do
			timeoutLogged = timeoutLogged or output:find(
				"state=failed via=serverpauseddirty attempts=20 native=false net=false", 1, true) ~= nil
		end
		assert(timeoutLogged, "pause receipt timeout diagnostics were incomplete")
	end)
	aipRPC, TheCamera, aipGetModConfig, ThePlayer, Ents, TheWorld.state, SetServerPaused =
		oldAipRPC, oldCamera, oldConfig, oldPlayer, oldEnts, oldWorldState, oldSetServerPaused
	TheNet.IsServerPaused, TheNet.GetIsServerAdmin = oldIsServerPaused, oldIsServerAdmin
	TheWorld.DoStaticTaskInTime = oldStaticTask
	aipPrint = oldAipPrint
	devTests.reporter, devTests.pauser, devTests.clientProber = oldReporter, oldPauser, oldClientProber
	assert(ok, err)
end)

print(string.format("%d train regression checks passed", tests))
