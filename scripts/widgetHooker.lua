local _G = GLOBAL
local DestinationScreen = require("widgets/aip_dest_screen")

local PlayerHud = _G.require("screens/playerhud")

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

	-- 告诉服务器关掉了
	_G.ThePlayer.player_classified.aip_fly_picker:set("")
end