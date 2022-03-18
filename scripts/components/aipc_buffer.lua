local interval = 0.5

-- 每秒执行一次效果，如果所有的 buffer duration 都结束了，就删除这个组件
local function DoEffect(inst, self)
	local allRemove = true
	local rmNames = {}

	for name, info in pairs(self.buffers) do
		info.duration = info.duration - interval

		-- 参数：源头，目标，间隔，时间差
		local fnData = {
			interval = interval,
			passTime = GetTime() - info.startTime,
			data = info.data,
		}

		-- 全局函数
		local fn = aipGlobalBuffer(name).fn
		if fn ~= nil then
			fn(info.source, inst, fnData)
		end

		if info.fn ~= nil then
			info.fn(info.source, inst, fnData)
		end

		-- 清理过期的 buffer
		if info.duration <= 0 then
			table.insert(rmNames, name)
		else
			allRemove = false
		end
	end

	-- 清除的 buffer 需要一个退出事件处理收尾
	for i, name in ipairs(rmNames) do
		local info = self.buffers[name]

		-- 全局结束函数
		local endFn = aipGlobalBuffer(name).endFn
		if endFn ~= nil then
			endFn(info.source, inst, { data = info.data })
		end

		-- 结束函数
		if info.endFn ~= nil then
			info.endFn(info.source, inst, { data = info.data })
		end
	end

	self.buffers = aipFilterKeysTable(self.buffers, rmNames)
	self:SyncBuffer()

	if allRemove then
		inst:RemoveComponent("aipc_buffer")
		self.task:Cancel()
		self.fx:Remove()
	end
end

local Buffer = Class(function(self, inst)
	self.inst = inst
	self.name = nil
	self.duration = nil
	self.fn = nil
	self.buffers = {}

	self.task = self.inst:DoPeriodicTask(interval, DoEffect, 0.1, self)

	-- TODO: Test this
	self.fx = SpawnPrefab("aip_buffer_fx")
	self.inst:AddChild(self.fx)
end)

function Buffer:Patch(name, source, duration, info)
	if self.buffers[name] == nil then
		-- 初始化 Buff
		self.buffers[name] = {
			startTime = GetTime(), -- 记录启动时间
			data = {}, -- 一些额外的信息记录
		}

		-- 全局启动函数
		local startFn = aipGlobalBuffer(name).startFn
		if startFn ~= nil then
			startFn(source, self.inst, { data = self.buffers[name].data })
		end

		-- 启动函数
		if info.startFn ~= nil then
			info.startFn(source, self.inst, { data = self.buffers[name].data })
		end
	end


	self.buffers[name].source = source
	self.buffers[name].duration = duration or 2
	self.buffers[name].fn = info.fn
	self.buffers[name].startFn = info.startFn
	self.buffers[name].endFn = info.endFn
	self.buffers[name].clientFn = info.clientFn

	self.buffers[name].showFX = info.showFX


	self:SyncBuffer()
end

function Buffer:SyncBuffer(ames)
	local names = ""
	local showFX = false
	for name, ent in pairs(self.buffers) do
		names = names.."|"..name
		showFX = showFX or ent.showFX
	end

	if showFX then
		self.fx:Show()
	else
		self.fx:Hide()
	end

	self.inst.replica.aipc_buffer:SyncBuffer(names)
end

return Buffer