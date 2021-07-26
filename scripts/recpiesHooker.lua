local _G = GLOBAL

function GLOBAL.AddModPrefabCookerRecipe(cooker, recipe)
	env.AddCookerRecipe(cooker, recipe)
end

--[[
	名称, 配方, 分类, 等级,
	建筑占位 placer, 最小间距, 不能解锁, 给予数量, 建筑标签？,
	atlas, image, testfn, product, build_mode, build_distance
]]

AddRecipe(
	"aip_score_ball",
	{ Ingredient("pigskin", 1), Ingredient("silk", 1), Ingredient("cutgrass", 6) }, 
	_G.RECIPETABS.TOOLS, _G.TECH.LOST,
	nil, nil, nil, nil, nil,
	"images/inventoryimages/aip_score_ball.xml",
	"aip_score_ball.tex"
)
