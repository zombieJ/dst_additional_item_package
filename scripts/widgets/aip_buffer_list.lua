local Widget = require "widgets/widget"
local Text = require "widgets/text"
local BufferBadge = require "widgets/aip_buffer_badge"

local OFFSET = 70

local BufferList = Class(Widget, function(self, owner)
    Widget._ctor(self, "Inventory")
    self.owner = owner

    self.root = self:AddChild(Widget("root"))

    self.buffers = {}
    self.keyStr = nil

    self:StartUpdating()
end)

-- 重新生成 Buffer 列表
function BufferList:Refresh(bufferInfos)
    local keys = aipTableKeys(bufferInfos)
    local keyStr = aipJoin(keys, ",")

    -- 如果没有变化，不刷新
    if self.keyStr == keyStr then
        return
    end

    self.keyStr = keyStr

    -- 移除旧的 Buffer
    for _, buffer in ipairs(self.buffers) do
        buffer:Kill()
    end
    self.buffers = {}

    -- 遍历生成 Buffer
    local totalCount = #keys
    local i = 0

    for bufferName, info in pairs(bufferInfos) do
        local buffer = self.root:AddChild(
            BufferBadge(self.owner, bufferName, info.endTime)
        )
        buffer:SetPosition(- OFFSET * (totalCount - 1) / 2 + OFFSET * i, 0)

        table.insert(self.buffers, buffer)

        i = i + 1
    end
end

function BufferList:OnUpdate(dt)
    if TheNet:IsServerPaused() then
        return
    end

    local bufferInfos = aipBufferInfos(self.owner)
    self:Refresh(bufferInfos)
end

return BufferList