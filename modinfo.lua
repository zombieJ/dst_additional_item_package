local EN = locale ~= "zh" and locale ~= "zhr" and locale ~= "zht"

version = "1.48.0"

local descList = EN and {
	"(DEV MODE)",
	"Provide additional items for game. Enjoy your new package! (You can close part of package in options)",
	"\n",
	"View Steam workshop for more info",
} or {
	"(DEV MODE)",
	"提供额外的物品合成，享受更加丰富的游戏内容吧！（您可以在选项中选择关闭不需要的内容）",
	"\n",
	"浏览 Steam 创意工坊查看更多信息",
	"\n",
	"新浪微博：@二货爱吃白萝卜",
}

local function joinArray(arr, spliter)
	local strs = ""
	for i = 1, #arr do
		if i ~= 1 then
			strs = strs..spliter
		end
		strs = strs..arr[i]
	end
	return strs
end

-- 本地化
local function Lang(en, zh)
	return EN and en or zh
end
local OPEN = Lang("Open", "开启")
local CLOSE = Lang("Close", "关闭")
local SHORTAGE = Lang("Shortage", "匮乏")
local LESS = Lang("Less", "少")
local DEFAULT = Lang("Default", "默认")
local MUCH = Lang("Much", "多")
local LARGE = Lang("Large", "大")

name = Lang("Additional Item Package DEV", "AIP-额外物品包 DEV")
description = joinArray(descList, "\n")
author = "ZombieJ"
forumthread = "http://steamcommunity.com/sharedfiles/filedetails/?id=1085586145"
icon_atlas = "modicon.xml"
icon = "modicon.tex"
priority = -111
dst_compatible = true
client_only_mod = false
all_clients_require_mod = true

api_version = 10

configuration_options = {
	{
		name = "language",
		label = Lang("Language", "语言"),
		options =
		{
			{description = "中文", data = "chinese"},
			{description = "English", data = "english"},
			{description = "Spanish", data = "spanish"},
			{description = "Portuguese", data = "portuguese"},
			{description = "Russian", data = "russian"},
			{description = "Korean", data = "korean"},
		},
		default = "english",
	},
	{
		name = "additional_weapon",
		label = Lang("Weapon Recipes", "武器配方"),
		options = {
			{description = OPEN, data = "open"},
			{description = CLOSE, data = "close"},
		},
		default = "open",
	},
	{
		name = "additional_building",
		label = Lang("Building Recipes", "建筑配方"),
		options = {
			{description = OPEN, data = "open"},
			{description = CLOSE, data = "close"},
		},
		default = "open",
	},
	{
		name = "additional_survival",
		label = Lang("Survival Recipes", "生存配方"),
		options = {
			{description = OPEN, data = "open"},
			{description = CLOSE, data = "close"},
		},
		default = "open",
	},
	{
		name = "additional_food",
		label = Lang("Food Recipes", "食物配方"),
		options =
		{
			{description = OPEN, data = "open"},
			{description = CLOSE, data = "close"},
		},
		default = "open",
	},
	{
		name = "additional_dress",
		label = Lang("Dress Recipes", "服饰配方"),
		options =
		{
			{description = OPEN, data = "open"},
			{description = CLOSE, data = "close"},
		},
		default = "open",
	},
	{
		name = "additional_chesspieces",
		label = Lang("Chesspieces Recipes", "雕塑配方"),
		options =
		{
			{description = OPEN, data = "open"},
			{description = CLOSE, data = "close"},
		},
		default = "open",
	},
	{
		name = "additional_orbit",
		label = Lang("Orbit Recipes", "轨道配方"),
		hover = Lang("Support Orbit. WOW!~", "第一个轨道模组，哇哦！~"),
		options =
		{
			{description = OPEN, data = "open"},
			{description = CLOSE, data = "close"},
		},
		default = "open",
	},
	{
		name = "additional_magic",
		label = Lang("Magic Recipes", "魔法配方"),
		options = {
			{description = OPEN, data = "open"},
			{description = CLOSE, data = "close"},
		},
		default = "open",
	},
	{
		name = "weapon_uses",
		label = Lang("Weapon Usage times", "武器使用次数"),
		options = {
			{description = LESS, data = "less"},
			{description = DEFAULT, data = "normal"},
			{description = MUCH, data = "much"},
		},
		default = "normal",
	},
	{
		name = "weapon_damage",
		label = Lang("Weapon Damage", "武器伤害"),
		options = {
			{description = LESS, data = "less"},
			{description = DEFAULT, data = "normal"},
			{description = LARGE, data = "large"},
		},
		default = "normal",
	},
	{
		name = "survival_effect",
		label = Lang("Survival Item Effect", "生存物品效果"),
		options = {
			{description = LESS, data = "less"},
			{description = DEFAULT, data = "normal"},
			{description = LARGE, data = "large"},
		},
		default = "normal",
	},
	{
		name = "food_effect",
		label = Lang("Food Recipes Effect", "食物效果"),
		options = {
			{description = SHORTAGE, data = "shortage"},
			{description = LESS, data = "less"},
			{description = DEFAULT, data = "normal"},
			{description = LARGE, data = "large"},
		},
		default = "normal",
	},
	{
		name = "dress_uses",
		label = Lang("Dress Usage times", "服饰使用次数"),
		options = {
			{description = LESS, data = "less"},
			{description = DEFAULT, data = "normal"},
			{description = MUCH, data = "much"},
		},
		default = "normal",
	},
	{
		name = "fly_totem",
		label = Lang("Fly Totem", "飞行图腾"),
		options = {
			{description = Lang("Fly", "飞行"), data = "fly"},
			{description = Lang("Fly anyway", "飞行（无视危险）"), data = "fly_anyway"},
			{description = Lang("Teleport", "传送"), data = "teleport"},
			{description = Lang("Teleport Anayway", "传送（无视危险）"), data = "teleport_anyway"},
			{description = Lang("No Build", "无法建造"), data = "close"},
		},
		default = "fly",
	},
	{
		name = "tooltip_enhance",
		label = Lang("Tooltip info enhance", "提示增强"),
		hover = Lang(
			"Let some item in slot support additional tooltip",
			"让部分物品支持额外信息展示"
		),
		options = {
			{description = OPEN, data = "open"},
			{description = CLOSE, data = "close"},
		},
		default = "open",
	},
	--[[{
		name = "additional_experiment",
		label = "Experiment Recipes",
		hover = "Experience new released items",
		options =
		{
			{description = "Open", data = "open"},
			{description = "Close", data = "close"},
		},
		default = "open",
	},]]
	{
		name = "open_beta",
		label = Lang("Open Beta", "公测功能"),
		hover = Lang("Help me to test new items!", "协助我测试新的物品！"),
		options = {
			{description = OPEN, data = "open"},
			{description = CLOSE, data = "close"},
		},
		default = "close",
	},
	{
		name = "dev_mode",
		label = Lang("Dev Mod(DONT OPEN!)", "开发模式（不要开启！）"),
		hover = Lang(
			"This is only for dev and fail track. Please never enable it.",
			"该功能仅供开发使用，将严重干扰游戏运行。"
		),
		options = {
			{description = OPEN, data = "enabled"},
			{description = CLOSE, data = "disabled"},
		},
		default = "disabled",
	},
}
