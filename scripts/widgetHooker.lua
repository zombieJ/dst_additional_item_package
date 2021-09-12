local _G = GLOBAL

local PlayerHud = _G.require("screens/playerhud")

------------------------------- 飞行 -------------------------------
local DestinationScreen = require("widgets/aip_dest_screen")

function PlayerHud:OpenAIPDestination(inst, currentTotemId)
	self.aipDestScreen = DestinationScreen(self.owner, currentTotemId)
	self:OpenScreenUnderPause(self.aipDestScreen)
	return self.aipDestScreen
end

function PlayerHud:CloseAIPDestination()
	if self.aipDestScreen then
		self.aipDestScreen:Close()
		self.aipDestScreen = nil
	end
end

------------------------------- 魔方 -------------------------------
local RubikScreen = require("widgets/aip_rubik_screen")

-- 控制面板
function PlayerHud:OpenAIPRubik(inst)
	self.aipRubikScreen = RubikScreen(self.owner)
	self:OpenScreenUnderPause(self.aipRubikScreen)
	return self.aipRubikScreen
end

function PlayerHud:CloseAIPRubik()
	if self.aipRubikScreen then
		self.aipRubikScreen:Close()
		self.aipRubikScreen = nil
	end
end

-- player_classified 在服务端每个玩家都有，而在客机只有当前玩家有
AddPrefabPostInit("player_classified", function(inst)
	inst.aip_rubik = _G.net_string(inst.GUID, "aip_rubik", "aip_rubik_dirty")

	-- 根据事件打开窗口
	inst:ListenForEvent("aip_rubik_dirty", function()
		if _G.ThePlayer ~= nil and inst == _G.ThePlayer.player_classified then
			_G.ThePlayer.HUD:OpenAIPRubik(inst)
		end
	end)
end)
