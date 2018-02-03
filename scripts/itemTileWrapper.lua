


--[[local ItemTile = GLOBAL.require("widgets/itemtile")

local originUpdateTooltip = ItemTile.UpdateTooltip


function ItemTile:UpdateTooltip()
	originUpdateTooltip(self)

	self:SetTooltipColour(GLOBAL.unpack(GLOBAL.PLAYERCOLOURS.GREEN))

	local str = self:GetDescriptionString()
	self:SetTooltip(str)
	if self.item:GetIsWet() then
		self:SetTooltipColour(unpack(WET_TEXT_COLOUR))
	else
		self:SetTooltipColour(unpack(NORMAL_TEXT_COLOUR))
	end
end]]