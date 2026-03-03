local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"
local Widget = require "widgets/widget"
local Text = require "widgets/text"
local Grid = require "widgets/grid"
local Spinner = require "widgets/spinner"

local TEMPLATES = require "widgets/redux/templates"

local StorybookPage = require "widgets/redux/aipStorybookPage"

local cooking = require("cooking")


require("util")

-------------------------------------------------------------------------------------------------------
local StorybookWidget = Class(Widget, function(self, parent)
    Widget._ctor(self, "StorybookWidget")

    self.root = self:AddChild(Widget("root"))

	local backdrop = self.root:AddChild(Image("images/quagmire_recipebook.xml", "quagmire_recipe_menu_bg.tex"))
    backdrop:ScaleToSize(900, 550)

	local base_size = .7

    -- 添加面板
    self.panel = self.root:AddChild(StorybookPage(parent, "cookpot"))
end)

function StorybookWidget:OnControl(control, down)
    if StorybookWidget._base.OnControl(self, control, down) then return true end
end

function StorybookWidget:GetHelpText()
    local controller_id = TheInput:GetControllerID()
    local t = {}

    table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_OPEN_CRAFTING).."/"..TheInput:GetLocalizedControl(controller_id, CONTROL_OPEN_INVENTORY).. " " .. STRINGS.UI.HELP.CHANGE_TAB)

    return table.concat(t, "  ")
end


return StorybookWidget
