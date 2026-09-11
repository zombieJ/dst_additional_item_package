local config = require("configurations/aip_pig_king_train")
local Track = {}
local CELL = 16
local GRID = 8
local MAX_SEARCH = 1200
local SAMPLE = 2
local DEFAULT_OUTER_SEARCH_EXTRA = 4
local VIEWPOINT_SEARCH_EXTRA = 24
local STATION_RADIUS = 12
local STATION_RAMP_DISTANCE = config.ELEVATION_RAMP_DISTANCE
local STATION_RAMP_DIRECTIONS = 24
local SCENIC_ARC_DIRECTIONS = 24
local SCENIC_ARC_SWEEP = config.SCENIC_ARC_FRACTION * 2 * math.pi
local GROUND_TRACK_HEIGHT = 0
local devMode = aipGetModConfig("dev_mode") == "enabled"
local LOG_PREFIX = "[PigKingTrain][Track]"

-- 开发模式统一使用 AIP 日志输出铺轨规划诊断信息。
local function Debug(...)
	if devMode then aipPrint(LOG_PREFIX, ...) end
end
local PROFILES = {
	dragonfly_arena = { radius = 26, height = 8, dangerous = true },
	beequeen = { radius = 24, height = 8, dangerous = true },
	oasis = { radius = 18, height = 8, dangerous = true },
	junkyard = { radius = 24, height = 8, dangerous = true },
	walrus_camp = { radius = 20, height = 8, dangerous = true },
	moose_nest = { radius = 24, height = 8, dangerous = true },
	crabking = { radius = 28, height = 8, dangerous = true },
	ocean_whirlpool = { radius = 24, height = 8, dangerous = true },
	lunar_rift = { radius = 28, height = 8, dangerous = true },
	waterlogged = { radius = 20, height = 4 },
	monkey_island = { radius = 20, height = 6 },
	statueharp_hedge = { radius = 20, height = 8, dangerous = true },
	resurrectionstone = { radius = 18, height = 8 },
}
local DANGER_RADII = {
	dragonfly = 28, dragonfly_spawner = 24, lava_pond = 7,
	beequeen = 28, beequeenhive = 22, antlion = 24,
	crabking = 26, crabking_spawner = 26, oceanwhirlbigportal = 22,
	lunarrift_portal = 26, moose = 26, junk_pile_big = 22,
}

-- 复制坐标并显式指定轨道高度。
local function Point(x, y, z)
	return { x = x, y = y, z = z }
end

-- 将轨道坐标压缩成适合单行日志的文本。
local function FormatPoint(point)
	if point == nil then return "nil" end
	return string.format("(%.1f,%.1f,%.1f)", point.x, point.y or 0, point.z)
end

-- 计算轨道实体预算所需的空间距离。
local function Distance(a, b)
	return math.sqrt((a.x - b.x)^2 + (a.y - b.y)^2 + (a.z - b.z)^2)
end

-- 计算规划折线的水平距离，坡度只在后续分段时加入。
local function HorizontalDistance(a, b)
	return math.sqrt((a.x - b.x)^2 + (a.z - b.z)^2)
end

-- 判断轨道端点是否仍属于地面段，兼容原驾驶器的 0.05 高度阈值。
local function IsGroundHeight(height)
	return height <= config.GROUND_HEIGHT
end

-- 按实际折线弦长估算一段观景圆弧的最低里程。
local function ScenicArcDistance(radius)
	local angle = SCENIC_ARC_SWEEP / config.SCENIC_ARC_SEGMENTS
	return config.SCENIC_ARC_SEGMENTS * 2 * radius * math.sin(angle / 2)
end

-- 计算景点外移最多能缩短的距离，得到无需扫描障碍即可判定的安全下界。
local function RoughDistanceLowerBound(routeMap)
	local maximumSaving = 2 * math.sqrt(
		(STATION_RADIUS + DEFAULT_OUTER_SEARCH_EXTRA)^2 + config.HEIGHT^2
	)
	local minimumArcDistance = 0
	for _, stop in ipairs(routeMap.stops) do
		local profile = PROFILES[stop.id] or { radius = 12, height = config.HEIGHT }
		local maximumOffset = math.sqrt(
			(profile.radius + VIEWPOINT_SEARCH_EXTRA)^2 + profile.height^2
		)
		maximumSaving = maximumSaving + 2 * maximumOffset
		minimumArcDistance = minimumArcDistance + ScenicArcDistance(profile.radius)
	end
	return math.max(0, routeMap.totalDistance - maximumSaving) + minimumArcDistance
