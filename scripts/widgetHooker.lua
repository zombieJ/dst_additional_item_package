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
