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
    table.sort(keys)
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

    for i, bufferName in ipairs(keys) do
        local info = bufferInfos[bufferName]

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

    -- local now = GetTime() + 10
    -- self:Refresh({
    --     aip_see_eyes = { endTime = now },
    --     aip_pet_play = { endTime = now },
    --     aip_pet_muddy = { endTime = now },
    --     healthCost = { endTime = now },
    --     seeFootPrint = { endTime = now },
    --     oldonePoison = { endTime = now },
    --     aip_pet_johnWick = { endTime = now },
    --     aip_see_petable = { endTime = now },
    --     aip_nectar_drunk = { endTime = now },
    --     aip_oldone_smiling = { endTime = now },
    --     aip_oldone_smiling_axe = { endTime = now },
    --     aip_oldone_smiling_attack = { endTime = now },
    --     aip_oldone_smiling_mine = { endTime = now },
    -- })
end

return BufferList