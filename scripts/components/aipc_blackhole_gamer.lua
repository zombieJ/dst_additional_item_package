local dev_mode = aipGetModConfig("dev_mode") == "enabled"

local INTERVAL = 0.2
local CHAPTER_TIME = 60

local CHAPTER_COUNT = { 5, 4, 3, 2 }

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
	-- Add player
	self.players[player] = 0
	self:Start()
end

function BlackholeGamer:FarPlayer(player)
	-- Revome player
	self.players[player] = nil

	if aipCountTable(self.players) == 0 then
		self:Stop()
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
			local passTimes = times * INTERVAL
			local chapters = math.ceil(passTimes / CHAPTER_TIME)

			-- 看一下是否要生成触手
			local handCount = CHAPTER_COUNT[chapters] or 1

			aipPrint(">>>", times, chapters, passTimes, handCount, math.mod(times, handCount))
			if math.mod(times, handCount) == 0 then
				aipPrint("Hit!!!")
				local pos = player:GetPosition()
				aipSpawnPrefab(
					player, "aip_oldone_black_hand",
					randomPosUnit(pos.x), pos.y, randomPosUnit(pos.z)
				)
			end


			-- local totalTime = time + INTERVAL
			-- self.players[player] = totalTime

			-- -- 看一下是否要生成触手
			-- local chapters = math.ceil(totalTime / CHAPTER_TIME)
			-- local handCount = CHAPTER_COUNT[chapters] or 1

			-- -- aipPrint(">>>", chapters, totalTime, handCount, handCount * INTERVAL, math.mod(totalTime, handCount * INTERVAL))
			-- -- local intervalTotalTime = totalTime * INTERVAL

			-- if math.mod(totalTime, handCount * INTERVAL) < INTERVAL then
			-- 	aipPrint("Hit!!!")
			-- 	local pos = player:GetPosition()
			-- 	aipSpawnPrefab(
			-- 		player, "aip_oldone_black_hand",
			-- 		randomPosUnit(pos.x), pos.y, randomPosUnit(pos.z)
			-- 	)
			-- end
		end
	end, 0)
end

-- 结束游戏
function BlackholeGamer:Stop()
	if self.intervalTask ~= nil then
		self.intervalTask:Cancel()
		self.intervalTask = nil
	end
end

return BlackholeGamer