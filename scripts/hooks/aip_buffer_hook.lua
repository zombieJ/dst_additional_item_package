-- Buffer 管理方法

local _G = GLOBAL

local globalBuffers = {}

function _G.aipBufferRegister(name, info)
	globalBuffers[name] = info
end

function _G.aipBufferFn(name, fnName)
	return (globalBuffers[name] or {})[fnName]
end

-- 【服务端】创建 Buffer
function _G.aipBufferPatch(inst, name, source, duration, info)
	local buffer = nil

	------------------------------- 准备阶段 -------------------------------
	-- 复用 Buffer 对象
	for child, exist in pairs(inst.children) do
		if exist and child:IsValid() and child.prefab == "aip_0_buffer" then
			buffer = child
			break
		end
	end

	-- 没有就创建一个
	if buffer == nil then
		buffer = inst:SpawnChild("aip_0_buffer")
	end

	if buffer == nil then
		_G.aipPrint("Buffer 创建失败！", name, inst.prefab)
		return
	end

	------------------------------- 添加数据 -------------------------------
	if inst._buffers[name] == nil then
		-- 初始化 Buff
		inst._buffers[name] = {
			startTime = GetTime(), -- 记录启动时间
			data = {}, -- 一些额外的信息记录
		}

		-- 全局启动函数
		local startFn = _G.aipBufferFn(name, "startFn")
		if startFn ~= nil then
			startFn(source, inst, { data = inst._buffers[name].data })
		end
	end

	inst._buffers[name].srcGUID = source ~= nil and source.GUID
	inst._buffers[name].duration = duration or 2
	-- inst._buffers[name].fn = info.fn
	-- inst._buffers[name].startFn = info.startFn
	-- inst._buffers[name].endFn = info.endFn
	-- inst._buffers[name].clientFn = info.clientFn

	inst._buffers[name].showFX = info.showFX

	------------------------------- 更新状态 -------------------------------
	-- 更新交给 aip_0_buffer 自己来做，我们只同步 names
	inst._aipSyncNames(inst)
end