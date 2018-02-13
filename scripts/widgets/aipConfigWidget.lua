local Screen = require "widgets/screen"
local Widget = require "widgets/widget"
local Text = require "widgets/text"
local TextEdit = require "widgets/textedit"
local Menu = require "widgets/menu"
local UIAnim = require "widgets/uianim"
local ImageButton = require "widgets/imagebutton"

------------------------------------ 配置 ------------------------------------
local foldername = KnownModIndex:GetModActualName(TUNING.ZOMBIEJ_ADDTIONAL_PACKAGE)
local language = aipGetModConfig("language")

local LANG_MAP = {
	english = {
		CONFIG = "Configuration",
	},
	chinese = {
		CONFIG = "配置",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english
local LANG_ENG = LANG_MAP.english

local function Lang(name)
	return LANG[name] or LANG_ENG[name]
end

------------------------------------------------------------------------------
local ConfigWidget = Class(Screen, function(self, owner, inst, config)
	Screen._ctor(self, "AIP_ConfigWidget")

	self.owner = owner
	self.inst = inst
	self.config = config

	self.isopen = false

	self._scrnw, self._scrnh = TheSim:GetScreenSize()

	self:SetScaleMode(SCALEMODE_PROPORTIONAL)
	self:SetMaxPropUpscale(MAX_HUD_SCALE)
	self:SetPosition(0, 0, 0)
	self:SetVAnchor(ANCHOR_MIDDLE)
	self:SetHAnchor(ANCHOR_MIDDLE)

	-- Resize
	self.scalingroot = self:AddChild(Widget("aipConfigWidgetScalingRoot"))
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

	self.root = self.scalingroot:AddChild(Widget("aipConfigWidgetRoot"))
	self.root:SetScale(.6, .6, .6)

	-- Black
	self.black = self.root:AddChild(Image("images/global.xml", "square.tex"))
	self.black:SetVRegPoint(ANCHOR_MIDDLE)
	self.black:SetHRegPoint(ANCHOR_MIDDLE)
	self.black:SetVAnchor(ANCHOR_MIDDLE)
	self.black:SetHAnchor(ANCHOR_MIDDLE)
	self.black:SetScaleMode(SCALEMODE_FILLSCREEN)
	self.black:SetTint(0, 0, 0, 0)
	self.black.OnMouseButton = function() oncancel(self.writeable, self.owner, self) end

	self.bganim = self.root:AddChild(UIAnim())
	self.bganim:SetScale(1, 1, 1)
	self.bgimage = self.root:AddChild(Image())
	self.bganim:SetScale(1, 1, 1)

	-- Title
	self.title = self.root:AddChild(Text(BUTTONFONT, 45, aipStr(" ", Lang(CONFIG))))
	self.title:SetPosition(10, 190)
	self.title:SetColour(0, 0, 0, 1)
end)

return ConfigWidget