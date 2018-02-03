local Widget = require "widgets/widget"

local AIPInfo = Class(Widget, function(self, slot)
	Widget._ctor(self, "AIPInfo")

	self.slot = slot
end)

return AIPInfo