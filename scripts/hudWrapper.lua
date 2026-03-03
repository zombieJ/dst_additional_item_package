local dev_mode = GLOBAL.aipGetModConfig("dev_mode") == "enabled"

if not dev_mode then
	return
end

-----------------------------------------------------------------------
local PlayerHud = GLOBAL.require("screens/playerhud")
local ConfigWidget = GLOBAL.require("widgets/aipAutoConfigWidget")

-- 显示自动化配置窗口
function PlayerHud:ShowAIPAutoConfigWidget(inst, config)
	self.aipAutoConfigScreen = ConfigWidget(self.owner, inst, config)
	self:OpenScreenUnderPause(self.aipAutoConfigScreen)
	return self.aipAutoConfigScreen
end

function PlayerHud:CloseAIPAutoConfigWidget()
	if self.aipAutoConfigScreen then
		self.aipAutoConfigScreen:Close()
		self.aipAutoConfigScreen = nil
	end
end