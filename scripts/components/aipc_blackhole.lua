-- 黑洞游戏管理器
local Blackhole = Class(function(self, inst)
	self.inst = inst

	self.gamePos = Vector3(1900, 0, 1900)
	self.stone = nil
end)

function Blackhole:StartGame()
	if self.stone ~= nil then
		return
	end

	-- 地址为硬编码
	self.stone = aipSwapPrefab(
		self.inst, "aip_sessho_seki",
		self.gamePos.x, self.gamePos.y, self.gamePos.z
	)
end

return Blackhole