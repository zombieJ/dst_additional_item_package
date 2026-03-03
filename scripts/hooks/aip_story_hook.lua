local _G = GLOBAL
local PlayerHud = _G.require("screens/playerhud")
local AIPStoryScreen = require "screens/aipStoryPopupScreen"

env.AddPopup("AIP_STORY")

_G.POPUPS.AIP_STORY.fn = function(inst, show, target)
    if inst.HUD then
        if not show then
            inst.HUD:CloseAIPStoryScreen()
        elseif not inst.HUD:OpenAIPStoryScreen(target) then
            POPUPS.AIP_STORY:Close(inst)
        end
    end
end

-------------------------------------- UI --------------------------------------
function PlayerHud:OpenAIPStoryScreen()
    self:CloseAIPStoryScreen()
    self.aipStoryScreen = AIPStoryScreen(self.owner)
    self:OpenScreenUnderPause(self.aipStoryScreen)
    return true
end

function PlayerHud:CloseAIPStoryScreen()
    if self.aipStoryScreen ~= nil then
        if self.aipStoryScreen.inst:IsValid() then
            TheFrontEnd:PopScreen(self.aipStoryScreen)
		end
        self.aipStoryScreen = nil
    end
end