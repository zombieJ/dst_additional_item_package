local _G = GLOBAL

-- 体验关闭
local tooltip_enhance = GLOBAL.aipGetModConfig("tooltip_enhance")
if tooltip_enhance ~= "open" then
	return nil
end

local Text = require "widgets/text"

local function findFocusItem(self)
    if self ~= nil and self.focus then
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
        local children = self.children or {}
        for child, v in pairs(children) do
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

-- 获取要展示的信息
local function getInfo(item)
	-- GLOBAL.aipPrint("->", item.replica and item.replica.aipc_snakeoil)
	-- 是否有 SnakeOilReplica 组件
	if item.replica and item.replica.aipc_snakeoil then
		local aip_info, aip_info_color = item.replica.aipc_snakeoil:GetInfo()
		-- GLOBAL.aipPrint("has it?", aip_info, aip_info_color)
		return aip_info, aip_info_color
	end

	-- 是否有消息组件
	if item.components.aipc_info_client ~= nil then
		local aip_info = item.components.aipc_info_client:Get("aip_info") or ""
        local aip_info_color = item.components.aipc_info_client:Get("aip_info_color")
		return aip_info, aip_info_color
	end
end

-- Hover 展示信息
AddClassPostConstruct("widgets/hoverer", function(self)
    self.aipText = self:AddChild(Text(_G.UIFONT, 24))
    self.aipText:SetPosition(-20, -30, 0)

    local originUpdate = self.OnUpdate

    self.OnUpdate = function(...)
        local ret = originUpdate(self, ...)

        -- 物品栏里的物品
        local item = findFocusItem(
            self.isFE and self.owner or _G.aipGet(self, "owner|HUD|controls")
        )

        local IsActionsVisible = _G.aipGet(self, "owner|IsActionsVisible")

        -- 鼠标 Hover 到的物品
        if item == nil and not self.isFE and IsActionsVisible ~= nil and self.owner:IsActionsVisible() then
            local GetLeftMouseAction = _G.aipGet(self, "owner|components|playercontroller|GetLeftMouseAction")

            -- 变猴子会崩溃，修一下
            if GetLeftMouseAction ~= nil then
                lmb = self.owner.components.playercontroller:GetLeftMouseAction()

                if lmb ~= nil then
                    item = lmb.target
                end
            end
        end

        -- 如果没有提示内容，就略过
        if
            item == nil or
            self.str == nil or self.str == ""
        then
            self.aipText:Hide()
            return ret
        end

        -- local aip_info = item.components.aipc_info_client:Get("aip_info") or ""
        -- local aip_info_color = item.components.aipc_info_client:Get("aip_info_color")

        local aip_info, aip_info_color = getInfo(item)

        if aip_info == "" or not aip_info then
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
