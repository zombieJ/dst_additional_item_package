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

    doer.HUD:CloseAIPPetInfo()
end

local PetInfoScreen = Class(Screen, function(self, owner, petSkillInfo)
    Screen._ctor(self, "AIP_PetInfoScreen")

    self.owner = owner

    self.petSkillInfo = petSkillInfo

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
    self.black.OnMouseButton = function(inst, button, down, x, y)
        if down == true then
            oncancel(self.owner, self)
        end
    end

	-- 木板 UI
    self.bganim = self.root:AddChild(UIAnim())
    self.bganim:SetScale(1, 1, 1)
    self.bgimage = self.root:AddChild(Image())
	self.bganim:SetScale(1, 1, 1)

	self.bganim:GetAnimState():SetBank("ui_board_5x3")
    self.bganim:GetAnimState():SetBuild("ui_board_5x3")

    -------------------------------------- 展示目的地列表 --------------------------------------
    self.buttons = {}
    table.insert(self.buttons, { text = "Left", cb = function()
        -- oncancel(self.writeable, self.owner, self)
    end, control = CONTROL_FOCUS_LEFT })

    table.insert(self.buttons, { text = "Right", cb = function()
        -- onaccept(self.writeable, self.owner, self)
    end, control = CONTROL_FOCUS_RIGHT })

    local spacing = 150
    self.menu = self.root:AddChild(Menu(self.buttons, spacing, true, "none"))
    self.menu:SetTextSize(40)
    local w = self.menu:AutoSpaceByText(15)
    local menuoffset = Vector3(6, -70, 0)
    self.menu:SetPosition(menuoffset.x - .5 * w, menuoffset.y, menuoffset.z)
    
    -- self:RenderInfo()

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

function PetInfoScreen:RenderInfo()
    -- if self.petMenu ~= nil then
    --     self.petMenu:Kill()
    -- end

    -- local petList = {}
    -- table.insert(petList, {
    --     text = '~~~',
    --     cb = function()
    --         aipPrint("Click TODO")
    --     end,
    -- })

    -- self.petMenu = self.root:AddChild(Menu(petList, -55, false, "carny_long"))
    -- self.petMenu:SetTextSize(35)
	-- self.petMenu:SetPosition(-350, 130, 0)
end

function PetInfoScreen:Close()
	if self.isopen then
		if self.bgimage.texture then
			self.bgimage:Hide()
		else
			self.bganim:GetAnimState():PlayAnimation("close")
		end

		self.black:Kill()

		self.isopen = false

		self.inst:DoTaskInTime(.3, function() TheFrontEnd:PopScreen(self) end)
	end
end

return PetInfoScreen