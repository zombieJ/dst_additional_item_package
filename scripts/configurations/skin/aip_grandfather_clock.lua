local skinUtil = require("utils/aip_skin_util")

local PREFAB = "aip_grandfather_clock"

return skinUtil.CreateConfig({
	prefab = PREFAB,
	skin_tags = { "AIP_GRANDFATHER_CLOCK", "CRAFTABLE" },
	skins = {
		{
			id = "normal",
			name = {
				english = "Grandfather Clock",
				chinese = "普通座钟",
			},
		},
		{
			id = "ruined",
			prefab = PREFAB.."_ruined",
			name = {
				english = "Ruined Grandfather Clock",
				chinese = "破败座钟",
			},
		},
		{
			id = "metal",
			prefab = PREFAB.."_metal",
			name = {
				english = "Metal Grandfather Clock",
				chinese = "金属座钟",
			},
		},
		{
			id = "tall",
			prefab = PREFAB.."_tall",
			name = {
				english = "Tall Grandfather Clock",
				chinese = "高脚座钟",
			},
		},
	},
})
