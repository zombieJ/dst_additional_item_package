local descList =
{
	"Provide additional items for game. Enjoy your new package! (You can close part of package in options)",
	"提供额外的物品合成，享受更加丰富的游戏内容吧！（您可以在选项中选择关闭不需要的内容）",
	"Item list:",
	"物品列表：",
	"- Popcorn Gun",
	"- 玉米枪",
	"- incinerator",
	"- 焚烧炉",

	"\n\nFood Recipes:",
	"食品配方：",
	"egg pancake (egg >= 3 and not inedible)",
	"鸡蛋灌饼",

	"\n\n新浪微博：@二货爱吃白萝卜",
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

name = "Additional Item Package"
description = joinArray(descList, "\n")
author = "ZombieJ"
version = "0.0.1"
forumthread = ""
icon_atlas = "modicon.xml"
icon = "modicon.tex"
dst_compatible = true
client_only_mod = false
all_clients_require_mod = true

api_version = 10

configuration_options =
{
    {
		name = "popcorn_uses",
		label = "Popcorn Gun Usage times",
        hover = "Increase the times will need more recipes",
		options =
		{
			{description = "Less", data = "less", hover = "10 times: 1 Corn + 1 Twigs + 1 Rope"},
			{description = "Default", data = "normal", hover = "20 times: 2 Corn + 2 Twigs + 1 Silk"},
			{description = "Much", data = "much", hover = "50 times: 3 Corn + 2 Twigs + 3 Silk"},
		},
		default = "normal",
	},
	{
		name = "popcorn_damage",
		label = "Popcorn Gun Damage",
		options =
		{
			{description = "Less", data = "less", hover = "Damage: 17"},
			{description = "Default", data = "normal", hover = "Damage: 28"},
			{description = "Large", data = "large", hover = "Damage: 60"},
		},
		default = "normal",
	},{
		name = "additional_food",
		label = "Addtional Food Recipes",
		options =
		{
			{description = "Open", data = "open"},
			{description = "Close", data = "close"},
		},
		default = "open",
	},{
		name = "language",
		label = "Language",
		options =
		{
			{description = "中文", data = "chinese"},
			{description = "English", data = "english"},
		},
		default = "english",
	},
}
