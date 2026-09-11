local RouteGenerator = {}

local PRIORITIES = { "P0", "P1", "P2" }
local SPOTS_PER_PRIORITY = 2
local MAX_ATTEMPTS_PER_PRIORITY = 12
local MAX_OPTIMIZE_PASSES = 4
local devMode = aipGetModConfig("dev_mode") == "enabled"
local LOG_PREFIX = "[PigKingTrain][Route]"

-- 开发模式统一使用 AIP 日志前缀输出选点诊断信息。
local function Debug(...)
	if devMode then aipPrint(LOG_PREFIX, ...) end
end

-- 景点池只记录当前分片内可由实体定位的地标，P3 洞穴专线不参与地面猪王列车选点。
local SPOT_POOLS = {
	P0 = {
		{ id = "moonbase", name = "月台森林", prefabs = { "moonbase" } },
		{ id = "dragonfly_arena", name = "龙蝇熔岩竞技场", prefabs = { "dragonfly_spawner", "lava_pond" } },
		{ id = "oasis", name = "绿洲与蚁狮沙漠", prefabs = { "oasislake" } },
		{ id = "beequeen", name = "蜂王草甸", prefabs = { "beequeenhive" } },
		{ id = "glommer_statue", name = "格罗姆雕像与桦树林", prefabs = { "statueglommer" } },
		{ id = "stagehand", name = "舞台之手玫瑰园", prefabs = { "stagehand" } },
		{ id = "portal", name = "绚丽之门", prefabs = { "multiplayer_portal", "spawnpoint_multiplayer" } },
	},
	P1 = {
		{ id = "junkyard", name = "垃圾场", prefabs = { "junk_pile_big", "wagstaff_machinery_marker" } },
		{ id = "walrus_camp", name = "海象营地", prefabs = { "walrus_camp" } },
		{ id = "marble_chess", name = "发条与大理石遗迹", prefabs = { "sculpture_rook", "sculpture_bishop", "sculpture_knight" } },
		{ id = "resurrectionstone", name = "试金石祭坛", prefabs = { "resurrectionstone" } },
		{ id = "moose_nest", name = "麋鹿鹅巢区", prefabs = { "moose_nesting_ground" } },
		{ id = "cave_entrance", name = "洞穴入口", prefabs = { "cave_entrance_open", "cave_entrance" } },
		{ id = "moon_island", name = "月岛环线", prefabs = { "hotspring", "moon_fissure" } },
		{ id = "hermit_island", name = "隐士之家", prefabs = { "hermithouse", "hermithouse_construction3", "hermithouse_construction2", "hermithouse_construction1", "hermitcrab" } },
		{ id = "monkey_island", name = "月亮码头猴岛", prefabs = { "monkeyqueen", "monkeyisland_portal" } },
		{ id = "waterlogged", name = "水中木巨树群", prefabs = { "watertree_pillar" } },
		{ id = "crabking", name = "帝王蟹岩礁", prefabs = { "crabking_spawner", "crabking" } },
		{ id = "ocean_whirlpool", name = "深海大漩涡", prefabs = { "oceanwhirlbigportal" } },
	},
	P2 = {
		{ id = "charlie_stage", name = "查理舞台", prefabs = { "charlie_stage_post" } },
		{ id = "statueharp_hedge", name = "竖琴雕像花篱", prefabs = { "statueharp_hedgespawner" } },
		{ id = "terrarium", name = "泰拉瑞亚箱子营地", prefabs = { "terrariumchest" } },
		{ id = "balatro", name = "Balatro 机器", prefabs = { "balatro_machine" } },
		{ id = "chester_eyebone", name = "切斯特眼骨出生区", prefabs = { "chester_eyebone" } },
		{ id = "celestial_portal", name = "天体传送门", prefabs = { "multiplayer_portal_moonrock" } },
		{ id = "lunar_rift", name = "月亮裂隙", prefabs = { "lunarrift_portal" } },
	},
}

-- 复制坐标，避免路线数据继续引用实体返回的临时 Vector3。
local function CopyPoint(point)
	return {
		x = point.x,
		y = point.y or 0,
		z = point.z,
	}
end

