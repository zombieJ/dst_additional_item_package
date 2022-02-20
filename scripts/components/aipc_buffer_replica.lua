local interval = 0.25

-- 客户端执行代码
local function DoEffect(inst, self)
	local nameList = self:GetNames()

	for i, name in ipairs(nameList) do
		local clientFn = aipClientBuffer(name)

		if clientFn ~= nil then
			clientFn(inst)
		end
	end
end

local Buffer = Class(function(self, inst)
	self.inst = inst
	self.bufferNames = net_string(inst.GUID, "aipc_buffer", "aipc_buffer_dirty")

	self.task = inst:DoPeriodicTask(interval, DoEffect, 0.1, self)
end)

function Buffer:SyncBuffer(names)
	self.bufferNames:set(names)
end

function Buffer:GetNames()
	local names = self.bufferNames:value()
	return string.split(names, '|')
end

function Buffer:HasBuffer(tgt)
	local nameList = self:GetNames()

	for i, name in ipairs(nameList) do
		if name == tgt then
			return true
		end
	end

	return false
end

function Buffer:CleanUp()
	self.task:Cancel()
end

Buffer.OnRemoveFromEntity = Buffer.CleanUp
Buffer.OnRemoveEntity = Buffer.CleanUp

return Buffer