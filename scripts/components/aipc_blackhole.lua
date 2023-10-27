-- world 专用组件。黑洞游戏管理器
local Blackhole = Class(function(self, inst)
	self.inst = inst

	self.gamePos = Vector3(1900, 0, 1900)
	self.stone = nil
end)

function Blackhole:StartGame()
	if self.stone ~= nil and self.stone:IsValid() then
		return
	end

	-- 地址为硬编码
	self.stone = aipSpawnPrefab(
		self.inst, "aip_oldone_black_head",
		self.gamePos.x, self.gamePos.y, self.gamePos.z
	)
end

function Blackhole:GetPos()
	return aipAngleDist(self.gamePos, math.random(360), 5)
end

return Blackhole