end

-- 返回稳定的空间网格键。
local function Key(x, z)
	return x .. ":" .. z
end

-- 将障碍范围放进空间索引，并区分仅阻挡地面总站或同时阻挡高架轨道。
local function AddBlocker(context, x, z, radius, blocksElevated)
	local blocker = { x = x, z = z, radius = radius, blocksElevated = blocksElevated == true }
	context.blockerCount = (context.blockerCount or 0) + 1
	if blocker.blocksElevated then
		context.elevatedBlockerCount = (context.elevatedBlockerCount or 0) + 1
	end
	for cx = math.floor((x - radius) / CELL), math.floor((x + radius) / CELL) do
		for cz = math.floor((z - radius) / CELL), math.floor((z + radius) / CELL) do
			local key = Key(cx, cz)
			context.cells[key] = context.cells[key] or {}
			table.insert(context.cells[key], blocker)
		end
	end
end

-- 建立当前地形及障碍快照；绝不修改障碍实体或世界地皮。
function Track.CreateContext(options)
	options = options or {}
	local context = {
		map = options.map or TheWorld.Map,
		cells = {},
		allowOcean = options.allowOcean,
		blockerCount = 0,
		elevatedBlockerCount = 0,
		scannedEntities = 0,
	}
	if context.allowOcean == nil then
		context.allowOcean = config.ALLOW_OCEAN
	end
	for _, ent in pairs(options.entities or Ents) do
		context.scannedEntities = context.scannedEntities + 1
		if ent:IsValid() and ent.Transform ~= nil and not ent:IsInLimbo()
			and not ent:HasTag("aip_train_temporary") and not ent:HasTag("player") then
			local radius = DANGER_RADII[ent.prefab]
			local blocksElevated = radius ~= nil
			if radius == nil then
				local physical = ent:GetPhysicsRadius(0)
				if physical > 0 or ent:HasTag("structure") or ent:HasTag("CHOP_workable") then
					radius = math.max(physical, ent:HasTag("CHOP_workable") and 3 or 1) + 2
				end
			end
			local burnable = ent.components.burnable
			if ent:HasTag("fire") or ent:HasTag("hostile") or ent:HasTag("monster")
				or burnable ~= nil and (burnable:IsBurning() or burnable:IsSmoldering()) then
				radius = math.max(radius or 0, 10)
				blocksElevated = true
			end
			if radius ~= nil then
				local x, _, z = ent.Transform:GetWorldPosition()
				AddBlocker(context, x, z, radius + SAMPLE / 2, blocksElevated)
			end
		end
	end
	Debug("context", "entities=" .. context.scannedEntities,
		"blockers=" .. context.blockerCount,
		"elevatedBlockers=" .. context.elevatedBlockerCount,
		"allowOcean=" .. tostring(context.allowOcean))
	return context
end

-- 检查陆地、海面、地图边界及静态障碍；地面轨道必须在陆地并避开全部障碍。
local function IsClear(context, point, ground)
	local land = context.map:IsPassableAtPoint(point.x, 0, point.z, false, true)
	if not land and (ground or not context.allowOcean
		or not context.map:IsOceanTileAtPoint(point.x, 0, point.z)) then
		return false
	end
	for _, block in ipairs(context.cells[Key(math.floor(point.x / CELL), math.floor(point.z / CELL))] or {}) do
		if (ground or block.blocksElevated)
			and (point.x - block.x)^2 + (point.z - block.z)^2 < block.radius^2 then
			return false
		end
	end
	return true
end

-- 等距采样整段轨道，避免两个安全端点之间仍穿过障碍或虚空。
local function ClearSegment(context, a, b, ground)
	local count = math.max(1, math.ceil(Distance(a, b) / SAMPLE))
	for i = 0, count do
		local t = i / count
		if not IsClear(context, Point(a.x + (b.x - a.x) * t, 0, a.z + (b.z - a.z) * t), ground) then
			return false
		end
	end
	return true
