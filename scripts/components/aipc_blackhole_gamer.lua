local dev_mode = aipGetModConfig("dev_mode") == "enabled"
local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
        TALK_DANGER = "What is under the ground?",
	},
	chinese = {
        TALK_DANGER = "有什么在地下？",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_BLACK_GAMER_TALK_DANGER = LANG.TALK_DANGER

-- 常量
local START_TIME = 3
local INTERVAL = 0.1
local CHAPTER_TIME = 60

local CHAPTER_COUNT = { 10, 8, 6, 4, 2, 1 }

local GIFTS = {
	-- 1
	{ "aip_oldone_meat" },
	-- 2
	{ "aip_oldone_meat", "aip_oldone_apple" },
	-- 3
	{ "aip_oldone_meat", "aip_oldone_apple", "aip_pet_eyeofterror" },
	-- 4
	{
		"aip_oldone_meat", "aip_oldone_apple",
		"aip_oldone_apple", "aip_pet_eyeofterror",
	},
	-- 5
	{
		"aip_oldone_meat", "aip_oldone_meat",
		"aip_oldone_apple", "aip_oldone_apple", "aip_pet_eyeofterror",
	},
	-- 6
	{
		"aip_oldone_meat", "aip_oldone_meat", "aip_pet_eyeofterror",
		"aip_oldone_apple", "aip_oldone_apple", "aip_black_xuelong",
	},
}

local function randomPosUnit(num)
	return num + math.random() - 0.5
end

-- 杀生石组件：游戏进度管理
local BlackholeGamer = Class(function(self, inst)
	self.inst = inst

	self.players = {}
	self.intervalTask = nil
end)

function BlackholeGamer:NearPlayer(player)
	if aipBufferExist(player, "aip_black_immunity") then
		aipBufferPatch(self.inst, player, "aip_black_portal", 0.001)
		return
	end

	-- Add player
	self.players[player] = -START_TIME / INTERVAL -- 延迟一段时间，让玩家可以从地上爬起来
	self:Start()

	-- Talk
	if player.components.talker ~= nil then
		player.components.talker:Say(
			STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_BLACK_GAMER_TALK_DANGER
		)
	end

	-- Patch Buffer
	aipBufferPatch(self.inst, player, "aip_black_count", 9999999, function(info)
		return info.stack ~= nil and info.stack or 10
	end)
end

function BlackholeGamer:FarPlayer(player)
	-- 离开就传送走
	self:SendAway(player)
end

-- 伤害玩家
function BlackholeGamer:HurtPlayer(player)
	if aipBufferExist(player, "aip_black_count") then
		aipBufferPatch(self.inst, player, "aip_black_count", 9999999, function(info)
			local nextStack = (info.stack or 1) - 1

			if nextStack <= 0 then
				aipBufferRemove(player, "aip_black_count")
				aipBufferPatch(self.inst, player, "aip_black_immunity", 60 * 10)

				self:SendAway(player)
			end

			return nextStack
		end)
	end
end

local function getChapter(times)
	local passTimes = times * INTERVAL
	return math.ceil(passTimes / CHAPTER_TIME)
end

-- 送走玩家
function BlackholeGamer:SendAway(player)
	aipBufferPatch(self.inst, player, "aip_black_portal", 0.001)

	-- 根据玩家留存时间给予奖励
	local chapters = getChapter(self.players[player] or 0)
	local gifts = GIFTS[math.min(chapters, #GIFTS)] or {}

	player:DoTaskInTime(1, function()
		for _, gift in ipairs(gifts) do
			aipFlingItem(
				aipSpawnPrefab(player, gift)
			)
		end
	end)


	-- 重置并决定是否要结束游戏
	self.players[player] = nil

	if aipCountTable(self.players) == 0 then
		self:End()
	end
end

-- 开始游戏
function BlackholeGamer:Start()
	self:Stop()

	self.intervalTask = self.inst:DoPeriodicTask(INTERVAL, function()

		for player, time in pairs(self.players) do
			local times = time + 1
			self.players[player] = times

			-- 计算度过的时间
			local chapters = getChapter(times)

			if chapters > 0 then
				-- 看一下是否要生成触手
				local handCount = CHAPTER_COUNT[math.min(chapters, #CHAPTER_COUNT)] or 1

				if math.mod(times, handCount) == 0 then
					-- aipPrint("Hit!!!")
					local pos = player:GetPosition()
					local hand = aipSpawnPrefab(
						player, "aip_oldone_black_hand",
						randomPosUnit(pos.x), pos.y, randomPosUnit(pos.z)
					)
					hand._aipHead = self.inst
				end
			end
		end
	end, 0)
end

-- 结束游戏
function BlackholeGamer:End()
	self:Stop()

	local pos = self.inst:GetPosition()

	local ents = TheSim:FindEntities(
		pos.x, pos.y, pos.z, 10,
		nil, nil, { "aip_aura_indicator", "aip_oldone_black_group" })

	aipReplacePrefab(self.inst, "aip_shadow_wrapper").DoShow()

	for _, ent in ipairs(ents) do
		ent:Remove()
	end
end

-- 结束任务
function BlackholeGamer:Stop()
	if self.intervalTask ~= nil then
		self.intervalTask:Cancel()
		self.intervalTask = nil
	end
end

return BlackholeGamer