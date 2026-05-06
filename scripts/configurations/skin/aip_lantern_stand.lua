local skinUtil = require("utils/aip_skin_util")

local PREFAB = "aip_lantern_stand"

return skinUtil.CreateConfig({
	prefab = PREFAB,
	default_skin = "primitive",
	skin_tags = { "AIP_LANTERN_STAND", "CRAFTABLE" },
	skins = {
		{
			id = "primitive",
			name = {
				english = "Primitive Lantern Stand",
				chinese = "原始灯笼架",
			},
		},
		{
			id = "upturn",
			prefab = PREFAB.."_upturn",
			name = {
				english = "Upturned Lantern Stand",
				chinese = "上扬灯笼架",
			},
		},
		{
			id = "thorn",
			prefab = PREFAB.."_thorn",
			name = {
				english = "Thornwood Lantern Stand",
				chinese = "刺木灯笼架",
			},
		},
		{
			id = "luxury",
			prefab = PREFAB.."_luxury",
			name = {
				english = "Luxury Lantern Stand",
				chinese = "奢华灯笼架",
			},
		},
		{
			id = "branch",
			prefab = PREFAB.."_branch",
			name = {
				english = "Branch Lantern Stand",
				chinese = "树枝灯笼架",
			},
		},
		{
			id = "bamboo",
			prefab = PREFAB.."_bamboo",
			name = {
				english = "Bamboo Lantern Stand",
				chinese = "竹竿灯笼架",
			},
		},
		{
			id = "thin",
			prefab = PREFAB.."_thin",
			name = {
				english = "Thin Lantern Stand",
				chinese = "细条灯笼架",
			},
		},
		{
			id = "ironhook",
			prefab = PREFAB.."_ironhook",
			name = {
				english = "Iron Hook Lantern Stand",
				chinese = "铁钩灯笼架",
			},
		},
		{
			id = "post",
			prefab = PREFAB.."_post",
			name = {
				english = "Post Lantern Stand",
				chinese = "驿站灯笼架",
			},
		},
		{
			id = "tall",
			prefab = PREFAB.."_tall",
			name = {
				english = "Tall Lantern Stand",
				chinese = "高脚灯笼架",
			},
		},
		{
			id = "blackiron",
			prefab = PREFAB.."_blackiron",
			name = {
				english = "Black Iron Lantern Stand",
				chinese = "黑铁灯笼架",
			},
		},
	},
})
