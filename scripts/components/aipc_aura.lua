-- 光环组件，每隔 1.5s 检测周围单位并添加光环 buffer（aipc_buffer）组件
local Aura = Class(function(self, inst)
	self.inst = inst
	self.range = 15
	self.bufferName = nil
	self.bufferDuration = nil
	self.mustTags = nil
	self.noTags = nil
	self.interval = 1.5
end)

local function SearchToAddBuffer(inst, self)
	local x, y, z = inst.Transform:GetWorldPosition()
	local ents = TheSim:FindEntities(x, y, z, self.range, self.mustTags, self.noTags)

	for i, ent in ipairs(ents) do
		aipBufferPatch(inst, ent, self.bufferName, self.bufferDuration)
	end
end

function Aura:Start()
	self:Stop()

	self.task = self.inst:DoPeriodicTask(self.interval, SearchToAddBuffer, 0.1, self)
end

function Aura:Stop()
	if self.task ~= nil then
		self.task:Cancel()
		self.task = nil
	end
end

return Aura