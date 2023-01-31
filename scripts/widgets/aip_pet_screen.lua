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

local config = {
    prompt = STRINGS.SIGNS.MENU.PROMPT,
    animbank = "ui_board_5x3",
    animbuild = "ui_board_5x3",
    menuoffset = Vector3(6, -165, 0),

    prevBtn = { text = LANG.PREV, cb = function()
        end, control = CONTROL_CANCEL },
    toggleBtn = { text = LANG.TOGGLE, cb = function(inst, doer, widget)
        end, control = CONTROL_MENU_MISC_2 },
    nextBtn = { text = LANG.NEXT, cb = function()
        end, control = CONTROL_ACCEPT },

}

local PetInfoWidget = Class(Screen, function(self, owner, data)
    Screen._ctor(self, "SignWriter")

    self.current = data.current or 1
    self.petInfos = data.petInfos or {}
    self.petOwner = data.owner or false

    
    self.owner = owner
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
    self.bganim:SetScale(1.5, 1.5, 1)
    self.bgimage = self.root:AddChild(Image())
    self.bganim:SetScale(1.5, 1.5, 1)

    ------------------------------ 刷新按钮 ------------------------------
    self.isopen = true

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

    self:Show()

    if self.bgimage.texture then
        self.bgimage:Show()
    else
        self.bganim:GetAnimState():PlayAnimation("open")
    end

    -- SetAutopaused(true)

    self.inst:DoTaskInTime(1, function(inst)
        self.canClick = true
    end)
end)

