local Screen = require "widgets/screen"
local Widget = require "widgets/widget"
local Text = require "widgets/text"
local TextEdit = require "widgets/textedit"
local Menu = require "widgets/menu"
local UIAnim = require "widgets/uianim"
local ImageButton = require "widgets/imagebutton"

local function oncancel(doer, widget)
    if not widget.isopen then
        return
	end

    doer.HUD:CloseAIPRubik()
end

local RubikScreen = Class(Screen, function(self, owner)
    Screen._ctor(self, "AIP_RubikScreen")

    self.owner = owner

    self.isopen = false

	----------------------------------- 以下直接抄的木板代码 -----------------------------------
    self._scrnw, self._scrnh = TheSim:GetScreenSize()

    self:SetScaleMode(SCALEMODE_PROPORTIONAL)
    self:SetMaxPropUpscale(MAX_HUD_SCALE)
    self:SetPosition(0, 0, 0)
    self:SetVAnchor(ANCHOR_MIDDLE)
    self:SetHAnchor(ANCHOR_MIDDLE)

    self.scalingroot = self:AddChild(Widget("writeablewidgetscalingroot"))
    self.scalingroot:SetScale(TheFrontEnd:GetHUDScale())
    self.inst:ListenForEvent("continuefrompause", function()
        if self.isopen then
            self.scalingroot:SetScale(TheFrontEnd:GetHUDScale())
        end
    end, TheWorld)
    self.inst:ListenForEvent("refreshhudsize", function(hud, scale)
        if self.isopen then
            self.scalingroot:SetScale(scale)
        end
    end, owner.HUD.inst)

	self.root = self.scalingroot:AddChild(Widget("writeablewidgetroot"))
	local scale = 0.8
    self.root:SetScale(scale, scale, scale)

	-- 不可见的透明背景：mask
    self.black = self.root:AddChild(Image("images/global.xml", "square.tex"))
    self.black:SetVRegPoint(ANCHOR_MIDDLE)
    self.black:SetHRegPoint(ANCHOR_MIDDLE)
    self.black:SetVAnchor(ANCHOR_MIDDLE)
    self.black:SetHAnchor(ANCHOR_MIDDLE)
    self.black:SetScaleMode(SCALEMODE_FILLSCREEN)
    self.black:SetTint(0, 0, 0, 0)
    self.black.OnMouseButton = function() oncancel(self.owner, self) end

	-- 木板 UI
    self.bganim = self.root:AddChild(UIAnim())
    self.bganim:SetHAnchor(ANCHOR_RIGHT)
    self.bganim:SetVAnchor(ANCHOR_BOTTOM)
    self.bganim:SetScale(0.5, 0.5, 0.5)

	self.bganim:GetAnimState():SetBank("ui_board_5x3")
    self.bganim:GetAnimState():SetBuild("ui_board_5x3")

    self.bganim:SetPosition(-300, 150, 0)

    ----------------------------------- 创建魔方 UI 内容物 -----------------------------------


	----------------------------------- 以下直接抄的木板代码 -----------------------------------
    self.root:SetPosition(0, 0, 0)

    self.isopen = true
    self:Show()

    self.bganim:GetAnimState():PlayAnimation("open")
end)

function RubikScreen:Close()
	if self.isopen then
		self.bganim:GetAnimState():PlayAnimation("close")

		self.black:Kill()

		self.isopen = false

		self.inst:DoTaskInTime(.3, function() TheFrontEnd:PopScreen(self) end)
	end
end

return RubikScreen