-- 将坐标压缩成适合单行日志的文本。
local function FormatPoint(point)
	if point == nil then return "nil" end
	return string.format("(%.1f,%.1f,%.1f)", point.x, point.y or 0, point.z)
end

-- 读取实体的当前世界坐标。
local function GetPoint(inst)
	if inst == nil or inst.Transform == nil then
		return nil
	end

	local x, y, z = inst.Transform:GetWorldPosition()
	if type(x) ~= "number" or type(y) ~= "number" or type(z) ~= "number"
		or x ~= x or y ~= y or z ~= z or math.abs(x) == math.huge
		or math.abs(y) == math.huge or math.abs(z) == math.huge then return nil end
	return { x = x, y = y, z = z }
end

-- 判断实体能否作为本次列车路线的定位锚点。
local function IsUsableAnchor(inst)
	if
		inst == nil or
		inst.IsValid == nil or
		not inst:IsValid() or
		inst.Transform == nil or
		inst.IsInLimbo ~= nil and inst:IsInLimbo()
	then
		return false
	end
	-- 已经带动切斯特的眼骨不再代表出生布景，即使后来又被丢在地上。
	if inst.prefab == "chester_eyebone" and (inst._aip_train_moved
		or inst.respawntime ~= nil or inst.components.leader ~= nil
		and next(inst.components.leader.followers) ~= nil) then return false end

	local inventoryItem = inst.components ~= nil and inst.components.inventoryitem or nil
	if
		inventoryItem ~= nil and
		inventoryItem.GetGrandOwner ~= nil and
		inventoryItem:GetGrandOwner() ~= nil
	then
		return false
	end

	return true
end

-- 计算忽略高度后的两点距离平方。
local function DistanceSq(first, second)
	local dx = first.x - second.x
	local dz = first.z - second.z
	return dx * dx + dz * dz
end

-- 计算忽略高度后的两点距离。
local function Distance(first, second)
	return math.sqrt(DistanceSq(first, second))
end

-- 一次扫描世界实体，按候选 prefab 建立索引，避免每次重试都遍历整个世界。
local function BuildEntityIndex(entities)
	local trackedPrefabs = {}
	for _, priority in ipairs(PRIORITIES) do
		for _, spot in ipairs(SPOT_POOLS[priority]) do
			for _, prefab in ipairs(spot.prefabs) do
				trackedPrefabs[prefab] = true
			end
		end
	end

	local entityIndex = {}
	for _, inst in pairs(entities) do
		if trackedPrefabs[inst.prefab] and IsUsableAnchor(inst) then
			entityIndex[inst.prefab] = entityIndex[inst.prefab] or {}
			table.insert(entityIndex[inst.prefab], inst)
		end
	end

	return entityIndex
end

-- 输出每个景点配置当前能够看到的有效锚点数量。
local function LogEntityIndex(entityIndex)
	if not devMode then return end
	for _, priority in ipairs(PRIORITIES) do
		local counts = {}
		for _, spot in ipairs(SPOT_POOLS[priority]) do
			local count = 0
			for _, prefab in ipairs(spot.prefabs) do
				for _, inst in ipairs(entityIndex[prefab] or {}) do
					if IsUsableAnchor(inst) then count = count + 1 end
				end
			end
			table.insert(counts, spot.id .. "=" .. tostring(count))
		end
		Debug("index", priority, table.concat(counts, ","))
	end
end

-- 在实体表中查找指定景点离猪王最近的可用锚点。
local function FindAnchor(spot, origin, usedAnchors, entityIndex, selectedSpots)
	local closest = nil
	local closestPoint = nil
	local closestDistanceSq = nil

	for _, prefab in ipairs(spot.prefabs) do
		for _, inst in ipairs(entityIndex[prefab] or {}) do
			if IsUsableAnchor(inst) and not usedAnchors[inst] then
				local point = GetPoint(inst)
				local distanceSq = point ~= nil and DistanceSq(origin, point) or nil
				-- 查理舞台与相邻竖琴花篱只计一个景点，避免两站实际属于同一处布景。
				if point ~= nil then
					for _, selected in ipairs(selectedSpots) do
						if (spot.id == "charlie_stage" and selected.id == "statueharp_hedge"
							or spot.id == "statueharp_hedge" and selected.id == "charlie_stage")
							and DistanceSq(point, selected.point) < 40 * 40 then distanceSq = nil end
					end
				end

				if distanceSq ~= nil and (closestDistanceSq == nil or distanceSq < closestDistanceSq) then
					closest = inst
					closestPoint = point
					closestDistanceSq = distanceSq
				end
			end
		end
		-- 只有首选 prefab 完全不可用时才尝试降级锚点。
		if closest ~= nil then break end
	end

	return closest, closestPoint
