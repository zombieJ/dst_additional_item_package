local skinUtil = require("utils/aip_skin_util")

local PREFAB = "aip_cozy_nest"

return skinUtil.CreateConfig({
	prefab = PREFAB,
	skin_tags = { "AIP_COZY_NEST", "CRAFTABLE" },
	skins = {
		{
			id = "pillow",
			name = {
				english = "Pillow Cozy Nest",
				chinese = "枕头小窝",
			},
		},
		{
			id = "colorful",
			prefab = PREFAB.."_colorful",
			name = {
				english = "Colorful Cozy Nest",
				chinese = "彩色小窝",
			},
		},
		{
			id = "pile",
			prefab = PREFAB.."_pile",
			name = {
				english = "Pillow Pile Cozy Nest",
				chinese = "枕头堆小窝",
			},
		},
		{
			id = "rare",
			prefab = PREFAB.."_rare",
			name = {
				english = "Precious Cozy Nest",
				chinese = "珍品小窝",
			},
		},
		{
			id = "red",
			prefab = PREFAB.."_red",
			name = {
				english = "Red Cozy Nest",
				chinese = "红色小窝",
			},
		},
		{
			id = "patch",
			prefab = PREFAB.."_patch",
			name = {
				english = "Patchwork Cozy Nest",
				chinese = "补丁小窝",
			},
		},
	},
})