end

-- 从有限个外围候选中选择靠近参考点且不压住地标的观景位置。
local function FindOuterPoint(context, center, radius, height, reference, ground, extraRadius)
	local best, bestDistance
	for ring = 0, math.floor((extraRadius or DEFAULT_OUTER_SEARCH_EXTRA) / 2) do
		for i = 0, 23 do
			local angle = i * 2 * math.pi / 24
			local r = radius + ring * 2
			local point = Point(center.x + math.cos(angle) * r, height, center.z + math.sin(angle) * r)
			local distance = Distance(point, reference)
			if IsClear(context, point, ground) and (bestDistance == nil or distance < bestDistance) then
				best, bestDistance = point, distance
			end
		end
	end
	return best
end

-- 从指定角度生成约四分之三圈的等高观景圆弧，并按地面或高架规则校验安全性。
local function BuildScenicArc(context, center, radius, height, startAngle, direction, ground)
	local points = {}
	for index = 0, config.SCENIC_ARC_SEGMENTS do
		local angle = startAngle + direction * SCENIC_ARC_SWEEP * index / config.SCENIC_ARC_SEGMENTS
		local point = Point(center.x + math.cos(angle) * radius, height,
			center.z + math.sin(angle) * radius)
		if not IsClear(context, point, ground)
			or index > 0 and not ClearSegment(context, points[#points], point, ground) then
			return nil
		end
		table.insert(points, point)
	end
	return points
end

-- 在最小安全半径上选择兼顾进站与下一站方向的地面或高架观景圆弧。
local function FindScenicArc(context, center, radius, height, reference, nextReference, ground)
	for ring = 0, math.floor(VIEWPOINT_SEARCH_EXTRA / 2) do
		local arcRadius = radius + ring * 2
		local best, bestScore
		for index = 0, SCENIC_ARC_DIRECTIONS - 1 do
			local startAngle = index * 2 * math.pi / SCENIC_ARC_DIRECTIONS
			for _, direction in ipairs({ 1, -1 }) do
				local points = BuildScenicArc(context, center, arcRadius, height, startAngle, direction, ground)
				if points ~= nil then
					local score = Distance(reference, points[1])
						+ Distance(points[#points], nextReference or reference)
					if bestScore == nil or score < bestScore then
						bestScore = score
						best = { points = points, radius = arcRadius, direction = direction,
							segmentCount = config.SCENIC_ARC_SEGMENTS,
							sweepDegrees = config.SCENIC_ARC_FRACTION * 360 }
					end
				end
			end
		end
		if best ~= nil then return best end
	end
end

-- 在猪王外围选择可落地总站，可供结束和异常中止时重新校验。
function Track.FindStation(context, origin, reference, returning)
	for radius = STATION_RADIUS, returning and 60 or STATION_RADIUS, 8 do
		local point = FindOuterPoint(context, origin, radius, 0, reference or origin, true)
		if point ~= nil then return point end
	end
end

-- 在总站外侧优先寻找地面出发点，周围完全堵塞时才使用短高架坡道。
local function FindStationDeparture(context, origin, station)
	local dx, dz = station.x - origin.x, station.z - origin.z
	local length = math.sqrt(dx * dx + dz * dz)
	if length < 0.01 then dx, dz, length = 1, 0, 1 end
	dx, dz = dx / length, dz / length
	for _, mode in ipairs({
		{ height = GROUND_TRACK_HEIGHT, ground = true, name = "ground" },
		{ height = config.HEIGHT, ground = false, name = "elevated-fallback" },
	}) do
		for attempt = 0, STATION_RAMP_DIRECTIONS - 1 do
			local direction = attempt == 0 and 0
				or math.ceil(attempt / 2) * (attempt % 2 == 1 and 1 or -1)
			local angle = direction * 2 * math.pi / STATION_RAMP_DIRECTIONS
			local cosAngle, sinAngle = math.cos(angle), math.sin(angle)
			local rampX = dx * cosAngle - dz * sinAngle
			local rampZ = dx * sinAngle + dz * cosAngle
			local point = Point(station.x + rampX * STATION_RAMP_DISTANCE,
				mode.height, station.z + rampZ * STATION_RAMP_DISTANCE)
			if ClearSegment(context, station, point, mode.ground) then return point, mode.name end
		end
	end
end

-- 优先队列插入，保持有限 A* 搜索的扩展成本可控。
local function HeapPush(heap, node)
	local i = #heap + 1
	while i > 1 do
		local parent = math.floor(i / 2)
		if heap[parent].f <= node.f then break end
		heap[i] = heap[parent]
		i = parent
	end
	heap[i] = node
end

-- 从优先队列取出估计总路程最短的节点。
local function HeapPop(heap)
	local root, last = heap[1], table.remove(heap)
	if #heap > 0 then
		local i = 1
		while i * 2 <= #heap do
			local child = i * 2
			if child < #heap and heap[child + 1].f < heap[child].f then child = child + 1 end
			if last.f <= heap[child].f then break end
			heap[i] = heap[child]
			i = child
		end
		heap[i] = last
	end
	return root
end

-- 按指定高度模式优先尝试直达，否则用有展开上限的 A* 绕行，不拆树或建筑。
local function FindPath(context, startPoint, endPoint, ground)
	local mode = ground and "ground" or "elevated"
	if ClearSegment(context, startPoint, endPoint, ground) then
		Debug("path-direct", "mode=" .. mode, FormatPoint(startPoint), "->", FormatPoint(endPoint),
			string.format("distance=%.1f", Distance(startPoint, endPoint)))
		return { startPoint, endPoint }
	end
	local heap, best, closed = {}, {}, {}
	local start = { x = startPoint.x, y = 0, z = startPoint.z, gx = 0, gz = 0, g = 0 }
	start.f = Distance(start, endPoint)
	HeapPush(heap, start)
	best[Key(0, 0)] = 0
	local expanded = 0
	while #heap > 0 and expanded < MAX_SEARCH do
		local node = HeapPop(heap)
		local key = Key(node.gx, node.gz)
		if not closed[key] then
			closed[key] = true
			expanded = expanded + 1
			if ClearSegment(context, node, endPoint, ground) then
				local path = { endPoint }
				while node ~= nil do
					table.insert(path, 1, Point(node.x, 0, node.z))
					node = node.parent
				end
				Debug("path-astar", "mode=" .. mode, FormatPoint(startPoint), "->", FormatPoint(endPoint),
					"expanded=" .. expanded, "pathNodes=" .. #path)
				return path
			end
			for dx = -1, 1 do
				for dz = -1, 1 do
					if dx ~= 0 or dz ~= 0 then
						local gx, gz = node.gx + dx, node.gz + dz
						local nextKey = Key(gx, gz)
						local point = Point(startPoint.x + gx * GRID, 0, startPoint.z + gz * GRID)
						local g = node.g + Distance(node, point)
						if not closed[nextKey] and (best[nextKey] == nil or g < best[nextKey])
							and g < config.MAX_DISTANCE and ClearSegment(context, node, point, ground) then
							best[nextKey] = g
							point.gx, point.gz, point.g, point.f, point.parent = gx, gz, g, g + Distance(point, endPoint), node
							HeapPush(heap, point)
						end
					end
				end
			end
		end
	end
	Debug("path-failed", "mode=" .. mode, FormatPoint(startPoint), "->", FormatPoint(endPoint),
		"expanded=" .. expanded, "limit=" .. MAX_SEARCH)
	return nil
end

-- 汇总寻路折线的水平长度，供短坡道高度曲线按累计进度计算。
local function PathHorizontalDistance(path)
	local distance = 0
	for index = 2, #path do
		distance = distance + HorizontalDistance(path[index - 1], path[index])
	end
	return distance
end

-- 根据路径模式生成短坡道：地面路线尽快落地，高架路线只在必要区间保持高度。
local function TrackHeightAt(fromHeight, toHeight, cruiseHeight, distance, totalDistance)
	if totalDistance <= 0.01 then return toHeight end
	local rampDistance = math.max(0.01, config.ELEVATION_RAMP_DISTANCE)
	local fromProgress = math.min(1, distance / rampDistance)
	local toProgress = math.min(1, (totalDistance - distance) / rampDistance)
	local fromLimit = fromHeight + (cruiseHeight - fromHeight) * fromProgress
	local toLimit = toHeight + (cruiseHeight - toHeight) * toProgress
	if cruiseHeight >= fromHeight and cruiseHeight >= toHeight then
		return math.min(fromLimit, toLimit)
	end
	return math.max(fromLimit, toLimit)
end

-- 按最终端点统计地面与抬升里程，日志可直接确认线路是否以地面为主。
local function MeasureHeightProfile(plan)
	local groundDistance, elevatedDistance, transitions = 0, 0, 0
	local previousElevated = nil
	for index = 2, #plan.points do
		local previous, point = plan.points[index - 1], plan.points[index]
		local length = Distance(previous, point)
		local elevated = not IsGroundHeight(previous.y) or not IsGroundHeight(point.y)
		if elevated then elevatedDistance = elevatedDistance + length
		else groundDistance = groundDistance + length end
		if previousElevated ~= nil and elevated ~= previousElevated then transitions = transitions + 1 end
		previousElevated = elevated
	end
	plan.groundDistance = groundDistance
	plan.elevatedDistance = elevatedDistance
	plan.heightTransitions = transitions
end

-- 输出结构化失败信息，供体验券返还与开发日志使用。
local function Failure(code, spot, detail)
	local spotId = spot ~= nil and spot.id or nil
	Debug("plan-failed", "code=" .. tostring(code), "spot=" .. tostring(spotId),
		"detail=" .. tostring(detail))
	return nil, { code = code, spot = spotId, detail = detail }
end

-- 将景点锚点转换为外围闭环折线，并在生成实体前完成全部预算检查。
function Track.Plan(routeMap, options)
	options = options or {}
	Debug("plan-begin", "spots=" .. tostring(routeMap ~= nil and routeMap.spotCount),
		"roughDistance=" .. string.format("%.1f", routeMap.totalDistance or 0),
		"reference=" .. FormatPoint(options.reference))
	local roughLowerBound = RoughDistanceLowerBound(routeMap)
	Debug("rough-budget", string.format("distance=%.1f", routeMap.totalDistance),
		string.format("lowerBound=%.1f/%d", roughLowerBound, config.MAX_DISTANCE))
	if roughLowerBound > config.MAX_DISTANCE then
		return Failure("rough_route_too_long", nil, string.format(
			"distance=%.1f,lowerBound=%.1f/%d",
			routeMap.totalDistance, roughLowerBound, config.MAX_DISTANCE))
	end
	local context = Track.CreateContext(options)
	local origin = routeMap.start.point
	local station = Track.FindStation(context, origin, options.reference)
	if station == nil then return Failure("no_station", nil, "origin=" .. FormatPoint(origin)) end
	local departure, departureMode = FindStationDeparture(context, origin, station)
	if departure == nil then
		return Failure("no_station", nil, "ramp-unavailable,station=" .. FormatPoint(station))
	end
	Debug("station", "origin=" .. FormatPoint(origin), "landing=" .. FormatPoint(station),
		"departure=" .. FormatPoint(departure), "mode=" .. tostring(departureMode))
	-- 先登记全部景点核心，确保任何观景圆弧都不会穿过尚未处理的景点。
	for _, stop in ipairs(routeMap.stops) do
		local profile = PROFILES[stop.id] or { radius = 12, height = config.HEIGHT }
		AddBlocker(context, stop.point.x, stop.point.z, profile.radius - 2, true)
	end
	local views = { { point = departure } }
	local routeNodes = { { point = departure } }
	local arcs = {}
	for stopIndex, stop in ipairs(routeMap.stops) do
		local profile = PROFILES[stop.id] or { radius = 12, height = config.HEIGHT }
		local nextReference = routeMap.stops[stopIndex + 1] ~= nil
			and routeMap.stops[stopIndex + 1].point or departure
		local elevated = profile.dangerous == true
		local arcHeight = elevated and profile.height or GROUND_TRACK_HEIGHT
		local heightMode = elevated and "danger-elevated" or "ground"
		local arc = FindScenicArc(context, stop.point, profile.radius, arcHeight,
			routeNodes[#routeNodes].point, nextReference, not elevated)
		-- 普通景点只有在地面圆弧被海岸或实体完全堵住时才退到高架。
		if arc == nil and not elevated then
			elevated = true
			arcHeight = profile.height
			heightMode = "elevated-fallback"
			arc = FindScenicArc(context, stop.point, profile.radius, arcHeight,
				routeNodes[#routeNodes].point, nextReference, false)
		end
		if arc == nil then return Failure("no_viewpoint", stop,
			"arc-unavailable,anchor=" .. FormatPoint(stop.point) .. ",radius=" .. tostring(profile.radius)) end
		local view = { point = arc.points[1], stop = stop,
			dangerous = profile.dangerous == true, canPark = false }
		table.insert(views, view)
		local arcId = #arcs + 1
		local arcPlan = { stop = stop, center = stop.point, entry = arc.points[1],
			exit = arc.points[#arc.points], radius = arc.radius, direction = arc.direction,
			segmentCount = arc.segmentCount, sweepDegrees = arc.sweepDegrees, points = arc.points,
			elevated = elevated, heightMode = heightMode, height = arcHeight }
		table.insert(arcs, arcPlan)
		for pointIndex, point in ipairs(arc.points) do
			table.insert(routeNodes, { point = point, arcId = arcId,
				stop = pointIndex == 1 and stop or nil,
				dangerous = profile.dangerous == true, canPark = false, ground = not elevated })
		end
		Debug("scenic-arc", "stop=" .. stop.id, "priority=" .. stop.priority,
			"anchor=" .. FormatPoint(stop.point), "entry=" .. FormatPoint(arcPlan.entry),
			"exit=" .. FormatPoint(arcPlan.exit), string.format("radius=%.1f", arc.radius),
			string.format("sweep=%.0f", arc.sweepDegrees), "segments=" .. arc.segmentCount,
			"direction=" .. (arc.direction > 0 and "positive" or "negative"),
			"dangerous=" .. tostring(profile.dangerous == true),
			"heightMode=" .. heightMode, string.format("height=%.1f", arcHeight))
	end
	table.insert(views, { point = departure })
	table.insert(routeNodes, { point = departure })
	local rampDistance = Distance(station, departure)
	local plan = { station = station, points = { station, departure }, stops = {}, totalDistance = rampDistance * 2,
		oceanDistance = 0, visualCount = 2 * math.max(0, math.ceil(rampDistance / config.ORBIT_SPACING) - 1),
		scenicSegments = {}, arcs = arcs }
	for legIndex = 1, #routeNodes - 1 do
		local from, to = routeNodes[legIndex], routeNodes[legIndex + 1]
		local scenicLeg = from.arcId ~= nil and from.arcId == to.arcId
		Debug("leg-begin", "index=" .. legIndex, "from=" .. FormatPoint(from.point),
			"to=" .. FormatPoint(to.point), "stop=" .. tostring(to.stop ~= nil and to.stop.id),
			"scenic=" .. tostring(scenicLeg))
		local path, pathMode
		if scenicLeg then
			local ground = from.ground == true and to.ground == true
			path = FindPath(context, from.point, to.point, ground)
			pathMode = ground and "ground-scenic" or "elevated-scenic"
		else
			path = FindPath(context, from.point, to.point, true)
			pathMode = "ground"
			if path == nil then
				path = FindPath(context, from.point, to.point, false)
				pathMode = "elevated-fallback"
			end
		end
		if path == nil then return Failure("no_safe_path", to.stop,
			"from=" .. FormatPoint(from.point) .. ",to=" .. FormatPoint(to.point)) end
		local pathDistance = PathHorizontalDistance(path)
		local cruiseHeight = (pathMode == "ground" or pathMode == "ground-scenic") and GROUND_TRACK_HEIGHT
			or math.max(config.HEIGHT, from.point.y, to.point.y)
		local requiresRamp = not scenicLeg and (pathMode == "elevated-fallback"
			or not IsGroundHeight(from.point.y) or not IsGroundHeight(to.point.y))
		local segmentLimit = requiresRamp
			and math.min(config.MAX_SEGMENT, config.ELEVATION_RAMP_DISTANCE) or config.MAX_SEGMENT
		Debug("leg-path", "index=" .. legIndex, "mode=" .. pathMode,
			string.format("horizontal=%.1f cruiseY=%.1f segmentLimit=%.1f",
				pathDistance, cruiseHeight, segmentLimit))
		local traveled = 0
		for i = 2, #path do
			local pathStart, pathEnd = path[i - 1], path[i]
			local horizontal = HorizontalDistance(pathStart, pathEnd)
			-- 每个端点间隔不超过配置上限，坡道高度按整条接驳路径的累计进度计算。
			local segments = math.max(1, math.ceil(horizontal / segmentLimit))
			for j = 1, segments do
				local t = j / segments
				local distanceAlong = traveled + horizontal * t
				local height = TrackHeightAt(from.point.y, to.point.y, cruiseHeight,
					distanceAlong, pathDistance)
				local point = Point(pathStart.x + (pathEnd.x - pathStart.x) * t, height,
					pathStart.z + (pathEnd.z - pathStart.z) * t)
				local previous = plan.points[#plan.points]
				local length = Distance(previous, point)
				if length > 0.01 then
					plan.totalDistance = plan.totalDistance + length
					plan.visualCount = plan.visualCount + math.max(0, math.ceil(length / config.ORBIT_SPACING) - 1)
					if scenicLeg then plan.scenicSegments[#plan.points] = true end
					local samples = math.max(1, math.ceil(length / SAMPLE))
					for sample = 1, samples do
						local fraction = (sample - 0.5) / samples
						if context.map:IsOceanTileAtPoint(previous.x + (point.x - previous.x) * fraction, 0,
							previous.z + (point.z - previous.z) * fraction) then
							plan.oceanDistance = plan.oceanDistance + length / samples
						end
					end
					table.insert(plan.points, point)
				end
				if plan.totalDistance > config.MAX_DISTANCE or plan.oceanDistance > config.MAX_OCEAN_DISTANCE
					or plan.visualCount > config.MAX_VISUALS or #plan.points > config.MAX_POINTS then
					return Failure("track_budget_exceeded", to.stop, string.format(
						"distance=%.1f/%d,ocean=%.1f/%d,visuals=%d/%d,points=%d/%d",
						plan.totalDistance, config.MAX_DISTANCE, plan.oceanDistance, config.MAX_OCEAN_DISTANCE,
						plan.visualCount, config.MAX_VISUALS, #plan.points, config.MAX_POINTS))
				end
			end
			traveled = traveled + horizontal
		end
		if to.stop ~= nil then
			plan.stops[#plan.points] = { spot = to.stop, dangerous = to.dangerous, canPark = to.canPark }
		end
	end
	table.insert(plan.points, station)
	MeasureHeightProfile(plan)
	-- 旧驾驶器按水平距离计算坡度进度，任何纯垂直相邻端点都必须在创建实体前拒绝。
	for index = 2, #plan.points do
		local previous, point = plan.points[index - 1], plan.points[index]
		if (point.x - previous.x)^2 + (point.z - previous.z)^2 <= 0.01^2 then
			return Failure("no_safe_path", nil,
				"zero-horizontal-segment=" .. tostring(index - 1) .. "->" .. tostring(index))
		end
	end
	if #plan.points > config.MAX_POINTS then
		return Failure("track_budget_exceeded", nil,
			"points=" .. #plan.points .. "/" .. config.MAX_POINTS)
	end
	plan.views = views
	Debug("plan-ready", string.format("distance=%.1f/%d", plan.totalDistance, config.MAX_DISTANCE),
		string.format("ocean=%.1f/%d", plan.oceanDistance, config.MAX_OCEAN_DISTANCE),
		string.format("ground=%.1f elevated=%.1f transitions=%d",
			plan.groundDistance, plan.elevatedDistance, plan.heightTransitions),
		"points=" .. #plan.points .. "/" .. config.MAX_POINTS,
		"visuals=" .. plan.visualCount .. "/" .. config.MAX_VISUALS,
		"blockers=" .. context.blockerCount)
	return plan
end

-- 先登记归属再初始化，后续任意步骤失败都能清理已创建的实体。
local function SpawnOwned(run, prefab, point)
	local ent = SpawnPrefab(prefab)
	if ent == nil then error("Cannot spawn train prefab: " .. prefab) end
	table.insert(run.entities, ent)
	ent._aip_train_run_id = run.id
	ent:AddTag("aip_train_temporary")
	ent:AddTag("NOCLICK")
	ent.persists = false
	ent.Transform:SetPosition(point.x, point.y, point.z)
	return ent
end

-- 按规划下标创建一个临时端点，已存在的有效端点直接复用。
local function EnsurePoint(run, index)
	local ent = run.points[index]
	if ent ~= nil and ent:IsValid() then return ent, false end
	local point = run.plan.points[index]
	if point == nil then return nil, false end
	ent = SpawnOwned(run, "aip_pig_king_train_point", point)
	ent._aip_train_point_index = index
	run.points[index] = ent
	if run.pointLookup ~= nil then run.pointLookup[ent] = index end
	return ent, true
end

-- 按规划下标创建当前可见轨道段，连接器仍复用原月亮轨道绘制组件。
local function EnsureLink(run, index)
	local link = run.links[index]
	if link ~= nil and link:IsValid() then return link, false end
	local first = EnsurePoint(run, index)
	local second = EnsurePoint(run, index + 1)
	if first == nil or second == nil then return nil, false end
	local a, b = run.plan.points[index], run.plan.points[index + 1]
	link = SpawnOwned(run, "aip_pig_king_train_link",
		Point((a.x + b.x) / 2, 0, (a.z + b.z) / 2))
	link._aip_train_segment_index = index
	link.components.aipc_orbit_link:Link(first, second)
	run.links[index] = link
	return link, true
end

-- 移除已经驶离窗口的轨道和端点，让交叉路线不会继续叠在当前画面中。
local function RetireBefore(run, firstSegment)
	local retiredLinks, retiredPoints = 0, 0
	for index, link in pairs(run.links) do
		if index < firstSegment and link:IsValid() and link._aip_train_run_id == run.id then
			link:Remove()
			retiredLinks = retiredLinks + 1
		end
	end
	for index, point in pairs(run.points) do
		if index < firstSegment and point:IsValid() and point._aip_train_run_id == run.id then
			point:Remove()
			retiredPoints = retiredPoints + 1
		end
	end
	return retiredPoints, retiredLinks
end

-- 展示乘客身后一段、当前段和后续三段，规划坐标本身仍完整保存在内存中。
function Track.UpdateWindow(run, pointIndex)
	local pointTotal = #run.plan.points
	local firstSegment = math.max(1, pointIndex - config.TRACK_RETAIN_BEHIND)
	local lastSegment = math.min(pointTotal - 1, pointIndex + config.TRACK_LOOKAHEAD - 1)
	local createdPoints, createdLinks = 0, 0
	for index = firstSegment, lastSegment + 1 do
		local _, created = EnsurePoint(run, index)
		if created then createdPoints = createdPoints + 1 end
	end
	for index = firstSegment, lastSegment do
		local _, created = EnsureLink(run, index)
		if created then createdLinks = createdLinks + 1 end
	end
	local retiredPoints, retiredLinks = RetireBefore(run, firstSegment)
	run.trackWindow = { firstSegment = firstSegment, lastSegment = lastSegment,
		firstPoint = firstSegment, lastPoint = math.min(pointTotal, lastSegment + 1) }
	Debug("track-window", "run=" .. tostring(run.id), "point=" .. tostring(pointIndex),
		string.format("segments=%d->%d", firstSegment, lastSegment),
		string.format("points=%d->%d", run.trackWindow.firstPoint, run.trackWindow.lastPoint),
		string.format("created=%d/%d", createdPoints, createdLinks),
		string.format("retired=%d/%d", retiredPoints, retiredLinks))
	return run.trackWindow
end

-- 创建本次体验专用矿车，不进入物品栏、不提供耐久或掉落收益。
function Track.SpawnCar(run)
	local car = SpawnOwned(run, "aip_pig_king_train_car", run.plan.station)
	car:Hide()
	return car
end

-- 只移除运行记录中的自有实体，永久轨道与其他乘客的线路均不受影响。
function Track.Cleanup(run)
	for i = #run.entities, 1, -1 do
		local ent = run.entities[i]
		if ent:IsValid() and ent._aip_train_run_id == run.id then ent:Remove() end
	end
	run.entities = {}
	run.points = {}
	run.links = {}
	run.pointLookup = {}
	run.trackWindow = nil
end

return Track
