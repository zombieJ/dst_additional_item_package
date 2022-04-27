local _G = GLOBAL

-- 体验关闭
local tooltip_enhance = GLOBAL.aipGetModConfig("tooltip_enhance")
if tooltip_enhance ~= "open" then
	return nil
end

local Text = require "widgets/text"

local function findFocusItem(self)
    if self.focus then
        -- 找到物品啦
        if
            self.item ~= nil and
            type(self.item) == "table" and
            self.item.IsValid ~= nil and -- T 键会给不是 inst 的东东
            self.item:IsValid() and
            self.item.replica ~= nil and
            type(self.item.replica) == "table" and
            self.item.replica.inventoryitem ~= nil
        then
            return self.item
        end

        -- 查找子元素有没有绑定物品
        for child, v in pairs(self.children) do
            local item = findFocusItem(child)
            if item ~= nil then
                return item
            end
        end
    end
end

------------------------------------------------------------------
--[[
    self.text:              怪物千层饼          y: 40
                            X: 吃

    self.secondarytext      X: 释放             y:-30
]]

-- Hover 展示信息
AddClassPostConstruct("widgets/hoverer", function(self)
    self.aipText = self:AddChild(Text(_G.UIFONT, 24))
    self.aipText:SetPosition(-20, -30, 0)

    local originUpdate = self.OnUpdate

    self.OnUpdate = function(...)
        local ret = originUpdate(self, ...)

        -- 物品栏里的物品
        local item = findFocusItem(
            self.isFE and self.owner or self.owner.HUD.controls
        )

        -- 鼠标 Hover 到的物品
        if item == nil and not self.isFE and self.owner:IsActionsVisible() then
            lmb = self.owner.components.playercontroller:GetLeftMouseAction()

            if lmb ~= nil then
                item = lmb.target
            end
        end

        -- 如果没有提示内容，就略过
        if
            item == nil or item.components.aipc_info_client == nil or
            self.str == nil or self.str == ""
        then
            self.aipText:Hide()
            return ret
        end

        local aip_info = item.components.aipc_info_client:Get("aip_info") or ""
        local aip_info_color = item.components.aipc_info_client:Get("aip_info_color")

        if aip_info == "" then
            self.aipText:Hide()
            return ret
        end

        if aip_info_color then
            aip_info_color = { aip_info_color[1] / 255, aip_info_color[2] / 255, aip_info_color[3] / 255, (aip_info_color[4] or 255) / 255 }
        else
            aip_info_color = _G.NORMAL_TEXT_COLOUR
        end

        -- 设置文本
        self.aipText:SetString(aip_info)
        self.aipText:SetColour(_G.unpack(aip_info_color))
        self.aipText:Show()

        -- 获取数据
        local textPos = self.text:GetPosition()
        local textWidth, textHeight = self.text:GetRegionSize()
        local infoWidth, infoHeight = self.aipText:GetRegionSize()

        self.aipText:SetPosition(0, textPos.y + textHeight / 2 + infoHeight / 2, 0)

        return ret
    end
end)
