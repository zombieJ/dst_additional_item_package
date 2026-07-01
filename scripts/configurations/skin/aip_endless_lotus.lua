local skinUtil = require("utils/aip_skin_util")

local PREFAB = "aip_endless_lotus"

return skinUtil.CreateConfig({
	prefab = PREFAB,
	default_skin = "style_1",
	skin_tags = { "AIP_ENDLESS_LOTUS", "DECOR" },
	skins = {
		{
			id = "style_1",
			name = {
				english = "Endless Lotus",
				chinese = "无限之莲",
			},
		},
		{
			id = "style_2",
			prefab = PREFAB.."_2",
			name = {
				english = "Endless Lotus II",
				chinese = "无限之莲·二式",
			},
		},
		{
			id = "style_3",
			prefab = PREFAB.."_3",
			name = {
				english = "Endless Lotus III",
				chinese = "无限之莲·三式",
			},
		},
	},
})
