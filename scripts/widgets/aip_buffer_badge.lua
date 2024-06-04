local Badge = require "widgets/badge"
local UIAnim = require "widgets/uianim"
local Text = require "widgets/text"
local Image = require "widgets/image"

-- 超出 1 小时则不显示
local MAX_TIME = 60 * 60

local BufferBadge = Class(Badge, function(self, owner, bufferName, endTime, stack)
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
    self.num:SetSize(60)

    -- 图标
    local buffPath = "images/aipBuffer/"..bufferName..".xml"
    local imgBuffPath = "images/inventoryimages/"..bufferName..".xml"
    local existBuffPath = softresolvefilepath(buffPath) ~= nil
    local existImgBuffPath = softresolvefilepath(imgBuffPath) ~= nil
    if existBuffPath or existImgBuffPath then
        local finalBuffPath = existBuffPath and buffPath or imgBuffPath
        self.icon = self:AddChild(Image(
            finalBuffPath, bufferName..".tex"
        ))
        self.icon:SetScale(0.65, 0.65)
        self.icon:SetPosition(0, 1, 0)
    end

    -- 倒计时
    self.countdown = self:AddChild(Text(BODYTEXTFONT, 33, ""))
    self.countdown:SetHAlign(ANCHOR_MIDDLE)
    self.countdown:SetPosition(3, 30, 0)

    -- Stack
    self.stack = tonumber(stack or 0)
    if self.stack >= 1 then
        self.stack = self:AddChild(Text(BODYTEXTFONT, 33, tostring(self.stack)))
        self.stack:SetHAlign(ANCHOR_MIDDLE)
        self.stack:SetPosition(3, -25, 0)
    end

    self:StartUpdating()
    self:OnUpdate(0)
end)

function BufferBadge:OnUpdate(dt)
    if TheNet:IsServerPaused() then
        return
    end

    local now = GetTime()
    local diffSeconds = math.max(math.floor(self.endTime - now), 0)

    if diffSeconds == 0 or diffSeconds > MAX_TIME then
        self.countdown:SetString("")
    elseif diffSeconds > 60 then
        local min = math.floor(diffSeconds / 60)
        local sec = diffSeconds % 60
        self.countdown:SetString(min.."m"..sec.."s")
    else
        self.countdown:SetString(diffSeconds.."s")
    end
end

return BufferBadge
