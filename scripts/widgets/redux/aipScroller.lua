local Widget = require "widgets/widget"

local Scroller = Class(Widget, function(self, x, y, width, height)
    Widget._ctor(self, "AIPScroller")

    self.control_up = CONTROL_SCROLLBACK
	self.control_down = CONTROL_SCROLLFWD
    self.scrollUp = false
	self.controlDT = 0 -- disabled state
    self.scrollBound = 0
    self.visualHeight = height
    self.started = false

    self.holder = self:AddChild(Widget("contentRoot"))
    self.holder:Hide()

    self:SetScissor(x, y, width, height)

	return self
end)

function Scroller:PathChild(node)
    return self.holder:AddChild(node)
end

function Scroller:SetScrollBound(scrollBound) -- 滚动边界得是一个正数
    self.scrollBound = scrollBound

    self:StartUpdating()
end

function Scroller:Offset(val)
    local x, y, z = self.holder:GetPosition():Get()

    local nextY = y + val
    nextY = math.min(nextY, self.scrollBound - self.visualHeight)
    nextY = math.max(nextY, 0)

    self.holder:SetPosition(x, nextY, z)
end

local SCROLL_SCALE = 0.05
local SCROLL_OFFSET = 100

function Scroller:OnUpdate(dt)
    -- 延迟展示
    if self.started == false then
        self.started = true
        self.holder:Show()
    end

    local up = TheInput:IsControlPressed(self.control_up)
    local down = TheInput:IsControlPressed(self.control_down)

    -- 有按键就叠加
    if up or down then
        self.controlDT = self.controlDT + dt
        self.scrollUp = up
    end

    -- 开始滚动
    if self.controlDT >= 0 then
        local multi = self.controlDT / SCROLL_SCALE
        self.controlDT = 0

        self:Offset(multi * (self.scrollUp and -SCROLL_OFFSET or SCROLL_OFFSET))
    end
end

return Scroller