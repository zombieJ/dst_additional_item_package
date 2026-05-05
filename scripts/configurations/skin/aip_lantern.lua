local skinUtil = require("utils/aip_skin_util")

local PREFAB = "aip_lantern"

return skinUtil.CreateConfig({
	prefab = PREFAB,
	default_skin = "round",
	skin_tags = { "AIP_LANTERN", "CRAFTABLE" },
	skins = {
		{
			id = "round",
		},
		{
			id = "cloth",
			prefab = PREFAB.."_cloth",
			name = {
				english = "Cloth Lantern",
				chinese = "布艺灯",
			},
		},
		{
			id = "horror",
			prefab = PREFAB.."_horror",
			name = {
				english = "Horror Lantern",
				chinese = "恐怖灯",
			},
		},
		{
			id = "oval",
			prefab = PREFAB.."_oval",
			name = {
				english = "Oval Lantern",
				chinese = "扁圆灯",
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
		{
			id = "pattern",
			prefab = PREFAB.."_pattern",
			name = {
				english = "Pattern Lantern",
				chinese = "花纹灯",
			},
		},
		{
			id = "skull",
			prefab = PREFAB.."_skull",
			name = {
				english = "Skull Lantern",
				chinese = "骷髅灯",
			},
		},
	},
})
