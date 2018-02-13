local dev_mode = GLOBAL.aipGetModConfig("dev_mode") == "enabled"

if not dev_mode then
	return
end

-----------------------------------------------------------------------
local PlayerHud = GLOBAL.require("screens/playerhud")

function PlayerHud:ShowAIPAutoConfigWidget(inst, config)
	if writeable == nil then
		return
	else
		self.writeablescreen = WriteableWidget(self.owner, inst, config)
		self:OpenScreenUnderPause(self.writeablescreen)
		if TheFrontEnd:GetActiveScreen() == self.writeablescreen then
			-- Have to set editing AFTER pushscreen finishes.
			self.writeablescreen.edit_text:SetEditing(true)
		end
		return self.writeablescreen
	end
end

function PlayerHud:CloseAIPAutoConfigWidget()
	if self.writeablescreen then
		self.writeablescreen:Close()
		self.writeablescreen = nil
	end
end