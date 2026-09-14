local language = aipGetModConfig("language")
local dev_mode = aipGetModConfig("dev_mode") == "enabled"

local LANG_MAP = {
	english = {
		INDICATOR_NAME = "Pig Village Quest",
		PIG_DESC = "I need %d %s! %d more!",
		HOUSE_DESC = "The pig living here is collecting %s: %d / %d.",
		RECEIVED = "%s received! %d more!",
		COMPLETE = "Enough! This is for you!",
		WRONG_ITEM = "Not this! I need %s!",
		TICKET_MERGED = "Three ticket fragments became a train ticket!",
	},
	chinese = {
		INDICATOR_NAME = "猪村委托",
		PIG_DESC = "俺要 %d 个%s！还差 %d 个！",
		HOUSE_DESC = "这里的猪人正在收集%s：%d / %d。",
		RECEIVED = "%s收到啦！还差 %d 个！",
		COMPLETE = "够啦够啦！这个给你！",
		WRONG_ITEM = "不是这个！俺要的是%s！",
		TICKET_MERGED = "三张碎片合成了一张列车体验券！",
	},
}

local config = {
	IS_DEV_MODE = dev_mode,
	MAX_ACTIVE_TASKS = 3,
	FALLBACK_VILLAGE_RADIUS = 60,
	INITIAL_FILL_DELAY_MIN = dev_mode and 1 or 5,
	INITIAL_FILL_DELAY_MAX = dev_mode and 1 or 15,
	DAILY_FILL_DELAY_MIN = dev_mode and 1 or 5,
	DAILY_FILL_DELAY_MAX = dev_mode and 1 or 30,
	RUNTIME_SYNC_INTERVAL = dev_mode and 0.25 or 1,
	TASK_COUNTS = dev_mode and { 2 } or { 2, 4, 6, 8 },
	TICKET_FRAGMENT_COUNT = 3,
	TASKS = {
		-- 草
		cutgrass = 3,
		-- 树枝
		twigs = 3,
		-- 木头
		log = 2,
		-- 石头
		rocks = 2,
		-- 燧石
		flint = 2,
		-- 蜂刺
		stinger = 1,
		-- 种子
		seeds = 3,
		-- 花瓣
		petals = 3,
	},
	REWARDS = {
		goldnugget = 50,
		redgem = 15,
		bluegem = 15,
		purplegem = 8,
		orangegem = 5,
		yellowgem = 5,
		greengem = 2,
	},
}

config.LANG = LANG_MAP[language] or LANG_MAP.english

-- 随机生成一个基础物资任务。
function config.PickTask(excluded)
	local taskWeights = aipCloneTable(config.TASKS)
	for prefab in pairs(excluded or {}) do
		taskWeights[prefab] = nil
	end

	local prefab = aipRandomLoot(taskWeights) or aipRandomLoot(config.TASKS)
	local count = aipRandomEnt(config.TASK_COUNTS)
	if prefab == nil or count == nil then
		return nil
	end

	return {
		prefab = prefab,
		count = count,
	}
end

-- 随机生成任务奖励，金子数量由任务需求决定。
function config.PickReward(requiredCount)
	local prefab = aipRandomLoot(config.REWARDS)
	if prefab == nil then
		return nil
	end

	return {
		prefab = prefab,
		count = prefab == "goldnugget" and
			math.max(1, math.floor(requiredCount / 2)) or 1,
	}
end

return config
