local Badge = require "widgets/badge"
local UIAnim = require "widgets/uianim"
local Text = require "widgets/text"

local BufferBadge = Class(Badge, function(self, owner)
    Badge._ctor(
        self, nil, owner, { 1, 1, 1, 0 },
        nil, nil, nil, true
    )

    -- 倒计时
    self.countdown = self:AddChild(Text(BODYTEXTFONT, 33, "30s"))
    self.countdown:SetHAlign(ANCHOR_MIDDLE)
    self.countdown:SetPosition(3, 30, 0)

    -- self:StartUpdating()
end)

-- 代理掉 SetPercent，不做任何事情
function BufferBadge:SetPercent()
end

-- 设置文案
function BufferBadge:SetName(name)
    self.num:SetString(name)
end

-- function BufferBadge:OnUpdate(dt)
--     if TheNet:IsServerPaused() then
--         return
--     end

--     -- self:SetPercent(0.5, 100)
-- end

return BufferBadge
