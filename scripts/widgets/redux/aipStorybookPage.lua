local Widget = require "widgets/widget"
local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"
local UIAnim = require "widgets/uianim"
local Text = require "widgets/text"
local Grid = require "widgets/grid"
local Spinner = require "widgets/spinner"
local Menu = require "widgets/menu"
local TrueScrollList = require "widgets/truescrolllist"

local TEMPLATES = require "widgets/redux/templates"
local Scroller = require "widgets/redux/aipScroller"

require("util")

----------------------------- 文本描述 -----------------------------
local chinese = require "aipStory/chinese"

-------------------------------------------------------------------------------------------------------
local CookbookPageCrockPot = Class(Widget, function(self, parent_screen, category)
    Widget._ctor(self, "CookbookPageCrockPot")

    self.parent_screen = parent_screen
	self.category = category or "storybook"

	self:InitLayout()

	return self
end)

----------------------------- 初始化布局 -----------------------------
local TOP_OFFSET = 250
local MENU_LEFT = -380

local DESC_LEFT = -240
local DESC_TOP_OFFSET = 25
local DESC_OFFSET = 30 -- 文本与文本之间的间距
local DESC_CONTENT_WIDTH = 710
local DESC_CONTENT_HEIGHT = 580

function CookbookPageCrockPot:InitLayout()
	-- 基本容器
	local scale = 0.8
	self.root = self:AddChild(Widget("contentRoot"))
    self.root:SetScale(scale, scale, scale)

	-- 生成文本
	local menuList = {}
	for i, info in pairs(chinese) do
		table.insert(menuList, {text = info.name, cb = function()
			self:CreateDesc(i)
		end})
	end

	-- 55 是每个菜单的间距
	local destLeftMenu = self.root:AddChild(Menu(menuList, -55, false, "carny_long"))
	destLeftMenu:SetTextSize(35)
	destLeftMenu:SetPosition(MENU_LEFT, TOP_OFFSET, 0)

	-- local test = self.root:AddChild(ImageButton("images/quagmire_recipebook.xml", "cookbook_unknown.tex", "cookbook_unknown_selected.tex"))
	-- test:SetScale(0.1, 0.1, 0.1)
	-- test:SetPosition(0, 0, 0)

	-- 第一次展示第一个
	self:CreateDesc(1)
end

function CookbookPageCrockPot:CreateDesc(index)
	if self.descHolder ~= nil then
		self.descHolder:Kill()
	end

	local descList = chinese[index].desc

	-- 描述容器
	self.descHolder = self.root:AddChild(Scroller(
		0, -DESC_CONTENT_HEIGHT, DESC_CONTENT_WIDTH, DESC_CONTENT_HEIGHT -- 切割范围
	))
	self.descHolder:SetPosition(DESC_LEFT, TOP_OFFSET + DESC_TOP_OFFSET, 0)

	local test = self.descHolder:AddChild(ImageButton("images/quagmire_recipebook.xml", "cookbook_unknown.tex", "cookbook_unknown_selected.tex"))
	test:SetScale(0.05, 0.05, 0.05)
	test:SetPosition(0, 0, 0)

	-- 容器切割
	-- self.descHolder:SetScissor(0, 0, DESC_CONTENT_WIDTH / 2, 200)

	-- 计量器
	local top = 0

	for i, descInfo in ipairs(descList) do
		local contentHeight = 0

		if type(descInfo) == "string" then -- 文本内容
			local text = self.descHolder:PathChild(Text(UIFONT, 30))
			text:SetHAlign(ANCHOR_LEFT)
			text:SetMultilineTruncatedString(descInfo, 14, DESC_CONTENT_WIDTH, 999) -- 163

			local TW, TH = text:GetRegionSize()
			text:SetPosition(TW / 2, top - TH / 2)
			contentHeight = TH

		elseif descInfo.type == "img" then -- 图片
			local atlas = descInfo.atlas
			local image = descInfo.image
			local name = descInfo.name

			if name ~= nil then
				atlas = "images/inventoryimages/"..name..".xml"
                image = name..".tex"
			end

			local img = self.descHolder:PathChild(Image(atlas, image))

			local w, h = img:GetSize()
			img:SetPosition(DESC_CONTENT_WIDTH / 2, top - h / 2)
			contentHeight = h
		end

		top = top - contentHeight - DESC_OFFSET
	end
end

return CookbookPageCrockPot
