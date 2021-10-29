local Buffer = Class(function(self, inst)
	self.inst = inst
	self.bufferNames = net_string(inst.GUID, "aipc_buffer", "aipc_buffer_dirty")
end)

function Buffer:SyncBuffer(names)
	self.bufferNames:set(names)
end

function Buffer:HasBuffer(tgt)
	local names = self.bufferNames:value()
	local nameList = string.split(names, '|')

	for i, name in ipairs(nameList) do
		if name == tgt then
			return true
		end
	end

	return false
end

return Buffer