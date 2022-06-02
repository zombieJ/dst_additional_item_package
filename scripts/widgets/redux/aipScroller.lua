local Widget = require "widgets/widget"

local Scroller = Class(Widget, function(self, x, y, width, height)
    Widget._ctor(self, "AIPScroller")

    self.control_up = CONTROL_SCROLLBACK
	self.control_down = CONTROL_SCROLLFWD
    self.scrollUp = false
	self.controlDT = 0 -- disabled state

    self.holder = self:AddChild(Widget("contentRoot"))

    self:SetScissor(x, y, width, height)

    self:StartUpdating()

	return self
end)

function Scroller:PathChild(node)
    return self:AddChild(node)
end

function Scroller:Offset(val)
    local x, y, z = self:GetPosition():Get()
    self:SetPosition(x, y + val, z)
end

local SCROLL_DELAY = 0.05
local SCROLL_OFFSET = 20

function Scroller:OnUpdate(dt)
    local up = TheInput:IsControlPressed(self.control_up)
    local down = TheInput:IsControlPressed(self.control_down)

    -- 有按键就叠加
    if up or down then
        self.controlDT = self.controlDT + dt
        self.scrollUp = up
    end

    -- 开始滚动
    if self.controlDT >= SCROLL_DELAY then
        local multi = math.floor(self.controlDT / SCROLL_DELAY)
        self.controlDT = self.controlDT - multi * SCROLL_DELAY

        self:Offset(multi * (self.scrollUp and -SCROLL_OFFSET or SCROLL_OFFSET))
    end
end

return Scroller