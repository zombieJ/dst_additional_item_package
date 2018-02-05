-- 多队列计时器组件
local Timer = Class(function(self, inst)
	self.inst = inst

	self.id = 0
	self.list = {}
end)

function Timer:Interval(step, func, ...)
	self.id = self.id + 1
	local myId = self.id
	local interval = self.inst:DoPeriodicTask(step, function(...)
		local result = func(...)
		if result == false then
			self:Remove(myId)
		end

		return result
	end, ...)
	self.list[myId] = interval

	return myId
end

function Timer:Timeout(step, func, ...)
	self.id = self.id + 1
	local myId = self.id
	local timeout = self.inst:DoTaskInTime(step, function(...)
		self:Remove(myId)
		return func(...)
	end, ...)
	self.list[myId] = timeout

	return myId
end

function Timer:Remove(id)
	self.list[id] = nil
end

function Timer:Kill(id)
	local timer = self.list[id]
	if timer then
		timer:Cancel()
		self.list[id] = nil
	end
end

function Timer:KillAll()
	for id, timer in pairs(self.list) do
		self:Kill(id)
	end
end

Timer.OnRemoveFromEntity = Timer.KillAll
Timer.OnRemoveEntity = Timer.KillAll

return Timer