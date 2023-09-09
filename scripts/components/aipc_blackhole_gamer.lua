local dev_mode = aipGetModConfig("dev_mode") == "enabled"

local brain = require("brains/aip_blackhole_monster_brain")

-- 杀生石组件：游戏进度管理
local Blackhole = Class(function(self, inst)
	self.inst = inst

	self.round = 0
	self.spawnDist = dev_mode and 10 or 20

	-- 每一级出现的怪物列表
	self.monsterList = {
		{ "crow" },
	}

	self.inst:DoTaskInTime(1, function()
		self:StartGame()
	end)
end)

function Blackhole:StartGame()
	self.round = 0
	self:StartRound()
end

function Blackhole:StartRound()
	self.round = self.round + 1

	local monsters = self.monsterList[self.round]
	local monsterPrefab = monsters[math.random(#monsters)]

	local tgtPos = aipAngleDist(self.inst:GetPosition(), math.random(360), self.spawnDist)
	local monster = aipSpawnPrefab(self.inst, monsterPrefab, tgtPos.x, tgtPos.y, tgtPos.z)

	monster._aipHome = self.inst
	monster:SetBrain(brain)
	monster.AnimState:SetMultColour(0, 0, 0, 0.8)

	if monster.components.lootdropper ~= nil then
		monster.components.lootdropper.numrandomloot = 0
	end
end

function Blackhole:Reach(target)
	if target then
		aipReplacePrefab(target, "aip_shadow_wrapper").DoShow()
	end
end

return Blackhole