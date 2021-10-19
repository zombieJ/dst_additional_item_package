local _G = GLOBAL

function GLOBAL.AddModPrefabCookerRecipe(cooker, recipe)
	env.AddCookerRecipe(cooker, recipe)
end

--[[
	1 名称, 2 配方, 3 分类, 4 等级,
	5 建筑占位 placer, 6 最小间距, 7 不能解锁, 8 给予数量, 9 建筑标签？,
	10 atlas, 11 image, 12 testfn, 13 product, 14 build_mode, 15 build_distance
]]

-- 豆豆球
AddRecipe(
	"aip_score_ball",
	{ Ingredient("pigskin", 1), Ingredient("silk", 1), Ingredient("cutgrass", 6) },
	_G.RECIPETABS.TOOLS, _G.TECH.LOST,
	nil, nil, nil, nil, nil,
	"images/inventoryimages/aip_score_ball.xml",
	"aip_score_ball.tex"
)

-- 劣质的飞行图腾
AddRecipe(
	"aip_fake_fly_totem",
	{ Ingredient("boards", 1), Ingredient("rope", 1), Ingredient("nightmarefuel", 1) },
	_G.RECIPETABS.TOWN, _G.TECH.LOST,
	"aip_fake_fly_totem_placer", nil, nil, nil, nil,
	"images/inventoryimages/aip_fake_fly_totem.xml",
	"aip_fake_fly_totem.tex"
)

-- 飞行图腾。只有蓝图可以做出来，现在不提供
AddRecipe(
	"aip_fly_totem",
	{ Ingredient(_G.CHARACTER_INGREDIENT.SANITY, 35) },
	_G.RECIPETABS.TOWN, _G.TECH.LOST,
	"aip_fly_totem_placer", nil, nil, nil, nil,
	"images/inventoryimages/aip_fly_totem.xml",
	"aip_fly_totem.tex"
)

-- 古早茶
AddRecipe(
	"aip_olden_tea",
	{ Ingredient("messagebottleempty", 1), Ingredient("sweettea", 1), Ingredient("cutreeds", 3) },
	_G.RECIPETABS.SURVIVAL, _G.TECH.LOST,
	nil, nil, nil, nil, nil,
	"images/inventoryimages/aip_olden_tea.xml",
	"aip_olden_tea.tex"
)

-- 饼干碎石
AddRecipe(
	"aip_shell_stone",
	{ Ingredient("cookiecuttershell", 1), Ingredient("moonrocknugget", 1) },
	_G.RECIPETABS.TOOLS, _G.TECH.LOST,
	nil, nil, nil, 3, nil,
	"images/inventoryimages/aip_shell_stone.xml",
	"aip_shell_stone.tex"
)