end

-- 复制候选池，选点时不会修改模块级配置。
local function CopyList(list)
	local copy = {}
	for _, item in ipairs(list) do
		table.insert(copy, item)
	end
	return copy
end

-- 统计当前候选池中准备保留的景点数量，供选点日志压缩输出。
local function CountPreferredCandidates(pool, preferredSpotIds)
	local count = 0
	for _, candidate in ipairs(pool) do
		if preferredSpotIds ~= nil and preferredSpotIds[candidate.id] then count = count + 1 end
	end
	return count
end

-- 找到当前候选池中离猪王最近的有效景点，超预算重试时用它缩短路线。
local function FindNearestCandidateIndex(pool, origin, usedAnchors, entityIndex, selected)
	local closestIndex, closestDistanceSq
	for index, candidate in ipairs(pool) do
		local _, point = FindAnchor(candidate, origin, usedAnchors, entityIndex, selected)
		local distanceSq = point ~= nil and DistanceSq(origin, point) or nil
		if distanceSq ~= nil and (closestDistanceSq == nil or distanceSq < closestDistanceSq) then
			closestIndex, closestDistanceSq = index, distanceSq
		end
	end
	return closestIndex
end

-- 从一个优先级中保留上轮有效景点并补足两个，超预算重试时优先补最近景点。
local function SelectPrioritySpots(priority, origin, usedAnchors, entityIndex, randomFn, excludedSpotIds,
	preferredSpotIds, preferNearest)
	local pool = {}
	for _, spot in ipairs(SPOT_POOLS[priority]) do
		if not excludedSpotIds[spot.id] then table.insert(pool, spot) end
	end
	local selected = {}
	local attempts = 0
	local attemptLimit = math.min(MAX_ATTEMPTS_PER_PRIORITY, #pool)
	Debug("select-begin", priority, "need=" .. SPOTS_PER_PRIORITY,
		"pool=" .. #pool, "limit=" .. attemptLimit,
		"excluded=" .. tostring(#SPOT_POOLS[priority] - #pool),
		"preferred=" .. tostring(CountPreferredCandidates(pool, preferredSpotIds)),
		"fill=" .. (preferNearest and "nearest" or "random"))

	-- 每次尝试都从临时池移除候选，保证无效锚点不会造成死循环。
	local function TryCandidate(index, source)
		if index == nil or pool[index] == nil or attempts >= attemptLimit then return false end
		attempts = attempts + 1
		local candidate = table.remove(pool, index)
		local anchor, point = FindAnchor(candidate, origin, usedAnchors, entityIndex, selected)
		if anchor == nil then
			Debug("select-miss", priority, tostring(attempts) .. "/" .. tostring(attemptLimit),
				candidate.id, "source=" .. source, "prefabs=" .. table.concat(candidate.prefabs, ","))
			return false
		end
		usedAnchors[anchor] = true
		table.insert(selected, {
			id = candidate.id,
			name = candidate.name,
			priority = priority,
			prefab = anchor.prefab,
			anchor = anchor,
			point = CopyPoint(point),
		})
		Debug("select-hit", priority, tostring(attempts) .. "/" .. tostring(attemptLimit),
			candidate.id, "source=" .. source, "prefab=" .. tostring(anchor.prefab),
			"guid=" .. tostring(anchor.GUID), "point=" .. FormatPoint(point))
		return true
	end

	-- 上轮未被排除的景点先复用，确保一次失败只替换一个候选。
	local index = 1
	while index <= #pool and #selected < SPOTS_PER_PRIORITY and attempts < attemptLimit do
		if preferredSpotIds ~= nil and preferredSpotIds[pool[index].id] then
			TryCandidate(index, "retained")
		else
			index = index + 1
		end
	end

	while #selected < SPOTS_PER_PRIORITY and #pool > 0 and attempts < attemptLimit do
		local candidateIndex = preferNearest
			and FindNearestCandidateIndex(pool, origin, usedAnchors, entityIndex, selected)
			or randomFn(#pool)
		TryCandidate(candidateIndex or 1, preferNearest and "nearest" or "random")
	end
	Debug("select-end", priority, "selected=" .. #selected,
		"attempts=" .. attempts, "remaining=" .. #pool)

	return selected, {
		attempts = attempts,
		attemptLimit = attemptLimit,
		selectedCount = #selected,
	}
end

-- 使用最近邻把六个景点排成从猪王出发的初始顺序。
local function SortByNearestNeighbour(startPoint, selected)
	local remaining = CopyList(selected)
	local ordered = {}
	local currentPoint = startPoint

	while #remaining > 0 do
		local closestIndex = 1
		local closestDistanceSq = DistanceSq(currentPoint, remaining[1].point)

		for index = 2, #remaining do
			local distanceSq = DistanceSq(currentPoint, remaining[index].point)
			if distanceSq < closestDistanceSq then
				closestIndex = index
				closestDistanceSq = distanceSq
			end
		end

		local closest = table.remove(remaining, closestIndex)
		table.insert(ordered, closest)
		currentPoint = closest.point
	end

	return ordered
end

-- 原地反转一段路线，用于有限轮次的 2-opt 优化。
local function ReverseRange(list, firstIndex, lastIndex)
	while firstIndex < lastIndex do
		list[firstIndex], list[lastIndex] = list[lastIndex], list[firstIndex]
		firstIndex = firstIndex + 1
		lastIndex = lastIndex - 1
	end
end

-- 对最近邻结果做有限轮次的 2-opt，减少折返和明显交叉。
local function OptimizeRoute(startPoint, ordered)
	local pass = 0
	local improved = true

	while improved and pass < MAX_OPTIMIZE_PASSES do
		pass = pass + 1
		improved = false

		for firstIndex = 1, #ordered - 1 do
			for lastIndex = firstIndex + 1, #ordered do
				local previousPoint = firstIndex == 1 and startPoint or ordered[firstIndex - 1].point
				local nextPoint = lastIndex == #ordered and startPoint or ordered[lastIndex + 1].point
				local currentDistance = Distance(previousPoint, ordered[firstIndex].point) +
					Distance(ordered[lastIndex].point, nextPoint)
				local reversedDistance = Distance(previousPoint, ordered[lastIndex].point) +
					Distance(ordered[firstIndex].point, nextPoint)

				if reversedDistance + 0.01 < currentDistance then
					ReverseRange(ordered, firstIndex, lastIndex)
					improved = true
				end
			end
		end
	end

	return pass
end

-- 把排好序的六站转换成闭环节点和分段路线图。
local function BuildRouteMap(startInst, startPoint, ordered, selectedByPriority, selectionStats, optimizePasses)
	local nodes = {
		{
			index = 0,
			id = "pigking",
			name = "猪王村与列车总站",
			priority = "START",
			prefab = startInst.prefab,
			anchor = startInst,
			point = CopyPoint(startPoint),
		},
	}

	for index, stop in ipairs(ordered) do
		table.insert(nodes, {
			index = index,
			id = stop.id,
			name = stop.name,
			priority = stop.priority,
			prefab = stop.prefab,
			anchor = stop.anchor,
			point = CopyPoint(stop.point),
		})
	end

	table.insert(nodes, {
		index = #ordered + 1,
		id = "pigking_return",
		name = "返回猪王村",
		priority = "RETURN",
		prefab = startInst.prefab,
		anchor = startInst,
		point = CopyPoint(startPoint),
	})

	local legs = {}
	local totalDistance = 0
	for index = 1, #nodes - 1 do
		local legDistance = Distance(nodes[index].point, nodes[index + 1].point)
		totalDistance = totalDistance + legDistance
		table.insert(legs, {
			index = index,
			from = nodes[index],
			to = nodes[index + 1],
			distance = legDistance,
		})
	end

	return {
		version = 1,
		closed = true,
		spotCount = #ordered,
		start = nodes[1],
		stops = ordered,
		nodes = nodes,
		legs = legs,
		totalDistance = totalDistance,
		selectedByPriority = selectedByPriority,
		selectionStats = selectionStats,
		optimizePasses = optimizePasses,
	}
end

-- 一次性选择 P0、P1、P2 各两个景点，并生成六站闭环路线图。
function RouteGenerator.Create(startInst, options)
	options = options or {}
	local excludedSpotIds = options.excludedSpotIds or {}
	local preferredSpotIds = options.preferredSpotIds or {}

	if not IsUsableAnchor(startInst) then
		Debug("create-failed", "code=invalid_start", "prefab=" .. tostring(startInst ~= nil and startInst.prefab))
		return nil, {
			code = "invalid_start",
			message = "猪王起点无效",
		}
	end

	local startPoint = GetPoint(startInst)
	if startPoint == nil then
		Debug("create-failed", "code=invalid_start", "reason=invalid_point")
		return nil, { code = "invalid_start", message = "猪王起点坐标无效" }
	end
	Debug("create-begin", "prefab=" .. tostring(startInst.prefab),
		"guid=" .. tostring(startInst.GUID), "point=" .. FormatPoint(startPoint))
	local entities = options.entities or Ents or {}
	local entityIndex = BuildEntityIndex(entities)
	LogEntityIndex(entityIndex)
	local randomFn = options.randomFn or math.random
	local usedAnchors = { [startInst] = true }
	local selected = {}
	local selectedByPriority = {}
	local selectionStats = {}

	for _, priority in ipairs(PRIORITIES) do
		local prioritySelected, stats = SelectPrioritySpots(
			priority,
			startPoint,
			usedAnchors,
			entityIndex,
			randomFn,
			excludedSpotIds,
			preferredSpotIds,
			options.preferNearest == true
		)
		selectedByPriority[priority] = prioritySelected
		selectionStats[priority] = stats

		if #prioritySelected < SPOTS_PER_PRIORITY then
			Debug("create-failed", "code=not_enough_spots", "priority=" .. priority,
				"selected=" .. #prioritySelected, "required=" .. SPOTS_PER_PRIORITY,
				"attempts=" .. stats.attempts)
			return nil, {
				code = "not_enough_spots",
				message = priority .. " 可用景点不足两个",
				priority = priority,
				requiredCount = SPOTS_PER_PRIORITY,
				selectedCount = #prioritySelected,
				selectionStats = selectionStats,
			}
		end

		for _, stop in ipairs(prioritySelected) do
			table.insert(selected, stop)
		end
	end

	local ordered = SortByNearestNeighbour(startPoint, selected)
	if devMode then
		local nearestOrder = {}
		for _, stop in ipairs(ordered) do table.insert(nearestOrder, stop.id .. "[" .. stop.priority .. "]") end
		Debug("order-nearest", table.concat(nearestOrder, " -> "))
	end
	local optimizePasses = OptimizeRoute(startPoint, ordered)
	local routeMap = BuildRouteMap(
		startInst,
		startPoint,
		ordered,
		selectedByPriority,
		selectionStats,
		optimizePasses
	)
	if devMode then
		local finalOrder = {}
		for _, stop in ipairs(routeMap.stops) do table.insert(finalOrder, stop.id .. "[" .. stop.priority .. "]") end
		Debug("order-final", "passes=" .. optimizePasses, table.concat(finalOrder, " -> "))
		Debug("create-ready", "spots=" .. routeMap.spotCount, "nodes=" .. #routeMap.nodes,
			"legs=" .. #routeMap.legs, string.format("distance=%.1f", routeMap.totalDistance))
	end

	return routeMap
end

RouteGenerator.PRIORITIES = PRIORITIES
RouteGenerator.SPOTS_PER_PRIORITY = SPOTS_PER_PRIORITY
RouteGenerator.MAX_ATTEMPTS_PER_PRIORITY = MAX_ATTEMPTS_PER_PRIORITY
RouteGenerator.SPOT_POOLS = SPOT_POOLS

return RouteGenerator
