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

	for i = start, math.min(len + start - 1, #tbl) do
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

			str = str .. "[" .. vType .. ": " .. tostring(parsed) .. "]" .. split
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

-- 返回(0 ~ 360)两个角度的偏差值
function _G.aipDiffAngle(a1, a2)
	local min = math.min(a1, a2)
	local max = math.max(a1, a2)

	local diff1 = max - min
	local diff2 = min + 360 - max

	return math.min(diff1, diff2)
end

-- 返回两点之间的距离（无视 Y 坐标）
function _G.aipDist(p1, p2)
	local dx = p1.x - p2.x
	local dz = p1.z - p2.z
	return math.pow(dx*dx+dz*dz, 0.5)
end

function _G.aipRandomEnt(ents)
	if #ents == 0 then
		return nil
	end
	return ents[math.random(#ents)]
end

--------------------------------------- 辅助 ---------------------------------------
function _G.aipFindNearPlayers(inst, dist)
	local NOTAGS = { "FX", "NOCLICK", "DECOR", "playerghost", "INLIMBO" }
	local x, y, z = inst.Transform:GetWorldPosition()
	local ents = TheSim:FindEntities(x, 0, z, dist, { "player", "_health" }, NOTAGS)
	return ents
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
function _G.aipGetSpawnPoint(pt, distance)
	-- 不在陆地就随便找一个陆地
    if not _G.TheWorld.Map:IsAboveGroundAtPoint(pt:Get()) then
        pt = _G.FindNearbyLand(pt) or pt
    end

	-- 找范围内可以走到的路径
	local offset = _G.FindWalkableOffset(pt, math.random() * 2 * _G.PI, distance or 40, 12, true)
	if offset ~= nil then
		offset.x = offset.x + pt.x
		offset.z = offset.z + pt.z
		return offset
	end

	-- 随机找一个附近的点
	for i = distance, distance + 100, 10 do
		local nextOffset = _G.FindValidPositionByFan(
			math.random() * 2 * _G.PI, distance, nil,
			function(offset)
				local x = pt.x + offset.x
				local y = pt.y + offset.y
				local z = pt.z + offset.z
				return _G.TheWorld.Map:IsAboveGroundAtPoint(x, y, z)
			end
		)

		if nextOffset ~= nil then
			nextOffset.x = nextOffset.x + pt.x
			nextOffset.z = nextOffset.z + pt.z
			return nextOffset
		end
	end
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

function _G.aipFindEnt(...)
	for _, ent in pairs(_G.Ents) do
		-- 检测图腾
		if ent:IsValid() and table.contains(arg, ent.prefab) then
			return ent
		end
	end

	return nil
end

-- 是暗影生物
_G.aipShadowTags = { "shadow", "shadowminion", "shadowchesspiece", "stalker", "stalkerminion" }

function _G.aipIsShadowCreature(inst)
	for i, tag in ipairs(_G.aipShadowTags) do
		if inst:HasTag(tag) then
			return true
		end
	end
	return false
end

--------------------------------------- RPC ---------------------------------------
-- RPC 发送时自动会带上 player 作为第一个参数
function _G.aipRPC(funcName, ...)
	SendModRPCToServer(MOD_RPC[env.modname][funcName], _G.unpack(arg))
end

-- 添加 aipc_buffer
function _G.patchBuffer(inst, name, duration, fn)
	if inst.components.aipc_buffer == nil then
		inst:AddComponent("aipc_buffer")
	end

	inst.components.aipc_buffer:Patch(name, duration, fn)
end

-- 存在 aipc_buffer
function _G.hasBuffer(inst, name)
	if inst.components.aipc_buffer ~= nil then
		return inst.components.aipc_buffer.buffers[name] ~= nil
	end

	return false
end
