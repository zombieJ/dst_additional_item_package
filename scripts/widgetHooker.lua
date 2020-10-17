local _G = GLOBAL
local DestinationScreen = require("widgets/aip_dest_screen")

local PlayerHud = _G.require("screens/playerhud")

function PlayerHud:OpenAIPDestination(inst, currentIndex)
	self.aipDestScreen = DestinationScreen(self.owner, currentIndex)
	self:OpenScreenUnderPause(self.aipDestScreen)
	return self.aipDestScreen
end

function PlayerHud:CloseAIPDestination()
	if self.aipDestScreen then
		self.aipDestScreen:Close()
		self.aipDestScreen = nil
	end
end