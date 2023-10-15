local Widget = require "widgets/widget"
local Text = require "widgets/text"
local BufferBadge = require "widgets/aip_buffer_badge"

local OFFSET = 70

local BufferList = Class(Widget, function(self, owner)
    Widget._ctor(self, "Inventory")
    self.owner = owner

    self.root = self:AddChild(Widget("root"))

    self:Refresh()
end)

function BufferList:Refresh()
    -- 重置 Buffer UI
	if self._aipBufferList ~= nil then
        self._aipBufferList:Kill()
        self._aipBufferList = nil
    end

	-- 添加额外的 Buffer
	self._aipBufferList = self.root:AddChild(Widget("root"))

    -- 遍历生成 Buffer
    local totalCount = 5
    for i = 1, totalCount do
        local buffer = self:AddChild(BufferBadge(self.owner))
        buffer:SetPosition(- OFFSET * totalCount / 2 + OFFSET * i, 0)
        buffer:SetName("生命恢复")
    end
end

return BufferList