-- 多队列计时器组件
local Timer = Class(function(self, inst)
	self.inst = inst

	self.id = 0
	self.list = {}
	self.names = {}
end)

function Timer:Interval(step, func, ...)
	self.id = self.id + 1
	local myId = self.id
	local interval = self.inst:DoPeriodicTask(step, function(...)
		local result = func(...)
		if result == false then
			self:Kill(myId)
		end

		return result
	end, ...)
	self.list[myId] = interval

	return myId
end

function Timer:KillName(name)
	local id = self.names[name]
	if id ~= nil then
		self:Kill(id)
		self.names[name] = nil
	end
end

function Timer:NamedInterval(name, step, func, ...)
	self:KillName(name)

	local id = self:Interval(step, func, ...)
	self.names[name] = id
end

function Timer:Timeout(step, func, ...)
	self.id = self.id + 1
	local myId = self.id
	local timeout = self.inst:DoTaskInTime(step, function(...)
		self:Kill(myId)
		return func(...)
	end, ...)
	self.list[myId] = timeout

	return myId
end

function Timer:Kill(id)
	local timer = self.list[id]
	if timer then
		timer:Cancel()
		self.list[id] = nil

		-- 删掉对应的名字
		for f_name, f_id in pairs(self.names) do
			if f_id == id then
				self.names[f_name] = nil
			end
		end
	end
end

function Timer:KillAll()
	for id, timer in pairs(self.list) do
		self:Kill(id)
	end

	self.list = {}
	self.names = {}
end

Timer.OnRemoveFromEntity = Timer.KillAll
Timer.OnRemoveEntity = Timer.KillAll

return Timer