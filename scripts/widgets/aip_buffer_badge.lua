local Badge = require "widgets/badge"
local UIAnim = require "widgets/uianim"
local Text = require "widgets/text"
local Image = require "widgets/image"

local MAX_TIME = 99

local BufferBadge = Class(Badge, function(self, owner, bufferName, endTime)
    Badge._ctor(
        self, nil, owner, { 232 / 255, 123 / 255, 15 / 255, 1 },
        nil, nil, nil, true
    )

    self.bufferName = bufferName
    self.endTime = endTime

    self:SetPercent(1, 1)
    self.num:SetPosition(3, 60, 0)
    self.num:SetString(
        aipBufferFn(bufferName, "name") or bufferName
    )

    -- 图标
    if softresolvefilepath("images/aipBuffer/"..bufferName..".xml") ~= nil then
        self.icon = self:AddChild(Image(
            "images/aipBuffer/"..bufferName..".xml", bufferName..".tex"
        ))
        self.icon:SetScale(0.65, 0.65)
        self.icon:SetPosition(0, 1, 0)
    end

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

    if diffSeconds == 0 then
        self.countdown:SetString("")
    elseif diffSeconds > MAX_TIME then
        self.countdown:SetString(">"..MAX_TIME.."s")
    else
        self.countdown:SetString(diffSeconds.."s")
    end
end

return BufferBadge
