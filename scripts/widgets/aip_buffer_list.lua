local Widget = require "widgets/widget"
local Text = require "widgets/text"
local BufferBadge = require "widgets/aip_buffer_badge"

local OFFSET = 70

local BufferList = Class(Widget, function(self, owner)
    Widget._ctor(self, "Inventory")
    self.owner = owner

    self.root = self:AddChild(Widget("root"))

    self:StartUpdating()
end)

function BufferList:Refresh(bufferInfos)
    -- 重置 Buffer UI
	if self._aipBufferList ~= nil then
        self._aipBufferList:Kill()
        self._aipBufferList = nil
    end

	-- 添加额外的 Buffer
	self._aipBufferList = self.root:AddChild(Widget("root"))

    -- 遍历生成 Buffer
    local totalCount = #aipTableKeys(bufferInfos)
    local i = 0

    for bufferName, info in pairs(bufferInfos) do
        local buffer = self._aipBufferList:AddChild(
            BufferBadge(self.owner, bufferName, info.endTime)
        )
        buffer:SetPosition(- OFFSET * (totalCount - 1) / 2 + OFFSET * i, 0)

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