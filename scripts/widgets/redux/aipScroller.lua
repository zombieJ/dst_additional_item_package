local Widget = require "widgets/widget"
local Image = require "widgets/image"

local Scroller = Class(Widget, function(self, x, y, width, height)
    Widget._ctor(self, "AIPScroller")

    self.control_up = CONTROL_SCROLLBACK
	self.control_down = CONTROL_SCROLLFWD
    self.scrollUp = false
	self.controlDT = 0 -- disabled state
    self.scrollBound = 0
    self.visualHeight = height
    self.started = false

    -- 背景板
    self.black = self:AddChild(Image("images/global.xml", "square.tex"))
    local bw, bh = self.black:GetSize()
    self.black:SetScale(width / bw, height / bh)
    self.black:SetPosition(width / 2, - height / 2)
    self.black:SetTint(0,0,0,.01)

    -- 容器
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

--------------------------------- 移动 ---------------------------------
function Scroller:Offset(val)
    local x, y, z = self.holder:GetPosition():Get()

    local nextY = y + val
    nextY = math.min(nextY, self.scrollBound - self.visualHeight)
    nextY = math.max(nextY, 0)

    self.holder:SetPosition(x, nextY, z)
end

local SCROLL_SCALE = 0.05
local SCROLL_OFFSET = 200

function Scroller:OnUpdate(dt)
    -- 延迟展示
    if self.started == false then
        self.started = true
        self.holder:Show()
    end

    -- 聚焦方可滚动
    local enabled = self:IsEnabled()
    local focused = self.focus

    local up = TheInput:IsControlPressed(self.control_up)
    local down = TheInput:IsControlPressed(self.control_down)

    -- 有按键 & 悬浮 就叠加
    if (up or down) and (enabled and focused) then
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