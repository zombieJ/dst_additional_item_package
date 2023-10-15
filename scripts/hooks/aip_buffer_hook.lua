----------------------------- Buffer 管理方法 -----------------------------

local _G = GLOBAL

local globalBuffers = {}

-- 【双端】注册 Buffer
function _G.aipBufferRegister(name, info)
	globalBuffers[name] = info
end

-- 【双端】获取 Buffer 函数
function _G.aipBufferFn(name, fnName)
	return (globalBuffers[name] or {})[fnName]
end

-- 【双端】获取 Buffer 数据，目前只能获得 endTime
function _G.aipBufferInfos(inst)
	if inst == nil or inst._aipBufferGUID == nil then
		return {}
	end

	-- 找到 Buffer 对象
	local buffer = _G.Ents[inst._aipBufferGUID]

	return (
		buffer ~= nil and
		buffer:IsValid() and
		buffer._aipBufferInfos ~= nil and
		buffer._aipBufferInfos(buffer)
	)
end

-- 【双端】获取 Buffer 是否存在
function _G.aipBufferExist(inst, name)
	local bufferInfos = _G.aipBufferInfos(inst)

	return bufferInfos[name] ~= nil

	-- if inst == nil or inst._aipBufferGUID == nil then
	-- 	return false
	-- end

	-- -- 找到 Buffer 对象
	-- local buffer = _G.Ents[inst._aipBufferGUID]

	-- return (
	-- 	buffer ~= nil and
	-- 	buffer:IsValid() and
	-- 	buffer._aipBufferExist ~= nil and
	-- 	buffer._aipBufferExist(buffer, name)
	-- )
end

-- 【服务端】删除 Buffer，实际上是剩余时间改为 0
function _G.aipBufferRemove(inst, name)
	if _G.aipBufferExist(inst, name) then
		-- 找到 Buffer 对象
		local buffer = _G.Ents[inst._aipBufferGUID]
		buffer._buffers[name].duration = 0
	end
end

-- 获取 Buffer 实体
local function getBuffInst(inst)
	local buffer = nil

	local children = inst.children or {}
	for child, exist in pairs(children) do
		if exist and child:IsValid() and child.prefab == "aip_0_buffer" then
			buffer = child
			break
		end
	end

	return buffer
end

-- 获取 Buffer 数据
function _G.aipBufferInfo(inst, name)
	local buffer = getBuffInst(inst)

	if buffer ~= nil and buffer._buffers[name] ~= nil then
		return buffer._buffers[name]
	end
end

-- 【服务端】创建 Buffer
function _G.aipBufferPatch(source, inst, name, duration)
	------------------------------- 准备阶段 -------------------------------
	-- 复用 Buffer 对象
	local buffer = getBuffInst(inst)

	-- 没有就创建一个
	if buffer == nil then
		buffer = inst:SpawnChild("aip_0_buffer")
	end

	if buffer == nil then
		_G.aipPrint("Buffer 创建失败！", name, inst.prefab)
		return
	end

	------------------------------- 添加数据 -------------------------------
	if buffer._buffers[name] == nil then
		-- 初始化 Buff
		local info = {
			startTime = _G.GetTime(), -- 记录启动时间
			data = {}, -- 一些额外的信息记录
		}
		buffer._buffers[name] = info

		-- 全局启动函数
		local startFn = _G.aipBufferFn(name, "startFn")
		if startFn ~= nil then
			startFn(source, inst, { data = info.data })
		end

		-- 额外添加特效
		local fxName = _G.aipBufferFn(name, "fx")
		if fxName ~= nil then
			local fx = _G.SpawnPrefab(fxName)
			inst:AddChild(fx)
			info.fx = fx
		end
	end

	buffer._buffers[name].srcGUID = source ~= nil and source.GUID

	-- local mergedDuration = duration or 2
	-- if buffer._buffers[name].duration ~= nil then -- 如果现有的更长就不替换
	-- 	mergedDuration = math.max(mergedDuration, buffer._buffers[name].duration)
	-- end
	-- buffer._buffers[name].duration = mergedDuration

	-- 设置结束时间
	local now = _G.GetTime()
	local endTime = now + (duration or 2)

	if buffer._buffers[name].endTime ~= nil then -- 如果现有的更长就不替换
		endTime = math.max(endTime, buffer._buffers[name].endTime)
	end

	buffer._buffers[name].endTime = endTime

	-- inst._buffers[name].fn = info.fn
	-- inst._buffers[name].startFn = info.startFn
	-- inst._buffers[name].endFn = info.endFn
	-- inst._buffers[name].clientFn = info.clientFn

	-- inst._buffers[name].showFX = info.showFX

	------------------------------- 更新状态 -------------------------------
	-- 更新交给 aip_0_buffer 自己来做，我们只同步 names
	buffer._aipSyncNames(buffer)
end

----------------------------------------------------------------
--                             UI                             --
----------------------------------------------------------------
local InventoryBar = require("widgets/inventorybar")
local BufferList = require("widgets/aip_buffer_list")
local UIFONT = _G.UIFONT

local originRebuild = InventoryBar.Rebuild

function InventoryBar:Rebuild()
	-- 调用原始的重置 UI
	local ret = originRebuild(self)

	-- 重置 Buffer UI
	if self._aipBufferList ~= nil then
        self._aipBufferList:Kill()
        self._aipBufferList = nil
    end

	-- 添加额外的 Buffer
	local bufferList = self.toprow:AddChild(BufferList(self.owner))
	bufferList:SetPosition(0, 90)

	self._aipBufferList = bufferList

	return ret
end