local descList =
{
"(DEV MODE)",
	"Provide additional items for game. Enjoy your new package! (You can close part of package in options)",
	"提供额外的物品合成，享受更加丰富的游戏内容吧！（您可以在选项中选择关闭不需要的内容）",

	"\nView Steam workshop for more info",
	"游览Steam创意工坊查看更多信息",

	"\n新浪微博：@二货爱吃白萝卜",
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

name = "Additional Item Package DEV"
description = joinArray(descList, "\n")
author = "ZombieJ"
version = "1.4.1"
forumthread = "http://steamcommunity.com/sharedfiles/filedetails/?id=1085586145"
icon_atlas = "modicon.xml"
icon = "modicon.tex"
priority = -99
dst_compatible = true
client_only_mod = false
all_clients_require_mod = true

api_version = 10

configuration_options =
{
	{
		name = "additional_weapon",
		label = "Weapon Recipes",
		options =
		{
			{description = "Open", data = "open"},
			{description = "Close", data = "close"},
		},
		default = "open",
	},
	{
		name = "additional_building",
		label = "Building Recipes",
		options =
		{
			{description = "Open", data = "open"},
			{description = "Close", data = "close"},
		},
		default = "open",
	},
	{
		name = "additional_survival",
		label = "Survival Recipes",
		options =
		{
			{description = "Open", data = "open"},
			{description = "Close", data = "close"},
		},
		default = "open",
	},
	{
		name = "additional_food",
		label = "Food Recipes",
		options =
		{
			{description = "Open", data = "open"},
			{description = "Close", data = "close"},
		},
		default = "open",
	},
	{
		name = "additional_dress",
		label = "Dress Recipes",
		options =
		{
			{description = "Open", data = "open"},
			{description = "Close", data = "close"},
		},
		default = "open",
	},
	{
		name = "additional_chesspieces",
		label = "Chesspieces Recipes",
		options =
		{
			{description = "Open", data = "open"},
			{description = "Close", data = "close"},
		},
		default = "open",
	},
	{
		name = "additional_orbit",
		label = "Orbit Recipes",
		hover = "Support Orbit. WOW!~",
		options =
		{
			{description = "Open", data = "open"},
			{description = "Close", data = "close"},
		},
		default = "open",
	},
	{
		name = "additional_experiment",
		label = "Experiment Recipes",
		hover = "Experience new released items",
		options =
		{
			{description = "Open", data = "open"},
			{description = "Close", data = "close"},
		},
		default = "open",
	},
	{
		name = "weapon_uses",
		label = "Weapon Usage times",
		options =
		{
			{description = "Less", data = "less"},
			{description = "Default", data = "normal"},
			{description = "Much", data = "much"},
		},
		default = "normal",
	},
	{
		name = "weapon_damage",
		label = "Weapon Damage",
		options =
		{
			{description = "Less", data = "less"},
			{description = "Default", data = "normal"},
			{description = "Large", data = "large"},
		},
		default = "normal",
	},
	{
		name = "survival_effect",
		label = "Survival Item Effect",
		options =
		{
			{description = "Less", data = "less"},
			{description = "Default", data = "normal"},
			{description = "Large", data = "large"},
		},
		default = "normal",
	},
	{
		name = "food_effect",
		label = "Food Recipes Effect",
		options =
		{
			{description = "Less", data = "less"},
			{description = "Default", data = "normal"},
			{description = "Large", data = "large"},
		},
		default = "normal",
	},
	{
		name = "dress_uses",
		label = "Dress Usage times",
		options =
		{
			{description = "Less", data = "less"},
			{description = "Default", data = "normal"},
			{description = "Much", data = "much"},
		},
		default = "normal",
	},
	{
		name = "tooltip_enhance",
		label = "Tooltip info enhance",
		hover = "Let some item in slot support additional tooltip",
		options =
		{
			{description = "Open", data = "open"},
			{description = "Close", data = "close"},
		},
		default = "open",
	},
	{
		name = "language",
		label = "Language",
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
	
	--Minecart exit key option--
	{
		local KEY_A = 65
		local keyslist = {}
		local string = ""
		for i = 1, 26 do
		local ch = string.char(KEY_A + i - 1)
		keyslist[i] = {description = ch, data = ch}
		end
 	 {
    	 	name = "KEYBOARDTOGGLEKEY",
      		label = "Hotkey for exit from minecart",
    		hover = "The key hotkey for exit from minecart.",
      		options = keyslist,
      		default = "X",
  	},

	{
		name = "dev_mode",
		label = "Dev Mod(DONT OPEN!)",
		hover = "This is only for dev and fail track. Please never enable it.",
		options =
		{
			{description = "Enabled", data = "enabled"},
			{description = "Disabled", data = "disabled"},
		},
		default = "disabled",
	},
}
