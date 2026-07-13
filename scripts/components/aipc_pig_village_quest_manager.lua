local questConfig = require("configurations/aip_pig_village_quest")

local QuestManager = Class(function(self, inst)
	self.inst = inst
	self.lastRefreshDay = nil
	self.refreshTask = nil

	self._onCycleComplete = function()
		self:ScheduleFill(math.random(
			questConfig.DAILY_FILL_DELAY_MIN,
			questConfig.DAILY_FILL_DELAY_MAX
		))
	end

	self.inst:ListenForEvent("ms_cyclecomplete", self._onCycleComplete, TheWorld)
	self:ScheduleFill(math.random(
		questConfig.INITIAL_FILL_DELAY_MIN,
		questConfig.INITIAL_FILL_DELAY_MAX
	))
end)

-- 读取实体所在的世界拓扑区域。
local function GetTopologyId(inst)
	if inst == nil or not inst:IsValid() or TheWorld.Map == nil then
		return nil
	end

	local x, y, z = inst.Transform:GetWorldPosition()
	return TheWorld.Map:GetTopologyIDAtPoint(x, y, z)
end

-- 判断猪窝是否与猪王属于同一个村庄。
function QuestManager:IsVillageHouse(house, kingTopologyId)
	if house == nil or not house:IsValid() or house.prefab ~= "pighouse" then
		return false
	end

	local houseTopologyId = GetTopologyId(house)
	if kingTopologyId ~= nil and houseTopologyId ~= nil then
		return kingTopologyId == houseTopologyId
	end

	return house:GetDistanceSqToInst(self.inst) <= questConfig.FALLBACK_VILLAGE_RADIUS ^ 2
end

-- 判断猪窝当前是否适合接收一个新任务。
function QuestManager:IsEligibleHouse(house)
	if
		house:HasTag("burnt") or
		house.components.burnable ~= nil and house.components.burnable:IsBurning() or
		house.components.spawner == nil or
		house.components.aipc_pig_village_quest == nil or
		house.components.aipc_pig_village_quest:IsActive()
	then
		return false
	end

	return true
end

-- 找出同一猪王村中的全部猪窝。
function QuestManager:FindVillageHouses()
	local houses = {}
	local kingTopologyId = GetTopologyId(self.inst)

	for _, house in ipairs(aipFindEnts("pighouse")) do
		if self:IsVillageHouse(house, kingTopologyId) then
			table.insert(houses, house)
		end
	end

	return houses
end

-- 安排一次补位，同一天只允许真正刷新一次。
function QuestManager:ScheduleFill(delay)
	if self.refreshTask ~= nil then
		return
	end

	self.refreshTask = self.inst:DoTaskInTime(delay or 0, function()
		self.refreshTask = nil
		self:FillTasks()
	end)
end

-- 每天把村庄内仍有效的任务补足到三个。
function QuestManager:FillTasks()
	local currentDay = TheWorld.state.cycles or 0
	if self.lastRefreshDay == currentDay then
		return
	end
	self.lastRefreshDay = currentDay

	local activeCount = 0
	local excludedPrefabs = {}
	local candidates = {}

	for _, house in ipairs(self:FindVillageHouses()) do
		local quest = house.components.aipc_pig_village_quest
		if quest ~= nil and quest:IsActive() then
			activeCount = activeCount + 1
			excludedPrefabs[quest.taskPrefab] = true
		elseif self:IsEligibleHouse(house) then
			table.insert(candidates, house)
		end
	end

	local missingCount = math.max(0, questConfig.MAX_ACTIVE_TASKS - activeCount)
	while missingCount > 0 and #candidates > 0 do
		local house = aipRandomEnt(candidates)
		aipTableRemove(candidates, house)
		local taskData = questConfig.PickTask(excludedPrefabs)

		if taskData ~= nil then
			house.components.aipc_pig_village_quest:StartQuest(taskData.prefab, taskData.count)
			excludedPrefabs[taskData.prefab] = true
			missingCount = missingCount - 1
		end
	end
end

-- 清理世界事件和延迟任务。
function QuestManager:OnRemoveFromEntity()
	self.inst:RemoveEventCallback("ms_cyclecomplete", self._onCycleComplete, TheWorld)
	if self.refreshTask ~= nil then
		self.refreshTask:Cancel()
		self.refreshTask = nil
	end
end

return QuestManager
