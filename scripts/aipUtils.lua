local _G = GLOBAL

--------------------------------------- 表格 ---------------------------------------
function _G.aipCountTable(tbl)
	local count = 0
	local lastKey = nil
	local lastVal = nil
	for k, v in pairs(tbl) do
		count = count + 1
		lastKey = k
		lastVal = v
	end

	-- arg 会带上一个 n 表示数量
	if lastKey == "n" and type(lastVal) == "number" then
		count = count - 1
	end

	return count
end

-- 查询是否在表格里
function _G.aipInTable(tbl, match)
	local list = tbl or {}
	for i, item in ipairs(list) do
		if item == match then
			return true
		end
	end

	return false
end

-- 打平表格，去除中间的空格并且保持顺序
function _G.aipFlattenTable(originTbl)
	local targetTbl = {}
	local tbl = originTbl or {}
	local count = _G.aipCountTable(tbl)

	local i = 1
	for i = 1, 10000 do
		local current = tbl[i]
		if current ~= nil then
			table.insert(targetTbl, current)
		end

		if #targetTbl >= count then
			break
		end
	end

	return targetTbl
end

function _G.aipTableRemove(tbl, item)
	for i, v in ipairs(tbl) do
		if v == item then
			table.remove(tbl, i)
		end
	end
end

