-- 直接复制的小木牌：scripts\widgets\writeablewidget.lua

local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		PREV = "Previous",
        TOGGLE = "Show/Hide",
        SHOW = "Show",
        HIDE = "Hide",
		NEXT = "Next",
	},
	chinese = {
		PREV = "上一个",
        TOGGLE = "显/隐",
        SHOW = "显示",
        HIDE = "隐藏",
		NEXT = "下一个",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

local petConfig = require("configurations/aip_pet")

-------------------------------------------------------------------------
local Screen = require "widgets/screen"
local Widget = require "widgets/widget"
local Text = require "widgets/text"
local TextEdit = require "widgets/textedit"
local Menu = require "widgets/menu"
local UIAnim = require "widgets/uianim"
local ImageButton = require "widgets/imagebutton"

local function onmiddle(inst, doer, widget)
    if not widget.isopen then
        return
    end

    widget.config.toggleBtn.cb(inst, doer, widget)
end

local function oncancel(widget, doer)
    if not widget.isopen then
        return
    end

    doer.HUD:CloseAIPPetInfo()
end

local PetInfoWidget = Class(Screen, function(self, owner, petInfo)
    Screen._ctor(self, "SignWriter")

    self.petInfo = petInfo

    self.owner = owner
    local config = {
        prompt = STRINGS.SIGNS.MENU.PROMPT,
        animbank = "ui_board_5x3",
        animbuild = "ui_board_5x3",
        menuoffset = Vector3(6, -70, 0),
    
        prevBtn = { text = LANG.PREV, cb = nil, control = CONTROL_CANCEL },
        toggleBtn = { text = LANG.TOGGLE, cb = function(inst, doer, widget)
                -- widget:OverrideText( SignGenerator(inst, doer) )
            end, control = CONTROL_MENU_MISC_2 },
        nextBtn = { text = LANG.NEXT, cb = nil, control = CONTROL_ACCEPT },
    
        --defaulttext = SignGenerator,
    }
    self.config = config

    self.isopen = false

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
    self.root:SetScale(.6, .6, .6)

    -- secretly this thing is a modal Screen, it just LOOKS like a widget
    self.black = self.root:AddChild(Image("images/global.xml", "square.tex"))
    self.black:SetVRegPoint(ANCHOR_MIDDLE)
    self.black:SetHRegPoint(ANCHOR_MIDDLE)
    self.black:SetVAnchor(ANCHOR_MIDDLE)
    self.black:SetHAnchor(ANCHOR_MIDDLE)
    self.black:SetScaleMode(SCALEMODE_FILLSCREEN)
    self.black:SetTint(0, 0, 0, 0)
    self.black.OnMouseButton = function(inst, button, down, x, y)
        if down then
            oncancel(self, self.owner)
        end
    end

    self.bganim = self.root:AddChild(UIAnim())
    self.bganim:SetScale(1, 1, 1)
    self.bgimage = self.root:AddChild(Image())
    self.bganim:SetScale(1, 1, 1)

    ------------------------------ 刷新按钮 ------------------------------
    self:RefreshStatus()
    self:RefreshControls()

    if config.bgatlas ~= nil and config.bgimage ~= nil then
        self.bgimage:SetTexture(config.bgatlas, config.bgimage)
    end

    if config.animbank ~= nil then
        self.bganim:GetAnimState():SetBank(config.animbank)
    end

    if config.animbuild ~= nil then
        self.bganim:GetAnimState():SetBuild(config.animbuild)
    end

    if config.pos ~= nil then
        self.root:SetPosition(config.pos)
    else
        self.root:SetPosition(0, 150, 0)
    end

    self.isopen = true
    self:Show()

    if self.bgimage.texture then
        self.bgimage:Show()
    else
        self.bganim:GetAnimState():PlayAnimation("open")
    end

    SetAutopaused(true)
end)

------------------------------ 更新描述 ------------------------------
function PetInfoWidget:RefreshStatus()
    -- self.petInfo
    if self.infoPanel ~= nil then
        self.infoPanel:Kill()
    end

    self.infoPanel = self.root:AddChild(Widget("petInfoRoot"))
    self.infoPanel:SetPosition(0, 130)

    -- 名字
    local color = petConfig.QUALITY_COLORS[self.petInfo.quality]
    local upperCase = string.upper(self.petInfo.prefab)
    local name_str = STRINGS.NAMES[upperCase].."("..petConfig.QUALITY_LANG[self.petInfo.quality]..")"
    local text = self.infoPanel:AddChild(Text(UIFONT, 50, name_str))
    text:SetHAlign(ANCHOR_LEFT)
    text:SetColour(color[1] / 255, color[2] / 255, color[3] / 255, 1)

    -- 技能列表
    local offsetTop = -80
    local DESC_CONTENT_WIDTH = 450
    for skillName, skillData in pairs(self.petInfo.skills) do
        local skill_str = petConfig.SKILL_LANG[skillName].."("..petConfig.QUALITY_LANG[skillData.quality].."):"
        skill_str = skill_str..petConfig.SKILL_DESC_LANG[skillName]
        local skillText = self.infoPanel:AddChild(Text(UIFONT, 35))
        
        skillText:SetMultilineTruncatedString(skill_str, 14, DESC_CONTENT_WIDTH, 200) -- 163
        skillText:SetHAlign(ANCHOR_LEFT)
        skillText:SetVAlign(ANCHOR_TOP)
        skillText:SetPosition(0, offsetTop)

        local TW, TH = text:GetRegionSize()

        offsetTop = offsetTop - TH - 10
    end
end

------------------------------ 更新按钮 ------------------------------
function PetInfoWidget:RefreshControls()
    if self.menu ~= nil then
        self.menu:Kill()
    end

    self.buttons = {}
    table.insert(self.buttons, {
        text = self.config.prevBtn.text,
        cb = function()
        end,
        control = self.config.prevBtn.control,
    })

    if self.config.toggleBtn ~= nil then
        table.insert(self.buttons, {
            text = self.config.toggleBtn.text,
            cb = function()
            end,
            control = self.config.toggleBtn.control,
        })
    end

    table.insert(self.buttons, {
        text = self.config.nextBtn.text,
        cb = function()
        end,
        control = self.config.nextBtn.control,
    })

    local menuoffset = self.config.menuoffset or Vector3(0, 0, 0)
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
end

function PetInfoWidget:OnBecomeActive()
    self._base.OnBecomeActive(self)
end

function PetInfoWidget:Close()
    if self.isopen then
        if self.bgimage.texture then
            self.bgimage:Hide()
        else
            self.bganim:GetAnimState():PlayAnimation("close")
        end

        self.black:Kill()
        self.menu:Kill()
        self.infoPanel:Kill()

        self.isopen = false

        self.inst:DoTaskInTime(.3, function() TheFrontEnd:PopScreen(self) end)
    end
end

function PetInfoWidget:OnControl(control, down)
    if PetInfoWidget._base.OnControl(self,control, down) then return true end

    if not down then
        for i, v in ipairs(self.buttons) do
            if control == v.control and v.cb ~= nil then
                v.cb()
                return true
            end
        end
        if control == CONTROL_OPEN_DEBUG_CONSOLE then
            return true
        end
    end
end

function PetInfoWidget:OnDestroy()
    SetAutopaused(false)

	PetInfoWidget._base.OnDestroy(self)
end

return PetInfoWidget
