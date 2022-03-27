local _G = GLOBAL
local TECH = _G.TECH
local CRAFTING_FILTERS = _G.CRAFTING_FILTERS

function GLOBAL.AddModPrefabCookerRecipe(cooker, recipe)
	env.AddCookerRecipe(cooker, recipe)
end

-- 新版 mod 物品配方
local function rec(name, tech, filters, ingredients, placer)
	local filterNames = {}
	for _, filter in ipairs(filters) do
		table.insert(filterNames, filter.name)
	end

	AddRecipe2(
		name,
		ingredients,
		tech,
		{ atlas = "images/inventoryimages/"..name..".xml", placer = placer },
		filterNames
	)
end

--[[
	1 名称, 2 配方, 3 等级,
	4 配置, 5 过滤
]]

-- 鱼刀
rec("aip_fish_sword", TECH.SCIENCE_TWO, { CRAFTING_FILTERS.WEAPONS },
	{Ingredient("pondfish", 1),Ingredient("nightmarefuel", 2),Ingredient("rope", 1)})

-- 马头
rec("aip_horse_head", TECH.SCIENCE_TWO, { CRAFTING_FILTERS.CLOTHING },
	{Ingredient("beefalowool", 5),Ingredient("boneshard", 3),Ingredient("beardhair", 3)})

-- 赌徒铠甲
rec("aip_armor_gambler", TECH.SCIENCE_TWO, { CRAFTING_FILTERS.WEAPONS, CRAFTING_FILTERS.ARMOUR },
	{Ingredient("papyrus", 6),Ingredient("nightmarefuel", 1),Ingredient("rope", 1)})

-- 蜂语
rec("aip_beehave", TECH.MAGIC_TWO, { CRAFTING_FILTERS.MAGIC, CRAFTING_FILTERS.WEAPONS },
	{Ingredient("tentaclespike", 1),Ingredient("stinger", 10),Ingredient("nightmarefuel", 2)})

-- 血袋
rec("aip_blood_package", TECH.SCIENCE_TWO, { CRAFTING_FILTERS.RESTORATION },
	{Ingredient("mosquitosack", 1), Ingredient("spidergland", 3), Ingredient("ash", 2)})

-- 岚色眼镜
rec("aip_blue_glasses", TECH.SCIENCE_TWO, { CRAFTING_FILTERS.CLOTHING },
	{Ingredient("steelwool", 1), Ingredient("ice", 2)})

-- 符文袋
rec("aip_dou_inscription_package", TECH.MAGIC_TWO, { CRAFTING_FILTERS.MAGIC },
	{Ingredient("aip_leaf_note", 2, "images/inventoryimages/aip_leaf_note.xml"),Ingredient("lightbulb", 2)})

-- 玻璃宝箱
rec("aip_glass_chest", TECH.MAGIC_TWO, { CRAFTING_FILTERS.MAGIC },
	{ Ingredient("moonglass", 3), Ingredient("nightmarefuel", 1), Ingredient("plantmeat", 1) },
	"aip_glass_chest_placer")

-- 雪人小屋
rec("aip_igloo", TECH.SCIENCE_TWO, { CRAFTING_FILTERS.STRUCTURES },
	{Ingredient("ice", 21), Ingredient("carrot", 1), Ingredient("twigs", 2)},
	"aip_igloo_placer")

-- 诙谐面具
rec("aip_joker_face", TECH.SCIENCE_TWO, { CRAFTING_FILTERS.CLOTHING },
	{Ingredient("livinglog", 3), Ingredient("spidereggsack", 1), Ingredient("razor", 1)})

-- 守财奴的背包
rec("aip_krampus_plus", TECH.SCIENCE_TWO, { CRAFTING_FILTERS.CONTAINERS },
	{
		Ingredient("klaussackkey", 1), -- 克劳斯钥匙
		Ingredient("fossil_piece", 2), -- 化石骨架
		Ingredient("glommerwings", 1), -- 咕噜咪翅膀
	})

-- 花蜜桶
rec("aip_nectar_maker", TECH.SCIENCE_TWO, { CRAFTING_FILTERS.RESTORATION, CRAFTING_FILTERS.STRUCTURES, CRAFTING_FILTERS.CONTAINERS },
	{Ingredient("boards", 4), Ingredient("goldnugget", 3), Ingredient("rope", 2)},
	"aip_nectar_maker_placer")

-- 草木灰
rec("aip_plaster", TECH.SCIENCE_ONE, { CRAFTING_FILTERS.RESTORATION },
	{Ingredient("ash", 1), Ingredient("poop", 1), Ingredient("cutgrass", 1)})

-- 木图腾
rec("aip_woodener", TECH.MAGIC_TWO, { CRAFTING_FILTERS.MAGIC, CRAFTING_FILTERS.CONTAINERS },
	{Ingredient("goldnugget", 5), Ingredient("livinglog", 2), Ingredient("boards", 3)},
	"aip_woodener_placer")

-- 心悦锄
rec("aip_xinyue_hoe", TECH.SCIENCE_TWO, { CRAFTING_FILTERS.TOOLS },
	{Ingredient("golden_farm_hoe", 1), Ingredient("frozen_heart", 1, "images/inventoryimages/frozen_heart.xml"), Ingredient("boneshard", 5)})

-- 暗影观察者
rec("dark_observer", TECH.MAGIC_TWO, { CRAFTING_FILTERS.MAGIC },
	{Ingredient("livinglog", 5), Ingredient("nightmarefuel", 5), Ingredient("frozen_heart", 1, "images/inventoryimages/frozen_heart.xml")},
	"dark_observer_placer")

-- 焚烧炉
rec("incinerator", TECH.SCIENCE_ONE, { CRAFTING_FILTERS.LIGHT },
	{Ingredient("rocks", 5), Ingredient("twigs", 2), Ingredient("ash", 1)},
	"incinerator_placer")

-- 玉米枪
rec("popcorngun", TECH.SCIENCE_TWO, { CRAFTING_FILTERS.WEAPONS },
	{Ingredient("corn", 2),Ingredient("houndstooth", 4),Ingredient("silk", 3)})

-----------------------------------------------------------------------------------
-- 豆豆球
rec("aip_score_ball", TECH.LOST, { CRAFTING_FILTERS.TOOLS },
	{ Ingredient("pigskin", 1), Ingredient("silk", 1), Ingredient("cutgrass", 6) })

-- 劣质的飞行图腾
rec("aip_fake_fly_totem", TECH.LOST, { CRAFTING_FILTERS.STRUCTURES, CRAFTING_FILTERS.MAGIC },
	{ Ingredient("boards", 1), Ingredient("rope", 1), Ingredient("nightmarefuel", 1) },
	"aip_fake_fly_totem_placer")

-- 飞行图腾。只有蓝图可以做出来，现在不提供
rec("aip_fly_totem", TECH.LOST, { CRAFTING_FILTERS.STRUCTURES, CRAFTING_FILTERS.MAGIC },
	{ Ingredient(_G.CHARACTER_INGREDIENT.SANITY, 35) },
	"aip_fly_totem_placer")

-- 古早茶
rec("aip_olden_tea", TECH.LOST, { CRAFTING_FILTERS.RESTORATION },
	{ Ingredient("messagebottleempty", 1), Ingredient("sweettea", 1), Ingredient("cutreeds", 3) })

-- 饼干碎石
rec("aip_shell_stone", TECH.LOST, { CRAFTING_FILTERS.TOOLS },
	{ Ingredient("cookiecuttershell", 1), Ingredient("moonrocknugget", 1) })
