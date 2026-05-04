local skinUtil = require("utils/aip_skin_util")

local PREFAB = "aip_lantern"

return skinUtil.CreateConfig({
	prefab = PREFAB,
	skin_tags = { "AIP_LANTERN", "CRAFTABLE" },
	skins = {
		{
			id = "rabbit",
			prefab = PREFAB.."_rabbit",
			name = {
				english = "Rabbit Lantern",
				chinese = "兔子灯",
			},
		},
		{
			id = "round",
			prefab = PREFAB.."_round",
			name = {
				english = "Round Lantern",
				chinese = "圆形灯",
			},
		},
		{
			id = "square",
			prefab = PREFAB.."_square",
			name = {
				english = "Square Lantern",
				chinese = "方形灯",
			},
		},
		{
			id = "gourd",
			prefab = PREFAB.."_gourd",
			name = {
				english = "Gourd Lantern",
				chinese = "歪瓜灯",
			},
		},
	},
})