function _G.aipTableSlice(tbl, start, len)
	local list = {}
	local finalStart = start or 1
	local finalLen = len or #tbl

	for i = finalStart, math.min(finalLen + finalStart - 1, #tbl) do
		table.insert(list, tbl[i])
	end
	return list
end

function _G.aipTableIndex(tbl, item)
	for i, v in ipairs(tbl) do
		if v == item then
			return i
		end
	end

	return nil
end

-- 过滤表格
function _G.aipFilterTable(originTbl, filterFn)
	local tbl = {}
	for i, v in ipairs(originTbl) do
		if filterFn(v, i) then
			table.insert(tbl, v)
		end
	end
	return tbl
end


-- 按照 key 过滤表格
function _G.aipFilterKeysTable(originTbl, keys)
	local tbl = {}

	for k, v in pairs(originTbl) do
		if not _G.aipInTable(keys, k) then
			tbl[k] = v
		end
	end

	return tbl
end

-- 获取 key
function _G.aipTableKeys(tbl)
	local keys = {}
	for k, v in pairs(tbl) do
		table.insert(keys, k)
	end
	return keys
end

--------------------------------------- 调试 ---------------------------------------
function _G.aipCommonStr(showType, split, ...)
	local count = _G.aipCountTable(arg)
	local str = ""

	for i = 1, count do
		local v = arg[i]
		local parsed = v
		local vType = type(v)

		if showType then
			-- 显示类别
			if parsed == nil then
				parsed = "(nil)"
			elseif parsed == true then
				parsed = "(true)"
			elseif parsed == false then
				parsed = "(false)"
			elseif parsed == "" then
				parsed = "(empty)"
			elseif vType == "table" then
				local isFirst = true
				parsed = "{"
				for v_k, v_v in pairs(v) do
					if not isFirst then
						parsed = parsed .. ", "
					end
					isFirst = false

					parsed = parsed .. tostring(v_k) .. ":" ..tostring(v_v)
				end
				parsed = parsed .. "}"
			end

			if vType == "string" then
				str = str.."'"..tostring(parsed).."'"..split
			else
				str = str .. "[" .. vType .. ": " .. tostring(parsed) .. "]" .. split
			end
		else
			-- 显示文字
			str = str .. tostring(parsed) .. split
		end

	end

	return str
end

function _G.aipCommonPrint(showType, split, ...)
	local str = "[AIP] ".._G.aipCommonStr(showType, split, ...)

	print(str)

	return str
end

function _G.aipStr(...)
	return _G.aipCommonStr(false, "", ...)
end

function _G.aipPrint(...)
	return _G.aipCommonPrint(false, " ", ...)
end

function _G.aipTypePrint(...)
	return _G.aipCommonPrint(true, " ", ...)
end

_G.aipGetModConfig = GetModConfigData

function _G.aipGetAnimState(inst)
	local match = false
	local data = {}

	if inst then
		local str = inst.GetDebugString and inst:GetDebugString()
		if str then
			local bank, build, anim

			bank, build, anim = string.match(str, "AnimState: bank: (.*) build: (.*) anim: (.*) anim")
			if not anim then
				bank, build, anim = string.match(str, "AnimState: bank: (.*) build: (.*) anim: (.*) ..")
			end

			data.bank = string.split(bank or "", " ")[1]
			data.build = string.split(build or "", " ")[1]
			data.anim = string.split(anim or "", " ")[1]

			if data.bank and data.build and data.anim then
				match = true
			end
		end
	end

	return match and data or nil
end

--------------------------------------- 文本 ---------------------------------------
function _G.aipJoin(strList, spliter)
	local str = ""
	local first = true
	for i, val in ipairs(strList) do
		if first then
			first = false
		else
			str = str..spliter
		end

		str = str..val
	end

	return str
end

function _G.aipSplit(str, spliter)
	local list = {}
	local str = str..spliter
	for i in str:gmatch("(.-)"..spliter) do
		table.insert(list, i)
	 end
	 return list
end

--------------------------------------- 角度 ---------------------------------------
-- 返回角度：0 ~ 360
function _G.aipGetAngle(src, tgt)
	local direction = (tgt - src):GetNormalized()
	local angle = math.acos(direction:Dot(_G.Vector3(1, 0, 0))) / _G.DEGREES
	if direction.z < 0 then
		angle = 360 - angle
	end
	return angle
end

-- 从点起按照设定角度前进一段距离
function _G.aipAngleDist(sourcePos, angle, distance)
	local radius = angle / 180 * _G.PI
	return _G.Vector3(sourcePos.x + math.cos(radius) * distance, sourcePos.y, sourcePos.z + math.sin(radius) * distance)
end

-- 返回(0 ~ 360)两个角度的偏差值
function _G.aipDiffAngle(a1, a2)
	local min = math.min(a1, a2)
	local max = math.max(a1, a2)

	local diff1 = max - min
	local diff2 = min + 360 - max

	return math.min(diff1, diff2)
end

-- 返回两点之间的距离（默认无视 Y 坐标）
function _G.aipDist(p1, p2, includeY)
	-- 无效坐标，则返回超级远
	if p1 == nil or p2 == nil then
		return 9999999
	end

	local dx = p1.x - p2.x
	local dz = p1.z - p2.z
	local dy = p1.y - p2.y

	if includeY then
		return math.pow(dx*dx+dy*dy+dz*dz, 1/3)
	else
		return math.pow(dx*dx+dz*dz, 0.5)
	end
end

function _G.aipRandomEnt(ents)
	if #ents == 0 then
		return nil
	end
	return ents[math.random(#ents)]
end

--------------------------------------- 辅助 ---------------------------------------
-- 找到附近符合名字的物品，可以是一个对象 或者 是一个 点
function _G.aipFindNearEnts(inst, prefabNames, distance, includeInv)
	local x, y, z = 0, 0, 0
	if inst.Transform ~= nil then
		x, y, z = inst.Transform:GetWorldPosition()
	elseif inst.x ~= nil and inst.y ~= nil and inst.z ~= nil then
		x = inst.x
		y = inst.y
		z = inst.z
	end
	local ents = TheSim:FindEntities(x, 0, z, distance or 10)
	local prefabs = {}

	for _, ent in pairs(ents) do
		if ent:IsValid() and table.contains(prefabNames, ent.prefab) then
			table.insert(prefabs, ent)
		end
	end

	-- 是否包含身上物品
	if includeInv then
		return prefabs
	end

	return _G.aipFilterTable(prefabs, function(inst)
        return	inst.components.inventoryitem == nil or
				inst.components.inventoryitem:GetGrandOwner() == nil
    end)
end

function _G.aipFindNearPlayers(inst, dist)
	if inst == nil then
		return {}
	end

	-- local NOTAGS = { "FX", "NOCLICK", "DECOR", "playerghost", "INLIMBO" }
	local x, y, z = inst.Transform:GetWorldPosition()
	-- local ents = TheSim:FindEntities(x, 0, z, dist, { "player", "_health" }, NOTAGS)
	-- return ents
	return _G.FindPlayersInRange(x, y, z, dist, true)
end

-- 降级值如果没有的话
function fb(value, defaultValue)
	if value ~= nil then
		return value
	end
	return defaultValue
end

-- 在目标位置创建
function _G.aipSpawnPrefab(inst, prefab, tx, ty, tz)
	local tgt = _G.SpawnPrefab(prefab)

	if tgt == nil then
		return nil
	end

	if inst ~= nil then
		local x, y, z = inst.Transform:GetWorldPosition()
		tgt.Transform:SetPosition(fb(tx, x), fb(ty, y), fb(tz, z))
	else
		tgt.Transform:SetPosition(fb(tx, 0), fb(ty, 0), fb(tz, 0))
	end
	return tgt
end

-- 替换单位（如果是物品则替换对应物品栏），原生也有一个 ReplacePrefab
function _G.aipReplacePrefab(inst, prefab, tx, ty, tz)
	local tgt = _G.aipSpawnPrefab(inst, prefab, tx, ty, tz)

	if tgt == nil then
		return nil
	end

	if inst.components.inventoryitem ~= nil then
		local container = inst.components.inventoryitem:GetContainer()
		local slot = inst.components.inventoryitem:GetSlotNum()

		inst:Remove()

		if container ~= nil then
			container:GiveItem(tgt, slot)
		end
	else
		inst:Remove()
	end

	return tgt
end

-- 获取一个可访达的路径，默认 40。TODO：优化一下避免在建筑附近生成
function _G.aipGetSpawnPoint(startPT, distance)
	local dist = distance or 40
	local pt = nil

	-- 不在陆地就随便找一个陆地作为起始点
	local px, py, pz = startPT:Get()
    if not _G.TheWorld.Map:IsAboveGroundAtPoint(px, py, pz, false) then
        startPT = _G.FindNearbyLand(startPT) or startPT
    end

	-- 1. 找范围内可以走到的路径
	local offset = _G.FindWalkableOffset(startPT, math.random() * 2 * _G.PI, dist, 12, true)
	if offset ~= nil then
		offset.x = offset.x + startPT.x
		offset.z = offset.z + startPT.z
		return offset
	end

	-- 2. 随机找一个附近的点
	for i = dist, dist + 100, 10 do
		local nextOffset = _G.FindValidPositionByFan(
			math.random() * 2 * _G.PI, dist, nil,
			function(offset)
				local x = startPT.x + offset.x
				local y = startPT.y + offset.y
				local z = startPT.z + offset.z
				return _G.TheWorld.Map:IsAboveGroundAtPoint(x, y, z, false)
			end
		)

		if nextOffset ~= nil then
			nextOffset.x = nextOffset.x + startPT.x
			nextOffset.z = nextOffset.z + startPT.z
			return nextOffset
		end
	end

	-- 3. 继续降级往回找
	for i = dist, 0, -1 do
		local offset = _G.FindWalkableOffset(
			startPT, math.random() * 2 * _G.PI, i, 12, true,
			true, nil, false -- ignore_walls, customcheckfn, allow_water
	)
		if offset ~= nil then
			offset.x = offset.x + startPT.x
			offset.z = offset.z + startPT.z
			return offset
		end
	end

	-- 4. 都没有的时候就不返回了
	return nil
end

-- 找到靠近海边的点
function _G.aipFindNearbyOcean(pt, dist)
	local oceanPT = nil
	
	for i = 2, 100, 2 do
		oceanPT = _G.FindNearbyOcean(pt, i)
		if oceanPT ~= nil then
			break
		end
	end

	-- 根据海洋点开始转圈找最远的点
	if oceanPT ~= nil then
		local startAngle = 0

		-- 第一次先找到陆地的点作为起点
		for i = 0, 360 do
			local angle = _G.PI * 2 * i / 360
			local tgtX = oceanPT.x + math.cos(angle) * dist
			local tgtZ = oceanPT.z + math.sin(angle) * dist

			if _G.TheWorld.Map:IsAboveGroundAtPoint(tgtX, 0, tgtZ, false) then
				startAngle = i
				break
			end
		end

		-- 转一圈，找到海洋的起点
		for i = startAngle, startAngle + 360 do
			local angle = _G.PI * 2 * i / 360
			local tgtX = oceanPT.x + math.cos(angle) * dist
			local tgtZ = oceanPT.z + math.sin(angle) * dist

			if not _G.TheWorld.Map:IsAboveGroundAtPoint(tgtX, 0, tgtZ, false) then
				startAngle = i
				break
			end
		end

		-- 转一圈，找到海洋的终点
		local endAngle = 0
		for i = startAngle, startAngle + 360 do
			local angle = _G.PI * 2 * i / 360
			local tgtX = oceanPT.x + math.cos(angle) * dist
			local tgtZ = oceanPT.z + math.sin(angle) * dist

			if _G.TheWorld.Map:IsAboveGroundAtPoint(tgtX, 0, tgtZ, false) then
				endAngle = i
				break
			end
		end

		-- 中间点找到了
		if startAngle ~= endAngle then
			local angle = _G.PI * (startAngle + endAngle) / 360
			return _G.Vector3(
				oceanPT.x + math.cos(angle) * dist,
				0,
				oceanPT.z + math.sin(angle) * dist
			)
		end
	end

	return oceanPT
end

-- 是自然地皮
function _G.aipIsNaturalPoint(pt)
	-- 没有给与有效点
	if pt == nil then
		return nil
	end

	local tile = _G.TheWorld.Map:GetTileAtPoint(pt.x, pt.y, pt.z)

	local DEFAULT_VALID_TILE_TYPES = {
		[GROUND.DIRT] = true,
		[GROUND.SAVANNA] = true,
		[GROUND.GRASS] = true,
		[GROUND.FOREST] = true,
		[GROUND.MARSH] = true,

		-- 月岛
		[GROUND.METEOR] = true,
	
		-- CAVES
		[GROUND.CAVE] = true,
		[GROUND.FUNGUS] = true,
		[GROUND.SINKHOLE] = true,
		[GROUND.MUD] = true,
		[GROUND.FUNGUSRED] = true,
		[GROUND.FUNGUSGREEN] = true,
	
		--EXPANDED FLOOR TILES
		[GROUND.DECIDUOUS] = true,
	}

	return DEFAULT_VALID_TILE_TYPES[tile] and pt or nil
end

-- 获取一个隐秘地点，如果是人工地皮就无效返回 nil
function _G.aipGetSecretSpawnPoint(pt, minDistance, maxDistance, emptyDistance)
	local tgtPT = nil
	emptyDistance = emptyDistance or 0

	-- 如果范围内存在物体，我们就找数量最少的地方
	local tgtEntCnt = 99999999

	local mergedMaxDistance = maxDistance
	if minDistance == maxDistance then
		mergedMaxDistance = minDistance + 1
	end

	local step = 20 / (mergedMaxDistance - minDistance)

	for distance = minDistance, maxDistance, step do
		local pos = _G.aipGetSpawnPoint(pt, distance)

		-- 如果不是自然地皮就跳过
		pos = _G.aipIsNaturalPoint(pos)

		if pos ~= nil then
			local ents = TheSim:FindEntities(pos.x, 0, pos.z, emptyDistance)
			if #ents < tgtEntCnt then
				tgtPT = pos
				tgtEntCnt = #ents
			end
		end
	end

	if tgtPT == nil then
		tgtPT = _G.aipGetSpawnPoint(pt, minDistance)

		-- 如果不是自然地皮就跳过
		tgtPT = _G.aipIsNaturalPoint(tgtPT)
	end

	return tgtPT
end

-- 和 TheMap:FindRandomPointInOcean 相似，但是通过地图上的岩石附近创造
function _G.aipFindRandomPointInOcean(radius, prefabRadius)
	local w, h = _G.TheWorld.Map:GetSize()
	local halfW = w/2 * _G.TILE_SCALE - 50 -- 裁剪边缘
	local halfH = h/2 * _G.TILE_SCALE - 50 -- 裁剪边缘
	
	local pos = nil
	for i = 1, 100 do
		local x = math.random(-halfW, halfW)
		local z = math.random(-halfH, halfH)
		local rndPos = _G.Vector3(x, 0, z)

		if _G.aipValidateOceanPoint(rndPos, radius) then
			pos = rndPos
			break
		end
	end

	return pos
end

function _G.aipFindRandomPointInLand(emptyDistance)
	local w, h = _G.TheWorld.Map:GetSize()
	local halfW = w/2 * _G.TILE_SCALE - 50 -- 裁剪边缘
	local halfH = h/2 * _G.TILE_SCALE - 50 -- 裁剪边缘

	local pos = nil
	for i = 1, 100 do
		local x = math.random(-halfW, halfW)
		local z = math.random(-halfH, halfH)
		local rndPos = _G.Vector3(x, 0, z)

		if _G.TheWorld.Map:IsAboveGroundAtPoint(x, 0, z, false) then
			pos = _G.aipGetSecretSpawnPoint(rndPos, 0, 100, emptyDistance)
			if pos ~= nil then
				break
			end
		end
	end

	return pos
end

function _G.aipValidateOceanPoint(pt, radius, prefabRadius)
	radius = radius or 0
	prefabRadius = prefabRadius or radius or 0

	-- 间隔一段地皮判断一次
	for rx = pt.x - radius, pt.x + radius, _G.TILE_SCALE * 0.8 do
		for rz = pt.z - radius, pt.z + radius, _G.TILE_SCALE * 0.8 do
			if not _G.TheWorld.Map:IsOceanAtPoint(rx, 0, rz) then
				return false
			end
		end
	end

	-- 附近允许石头、漂流瓶
	local ents = TheSim:FindEntities(pt.x, 0, pt.z, prefabRadius)
	for i, ent in ipairs(ents) do
		if not table.contains({
			"seastack",
			"messagebottle",
			"float_fx_back",
			"float_fx_front",
			"fireflies",
			"driftwood_log",
		}, ent.prefab) then
			return false
		end
	end

	return true
end

-- 在符合 tag 的地形上，且存在匹配的物品，在改物品附近找一个点
function _G.aipGetTopologyPoint(tag, prefab, dist)
	for i, node in ipairs(_G.TheWorld.topology.nodes) do
		if table.contains(node.tags, tag) then
			local x = node.cent[1]
			local z = node.cent[2]

			-- 找到 匹配的物品
			local ents = TheSim:FindEntities(x, 0, z, 40)
			local fissures = _G.aipFilterTable(ents, function(inst)
				return inst.prefab == prefab
			end)

			-- 使用第一个匹配的物品
			local first = fissures[1]
			if first ~= nil then
				return first:GetPosition()
			end
		end
	end

	return nil
end

function entMatchNames(prefabNames, ent)
	return ent ~= nil and ent:IsValid() and table.contains(prefabNames, ent.prefab)
end

-- 按照参数找到所有符合名字列表的 prefab（TheSim:FindFirstEntityWithTag("malbatross")）
function _G.aipFindEnt(...)
	for _, ent in pairs(_G.Ents) do
		-- 检测图腾
		if entMatchNames(arg, ent) then
			return ent
		end
	end

	return nil
end

function _G.aipFindEnts(...)
	local list = {}

	for _, ent in pairs(_G.Ents) do
		-- 检测图腾
		if entMatchNames(arg, ent) then
			table.insert(list, ent)
		end
	end

	return list
end

function _G.aipFindRandomEnt(...)
	local list = _G.aipFindEnts(...)

	return _G.aipRandomEnt(list)
end

-- 是暗影生物
_G.aipShadowTags = { "shadow", "shadowminion", "shadowchesspiece", "stalker", "stalkerminion", "aip_shadowcreature" }

function _G.aipIsShadowCreature(inst)
	if not inst then
		return false
	end

	for i, tag in ipairs(_G.aipShadowTags) do
		if inst:HasTag(tag) then
			return true
		end
	end
	return false
end

function _G.aipCommonStore()
	return _G.TheWorld.components ~= nil and _G.TheWorld.components.world_common_store
end

function _G.aipRemove(inst)
	if inst ~= nil and inst:IsValid() then
		if inst.components.stackable ~= nil then
			inst.components.stackable:Get():Remove()
		else
			inst:Remove()
		end
	end
end

-- 丢弃物品，产生一个物理抛下的效果
function _G.aipFlingItem(loot, pt)
	if loot ~= nil and loot:IsValid() then
        if pt ~= nil then
            loot.Transform:SetPosition(pt:Get())
        end

        local min_speed =  0
        local max_speed = 2
        local y_speed = 8
        local y_speed_variance = 4

        if loot.Physics ~= nil then
            local angle = math.random() * 2 * _G.PI
            local speed = min_speed + math.random() * (max_speed - min_speed)
            if loot:IsAsleep() then
                local radius = .5 * speed
                loot.Transform:SetPosition(
                    pt.x + math.cos(angle) * radius,
                    0,
                    pt.z - math.sin(angle) * radius
                )
            else
                local sinangle = math.sin(angle)
                local cosangle = math.cos(angle)
                loot.Physics:SetVel(speed * cosangle, _G.GetRandomWithVariance(y_speed, y_speed_variance), speed * -sinangle)
            end
        end
    end
end

function _G.aipGet(inst, paths)
	local current = inst

	if type(paths) == "string" then
		paths = _G.aipSplit(paths, "|")
	end

	for i, path in ipairs(paths) do
		if current ~= nil then
			current = current[path]
		end
	end

	return current
end

--------------------------------------- RPC ---------------------------------------
-- RPC 发送时自动会带上 player 作为第一个参数
function _G.aipRPC(funcName, ...)
	SendModRPCToServer(MOD_RPC[env.modname][funcName], ...)
end

-- 获取玩家手持的物品，仅在 AddComponentAction 中使用
function _G.aipGetActionableItem(doer)
	local inventory = doer.replica.inventory
	if inventory ~= nil then
		local item = inventory:GetEquippedItem(_G.EQUIPSLOTS.HANDS)
		if item ~= nil and item.components.aipc_action_client ~= nil then
			return item
		end
	end
	return nil
end

------------------------------------- 简易 AI -------------------------------------
-- 纯时序 AI，返回 false 则继续执行下一个 Step
function _G.aipQueue(tasks)
	for i, fn in ipairs(tasks) do
		-- 如果为 true 则不用再往下了
		if fn() then
			return
		end
	end
end
