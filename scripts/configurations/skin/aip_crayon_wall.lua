local skinUtil = require("utils/aip_skin_util")

local PREFAB = "aip_crayon_wall_item"

return skinUtil.CreateConfig({
	prefab = PREFAB,
	aliases = { "aip_crayon_wall" },
	skin_tags = { "AIP_CRAYON_WALL", "CRAFTABLE" },
	skins = {
		{
			id = "default",
		},
		{
			id = "blue",
			prefab = "aip_crayon_wall_blue",
			name = {
				english = "Blue Crayon Pillar",
				chinese = "蓝色蜡笔柱",
			},
		},
	},
})
