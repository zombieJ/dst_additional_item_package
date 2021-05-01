local _G = GLOBAL

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
-- 替换单位
function _G.aipReplacePrefab(inst, prefab)
	local tgt = _G.SpawnPrefab(prefab)
	local x, y, z = inst.Transform:GetWorldPosition()
	tgt.Transform:SetPosition(x, y, z)
	inst:Remove()
	return tgt
end

-- 获取一个可访达的路径，默认 40。TODO：优化一下避免在建筑附近生成
function _G.aipGetSpawnPoint(pt, distance)
    if not _G.TheWorld.Map:IsAboveGroundAtPoint(pt:Get()) then
        pt = _G.FindNearbyLand(pt, 1) or pt
    end
    local offset = _G.FindWalkableOffset(pt, math.random() * 2 * _G.PI, distance or 40, 12, true)
    if offset ~= nil then
        offset.x = offset.x + pt.x
        offset.z = offset.z + pt.z
        return offset
    end
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