local Badge = require "widgets/badge"
local UIAnim = require "widgets/uianim"
local Text = require "widgets/text"

local MAX_TIME = 99

local BufferBadge = Class(Badge, function(self, owner, bufferName, endTime)
    Badge._ctor(
        self, nil, owner, { 232 / 255, 123 / 255, 15 / 255, 1 },
        nil, nil, nil, true
    )

    self.bufferName = bufferName
    self.endTime = endTime

    self:SetPercent(1, 1)
    self.num:SetString(
        aipBufferFn(bufferName, "name") or bufferName
    )

    -- 倒计时
    self.countdown = self:AddChild(Text(BODYTEXTFONT, 33, "30s"))
    self.countdown:SetHAlign(ANCHOR_MIDDLE)
    self.countdown:SetPosition(3, 30, 0)

    self:StartUpdating()
end)

function BufferBadge:OnUpdate(dt)
    if TheNet:IsServerPaused() then
        return
    end

    local now = GetTime()
    local diffSeconds = math.max(math.floor(self.endTime - now), 0)

    self.countdown:SetString(diffSeconds > MAX_TIME and ">"..MAX_TIME.."s" or diffSeconds.."s")
end

return BufferBadge
