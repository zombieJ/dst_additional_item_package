local dev_mode = aipGetModConfig("dev_mode") == "enabled"

local brain = require("brains/aip_blackhole_monster_brain")

-- 杀生石组件：游戏进度管理
local Blackhole = Class(function(self, inst)
	self.inst = inst

	-- self.round = 0
	-- self.interval = 2
	-- self.roundMonstCount = dev_mode and 10 or 20	-- 每一轮出现的怪物数量
	-- self.spawnDist = dev_mode and 10 or 20

	-- 每一级出现的怪物列表
	-- self.monsterList = {
	-- 	{ "crow", "robin", "robin_winter", "canary" },
	-- }

	self.inst:DoTaskInTime(1, function()
		self:StartGame()
	end)
end)

function Blackhole:StartGame()
	self.round = 0
	self:StartRound()
end

function Blackhole:StartRound()
	if self.task then
		return
	end

	-- self.round = self.round + 1

	-- local monsters = self.monsterList[self.round]

	-- -- 延时生成怪物
	-- local restCount = self.roundMonstCount

	-- self.task = self.inst:DoPeriodicTask(self.interval, function()
	-- 	-- 生成怪物
	-- 	local monsterPrefab = monsters[math.random(#monsters)]
	-- 	self:SpawnMonster(monsterPrefab)

	-- 	-- 停止生成
	-- 	restCount = restCount - 1
	-- 	if restCount <= 0 then
	-- 		self.task:Cancel()
	-- 		self.task = nil
	-- 		return
	-- 	end
	-- end)
end

--[[
-- 无敌了
local function onAttacked(inst, data)
	if data then
		local getAttacked = data.damage > 0

		for type, dmg in pairs(data.spdamage) do
			getAttacked = getAttacked or dmg > 0
			data.spdamage[type] = 0
		end

		data.damage = getAttacked and 1 or 0
	end
end

-- 生成怪物
function Blackhole:SpawnMonster(prefab)
	local tgtPos = aipAngleDist(self.inst:GetPosition(), math.random(360), self.spawnDist)
	local monster = aipSpawnPrefab(self.inst, prefab, tgtPos.x, tgtPos.y, tgtPos.z)

	aipSpawnPrefab(monster, "aip_shadow_wrapper").DoShow()

	monster._aipHome = self.inst
	monster:SetBrain(brain)
	monster.AnimState:SetMultColour(0, 0, 0, 0.8)

	monster:AddTag("hostile")

	-- 不能掉落
	if monster.components.lootdropper ~= nil then
		monster.components.lootdropper.numrandomloot = 0
	end

	-- 减免伤害
	monster:ListenForEvent("aipAttacked", onAttacked)
end

function Blackhole:Reach(target)
	if target then
		aipReplacePrefab(target, "aip_shadow_wrapper").DoShow()

		if target.components.health ~= nil then
			target.components.health:DoDelta(-1, nil, nil, true)
		end
	end
end
]]

return Blackhole