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

    -- if widget.config.cancelbtn.cb ~= nil then
    --     widget.config.cancelbtn.cb(inst, doer, widget)
    -- end

    doer.HUD:CloseAIPDestination()
end

local DestinationScreen = Class(Screen, function(self, owner)
    Screen._ctor(self, "AIP_DestinationScreen")

    self.owner = owner

    -- aipTypePrint("Screen:", TheWorld.components.aip_world_common_store_client:GetTotems())
    self.totemNames = TheWorld.components.aip_world_common_store_client:GetTotems()

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
    self.bganim:SetScale(1, 1, 1)
    self.bgimage = self.root:AddChild(Image())
	self.bganim:SetScale(1, 1, 1)

	self.bganim:GetAnimState():SetBank("ui_board_5x3")
    self.bganim:GetAnimState():SetBuild("ui_board_5x3")

	-- 按钮
    self.buttons = {}
    table.insert(self.buttons, { text = STRINGS.SIGNS.MENU.CANCEL, cb = function() oncancel(self.owner, self) end, control = CONTROL_CANCEL })

	-- 看起来像是根据输入控制用不同的东东，但是不知道区别是什么。反正是菜单按钮的，不用管。
    local menuoffset = Vector3(6, -160, 0)
    if TheInput:ControllerAttached() then
        local spacing = 150
        self.menu = self.root:AddChild(Menu(self.buttons, spacing, true, "none"))
        self.menu:SetTextSize(40)
        local w = self.menu:AutoSpaceByText(15)
        self.menu:SetPosition(menuoffset.x - .5 * w, menuoffset.y, menuoffset.z)
    else
        local spacing = 110
        self.menu = self.root:AddChild(Menu(self.buttons, spacing, true, "small"))
        self.menu:SetTextSize(35)
        self.menu:SetPosition(menuoffset.x - .5 * spacing * (#self.buttons - 1), menuoffset.y, menuoffset.z)
    end

    -------------------------------------- 展示目的地列表 --------------------------------------
    self.page = 0
    self:RenderDestinations()

	----------------------------------- 以下直接抄的木板代码 -----------------------------------
	self.root:SetPosition(0, 150, 0)

    self.isopen = true
    self:Show()

    if self.bgimage.texture then
        self.bgimage:Show()
    else
        self.bganim:GetAnimState():PlayAnimation("open")
    end
end)

function DestinationScreen:RenderDestinations()
    local startIndex = (self.page) * 10
    local names = aipTableSlice(self.totemNames, startIndex + 1, 10)
    self.destLeft = {}
    self.destRight = {}

    -- 如果有了就清理一下
    if self.destLeftMenu ~= nil then
        self.destLeftMenu:Kill()
		self.destRightMenu:Kill()
    end

    -- 左侧列表
    for i = 1, 5 do
        table.insert(self.destLeft, {
            text = self.totemNames[startIndex + i] or "-",
            totemIndex = startIndex + i,
            cb = function() oncancel(self.owner, self) end,
        })
    end

	self.destLeftMenu = self.root:AddChild(Menu(self.destLeft, -55, false, "carny_long"))
	self.destLeftMenu:SetTextSize(35)
	self.destLeftMenu:SetPosition(-118, 130, 0)

    -- 右侧列表
	for i = 6, 10 do
        table.insert(self.destRight, {
            text = self.totemNames[startIndex + i] or "-",
            totemIndex = startIndex + i,
            cb = function() oncancel(self.owner, self) end,
        })
    end

	self.destRightMenu = self.root:AddChild(Menu(self.destRight, -55, false, "carny_long"))
	self.destRightMenu:SetTextSize(35)
	self.destRightMenu:SetPosition(118, 130, 0)
end

function DestinationScreen:Close()
	if self.isopen then
		if self.bgimage.texture then
			self.bgimage:Hide()
		else
			self.bganim:GetAnimState():PlayAnimation("close")
		end

		self.black:Kill()
		self.menu:Kill()
		self.destLeftMenu:Kill()
		self.destRightMenu:Kill()

		self.isopen = false

		self.inst:DoTaskInTime(.3, function() TheFrontEnd:PopScreen(self) end)
	end
end

return DestinationScreen