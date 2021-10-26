-- 每秒执行一次效果，如果所有的 buffer duration 都结束了，就删除这个组件
local function DoEffect(inst, self)
	local allRemove = true
	local rmNames = {}

	for name, info in pairs(self.buffers) do
		info.duration = info.duration - 1

		if info.fn ~= nil then
			info.fn(inst)
		end

		-- 清理过期的 buffer
		if info.duration <= 0 then
			table.insert(rmNames, name)
		else
			allRemove = false
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

	self.task = self.inst:DoPeriodicTask(1, DoEffect, 0.1, self)

	-- TODO: Test this
	self.fx = SpawnPrefab("aip_buffer_fx")
	self.inst:AddChild(self.fx)
end)

function Buffer:Patch(name, duration, fn, showFX)
	self.buffers[name] = {
		duration = duration or 2,
		fn = fn,
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