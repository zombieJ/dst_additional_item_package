--[[
	一个可以被睡眠的计时器
]]

local WeakTimer = Class(function(self, inst)
	self.inst = inst

	self.task = nil
	self.func = nil
	self.targetTime = nil
end)

-- 执行当前的任务
function WeakTimer:DoTask()
	self.func(self.inst)
	self:CleanUp()
end

function WeakTimer:Start(timeout, func)
	self:Cancel()

	self.func = func
	self.targetTime = GetTime() + timeout

	self.task = self.inst:DoTaskInTime(timeout, function()
		self:DoTask()
	end)
end

function WeakTimer:Cancel()
	if self.task ~= nil then
		self.task:Cancel()
		self.task = nil
	end
end

function WeakTimer:CleanUp()
	self:Cancel()
	self.targetTime = nil
end

function WeakTimer:GetLeftTime()
	return math.max(0, self.targetTime - GetTime())
end

------------------------------- 休眠逻辑 -------------------------------
function WeakTimer:LongUpdate(dt)
	if self.targetTime ~= nil and self:GetLeftTime() <= 0 then
		self:DoTask()
	end
end

function WeakTimer:OnEntitySleep()
	self:Cancel()
end

function WeakTimer:OnEntityWake()
	self:Cancel()

	if self.targetTime ~= nil then
		self.task = self.inst:DoTaskInTime(self:GetLeftTime(), function()
			self:DoTask()
		end)
	end
end

---------------------------- 加载时重置时间 ----------------------------
function WeakTimer:OnSave()
	if self.targetTime ~= nil then
		return {
			leftTime = self:GetLeftTime()
		}
	end
end

function WeakTimer:OnLoad(data)
	if data ~= nil and data.leftTime ~= nil and self.func ~= nil then
		self:Start(data.leftTime, self.func)
	end
end

WeakTimer.OnRemoveFromEntity = WeakTimer.CleanUp
WeakTimer.OnRemoveEntity = WeakTimer.CleanUp

return WeakTimer