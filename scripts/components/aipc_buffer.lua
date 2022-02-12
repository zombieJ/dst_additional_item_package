local interval = 0.5

-- 每秒执行一次效果，如果所有的 buffer duration 都结束了，就删除这个组件
local function DoEffect(inst, self)
	local allRemove = true
	local rmNames = {}

	for name, info in pairs(self.buffers) do
		info.duration = info.duration - interval

		if info.fn ~= nil then
			info.fn(info.source, inst, interval)
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
		if info.endFn ~= nil then
			info.endFn(info.source, inst)
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

function Buffer:Patch(name, source, duration, fn, startFn, endFn, showFX)
	if self.buffers[name] == nil and startFn ~= nil then
		startFn(source, self.inst)
	end

	self.buffers[name] = {
		source = source,
		duration = duration or 2,
		fn = fn,
		startFn = startFn,
		endFn = endFn,
		showFX = showFX,
	}

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