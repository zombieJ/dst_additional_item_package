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
local TOP_OFFSET = 275
local MENU_LEFT = -380
local MENU_TOP_OFFSET = 25
local MENU_TOP_OFFSET_UNIT = 10 -- 菜单项的上侧会被切掉，这里设置一个偏移量
local MENU_LEFT_OFFSET = 110
local MENU_ITEM_HEIGHT = 55

local DESC_LEFT = -240
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
	local menuHeight = DESC_CONTENT_HEIGHT + MENU_TOP_OFFSET + MENU_TOP_OFFSET_UNIT
	self.menuScroller = self.root:AddChild(Scroller(
		0, -DESC_CONTENT_HEIGHT, DESC_CONTENT_WIDTH, menuHeight -- 切割范围
	))
	self.menuScroller:SetPosition(MENU_LEFT - MENU_LEFT_OFFSET, TOP_OFFSET + MENU_TOP_OFFSET_UNIT, 0)
	-- self.menuScroller:SetScrollBound(MENU_ITEM_HEIGHT * #menuList)
	self.menuScroller:SetScrollBound(2000)

	local leftMenu = self.menuScroller:PathChild(Menu(menuList, -MENU_ITEM_HEIGHT, false, "carny_long"))
	leftMenu:SetTextSize(35)
	leftMenu:SetPosition(MENU_LEFT_OFFSET, -MENU_TOP_OFFSET - MENU_TOP_OFFSET_UNIT, 0)

	-- local test = self.menuScroller:PathChild(ImageButton("images/quagmire_recipebook.xml", "cookbook_unknown.tex", "cookbook_unknown_selected.tex"))
	-- test:SetScale(0.1, 0.1, 0.1)
	-- test:SetPosition(0, 0, 0)

	-- 第一次展示第一个
	self:CreateDesc(1)
end

local IMG_MAX_WIDTH = 128

function CookbookPageCrockPot:CreateDesc(index)
	if self.currentIndex == index then
		return
	end

	if self.descHolder ~= nil then
		self.descHolder:Kill()
	end

	local descList = chinese[index].desc
	self.currentIndex = index

	-- 描述容器
	self.descHolder = self.root:AddChild(Scroller(
		0, -DESC_CONTENT_HEIGHT, DESC_CONTENT_WIDTH, DESC_CONTENT_HEIGHT -- 切割范围
	))
	self.descHolder:SetPosition(DESC_LEFT, TOP_OFFSET, 0)

	-- local test = self.descHolder:AddChild(ImageButton("images/quagmire_recipebook.xml", "cookbook_unknown.tex", "cookbook_unknown_selected.tex"))
	-- test:SetScale(0.05, 0.05, 0.05)
	-- test:SetPosition(0, 0, 0)

	-- 计量器
	local top = 0

	for i, descInfo in ipairs(descList) do
		local contentHeight = 0

		if type(descInfo) == "string" then -- 文本内容
			local text = self.descHolder:PathChild(Text(UIFONT, 35))
			text:SetHAlign(ANCHOR_LEFT)
			text:SetMultilineTruncatedString(descInfo, 14, DESC_CONTENT_WIDTH, 200) -- 163

			local TW, TH = text:GetRegionSize()
			text:SetPosition(TW / 2, top - TH / 2)
			contentHeight = TH

		elseif descInfo.type == "img" then -- 图片
			local atlas = descInfo.atlas
			local image = descInfo.image
			local name = descInfo.name

			if name ~= nil then
				if softresolvefilepath("images/aipStory/"..name..".xml") ~= nil then
					atlas = "images/aipStory/"..name..".xml"
				elseif softresolvefilepath("images/inventoryimages/"..name..".xml") ~= nil then
					atlas = "images/inventoryimages/"..name..".xml"
				end

				image = name..".tex"
			end

			local img = self.descHolder:PathChild(Image(atlas, image))

			local w, h = img:GetSize()
			local scale = 1

			if descInfo.scale ~= nil then -- 使用设置的长宽比
				scale = descInfo.scale
			elseif w > IMG_MAX_WIDTH then -- 如果尺寸太大，我们拉回去
				scale = IMG_MAX_WIDTH / w
			end

			-- 应用长宽
			img:SetScale(scale, scale)
			w = w * scale
			h = h * scale

			img:SetPosition(DESC_CONTENT_WIDTH / 2, top - h / 2)
			contentHeight = h

		elseif descInfo.type == "anim" then -- 动画
			local anim = self.descHolder:PathChild(UIAnim())
			anim:GetAnimState():SetBuild(descInfo.build)
			anim:GetAnimState():SetBankAndPlayAnimation(
				descInfo.bank or descInfo.build,
				descInfo.anim or "idle", true
			)
			if descInfo.opacity ~= nil then
				anim:GetAnimState():SetMultColour(1,1,1,descInfo.opacity)
			end

			anim:SetScale(descInfo.scale or 1)

			anim:SetPosition(DESC_CONTENT_WIDTH / 2 + (descInfo.left or 0), top - descInfo.height)
			contentHeight = descInfo.height
		end

		top = top - contentHeight - DESC_OFFSET
	end

	-- 设置一下滚动高度
	self.descHolder:SetScrollBound(-top)
end

return CookbookPageCrockPot
