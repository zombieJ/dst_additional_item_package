local Badge = require "widgets/badge"
local UIAnim = require "widgets/uianim"
local Text = require "widgets/text"

local BufferBadge = Class(Badge, function(self, owner, bufferName, endTime)
    Badge._ctor(
        self, nil, owner, { 232 / 255, 123 / 255, 15 / 255, 1 },
        nil, nil, nil, true
    )

    self.bufferName = bufferName
    self.num:SetString(bufferName)
    self.endTime = endTime

    -- 倒计时
    self.countdown = self:AddChild(Text(BODYTEXTFONT, 33, "30s"))
    self.countdown:SetHAlign(ANCHOR_MIDDLE)
    self.countdown:SetPosition(3, 30, 0)

    local now = GetTime()
    local diffSeconds = math.max(math.floor(endTime - now), 0)
    self.countdown:SetString(diffSeconds.. "s")

    -- self:StartUpdating()
end)

-- 代理掉 SetPercent，不做任何事情
function BufferBadge:SetPercent()
end

-- function BufferBadge:OnUpdate(dt)
--     if TheNet:IsServerPaused() then
--         return
--     end

--     -- self:SetPercent(0.5, 100)
-- end

return BufferBadge