------------------------------ 更新描述 ------------------------------
function PetInfoWidget:RefreshStatus()
    if self.infoPanel ~= nil then
        self.infoPanel:Kill()
        self.infoPanel = nil
    end

    if not self.isopen then
        return
    end

    local SKILL_MAX_LEVEL = petConfig.SKILL_MAX_LEVEL
    local QUALITY_COLORS = petConfig.QUALITY_COLORS
    local QUALITY_LANG = petConfig.QUALITY_LANG
    local SKILL_LANG = petConfig.SKILL_LANG
    local SKILL_DESC_LANG = petConfig.SKILL_DESC_LANG
    local SKILL_DESC_VARS = petConfig.SKILL_DESC_VARS
    local SKILL_CONSTANT = petConfig.SKILL_CONSTANT

    local DESC_CONTENT_WIDTH = 700 -- 470
    local SKILL_DESC_WIDTH = DESC_CONTENT_WIDTH - 30    -- 技能描述更短一些
    local petInfo = self.petInfos[self.current] or {}

    self.infoPanel = self.root:AddChild(Widget("petInfoRoot"))
    self.infoPanel:SetPosition(0, 200)

    -- 名字
    local color = QUALITY_COLORS[petInfo.quality]
    local upperCase = string.upper(petInfo.prefab)
    local name_str = "["..QUALITY_LANG[petInfo.quality].."] "..STRINGS.NAMES[upperCase]
    local text = self.infoPanel:AddChild(Text(UIFONT, 60, name_str))
    text:SetHAlign(ANCHOR_LEFT)
    text:SetColour(color[1] / 255, color[2] / 255, color[3] / 255, 1)
    local nameW, nameH = text:GetRegionSize()
    text:SetPosition(nameW / 2 - DESC_CONTENT_WIDTH / 2, 0)

    -- ID
    local id_str = "ID:"..petInfo.id.."("..tostring(self.current).."/"..tostring(#self.petInfos)..")"
    local idText = self.infoPanel:AddChild(Text(UIFONT, 40, id_str))
    idText:SetHAlign(ANCHOR_LEFT)
    local idW, idH = idText:GetRegionSize()
    idText:SetPosition(DESC_CONTENT_WIDTH / 2 - idW / 2, 0)

    -- 技能列表
    local offsetTop = -50
    for skillName, skillData in pairs(petInfo.skills) do
        local skillQuality = skillData.quality

        -- 技能名
        local skill_str = SKILL_LANG[skillName]

        -- 技能等级
        local maxLevel = SKILL_MAX_LEVEL[skillName][skillQuality]
        skill_str = skill_str.."[Lv."..tostring(skillData.lv).."]"

        if maxLevel == skillData.lv then
            skill_str = skill_str.."[MAX]"
        end

        local skill_name_str = skill_str
        skill_str = skill_str..": "

        -- 技能描述
        skill_str = skill_str..SKILL_DESC_LANG[skillName]

        -- 技能变量替换
        local skillConstant = SKILL_CONSTANT[skillName] or {}
        local func = SKILL_DESC_VARS[skillName]
        if func ~= nil then
            local vars = func(skillConstant, skillData.lv)
            for key, value in pairs(vars) do
                skill_str = string.gsub(skill_str, key, string.format("%.1f", value))
            end
        end

        local skillText = self.infoPanel:AddChild(Text(UIFONT, 50))

        skillText:SetMultilineTruncatedString(skill_str, 14, SKILL_DESC_WIDTH, 200) -- 163
        skillText:SetHAlign(ANCHOR_LEFT)

        local TW, TH = skillText:GetRegionSize()
        skillText:SetPosition(TW / 2 - SKILL_DESC_WIDTH / 2, offsetTop - TH / 2)

        -- 技能名字用颜色覆盖
        local colorSkillText = self.infoPanel:AddChild(Text(UIFONT, 50, skill_name_str))
        colorSkillText:SetHAlign(ANCHOR_LEFT)

        local skillClr = QUALITY_COLORS[skillQuality]
        colorSkillText:SetColour(skillClr[1] / 255, skillClr[2] / 255, skillClr[3] / 255, 1)

        local SCW, SCH = colorSkillText:GetRegionSize()
        colorSkillText:SetPosition(SCW / 2 - SKILL_DESC_WIDTH / 2, offsetTop - SCH / 2)

        -- 偏移位置
        offsetTop = offsetTop - TH - 10
    end
end

------------------------------ 更新按钮 ------------------------------
function PetInfoWidget:RefreshControls()
    if self.petOwner ~= true then
        return
    end

    if self.menu ~= nil then
        self.menu:Kill()
    end

    self.buttons = {}
    table.insert(self.buttons, {
        text = self.config.prevBtn.text,
        cb = function(inst, button, down)
            if self.canClick then
                -- 上一个
                self.current = self.current - 1
                if self.current < 1 then
                    self.current = #self.petInfos
                end
                self:RefreshStatus()
            end
        end,
        control = self.config.prevBtn.control,
    })

    if self.config.toggleBtn ~= nil then
        table.insert(self.buttons, {
            text = self.config.toggleBtn.text,
            cb = function()
                if self.canClick then
                    local petInfo = self.petInfos[self.current]
                    if petInfo ~= nil then
                        aipRPC("aipTogglePet", petInfo.id)
                    end
                end
            end,
            control = self.config.toggleBtn.control,
        })
    end

    table.insert(self.buttons, {
        text = self.config.nextBtn.text,
        cb = function()
            if self.canClick then
                -- 下一个
                self.current = self.current + 1
                if self.current > #self.petInfos then
                    self.current = 1
                end
                self:RefreshStatus()
            end
        end,
        control = self.config.nextBtn.control,
    })

    local menuoffset = self.config.menuoffset or Vector3(0, 0, 0)
    if TheInput:ControllerAttached() then
        local spacing = 150
        self.menu = self.root:AddChild(Menu(self.buttons, spacing, true, "none"))
        self.menu:SetTextSize(45)
        local w = self.menu:AutoSpaceByText(15)
        self.menu:SetPosition(menuoffset.x - .5 * w, menuoffset.y, menuoffset.z)
    else
        local spacing = 110
        self.menu = self.root:AddChild(Menu(self.buttons, spacing, true, "small"))
        self.menu:SetTextSize(40)
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
        if self.menu ~= nil then
            self.menu:Kill()
        end
        if self.infoPane ~= nil then
            self.infoPanel:Kill()
        end

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
    -- SetAutopaused(false)

	PetInfoWidget._base.OnDestroy(self)
end

return PetInfoWidget
