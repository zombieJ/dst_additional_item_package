local _G = GLOBAL
local TECH = _G.TECH
local CRAFTING_FILTERS = _G.CRAFTING_FILTERS
local TECH_INGREDIENT = _G.TECH_INGREDIENT

function GLOBAL.AddModPrefabCookerRecipe(cooker, recipe)
	env.AddCookerRecipe(cooker, recipe)
end

-- 新版 mod 物品配方
local function rec(name, tech, filters, ingredients, placerOrConfig)
	local filterNames = {}
	for _, filter in ipairs(filters) do
		table.insert(filterNames, filter.name)
	end

	local config = {}
	if type(placerOrConfig) == "table" then
		config = placerOrConfig
	else
		config.placer = placerOrConfig
	end

	-- atlas
	if config.atlas == nil then
		config.atlas = "images/inventoryimages/"..name..".xml"
	end

	AddRecipe2(
		name,
		ingredients,
		tech,
		config,
		filterNames
	)
end

--[[
	1 名称, 2 配方, 3 等级,
	4 配置, 5 过滤
]]

-------------------------------------- 废弃 --------------------------------------
-- 【废弃】矿车
rec("aip_mine_car", TECH.LOST, { CRAFTING_FILTERS.TOOLS },
	{ Ingredient("boards", 5) })

-- 【废弃】轨道
rec("aip_orbit_item", TECH.LOST, { CRAFTING_FILTERS.TOOLS },
{ Ingredient("boards", 1) })

-- 【废弃】暗影打包带
rec("aip_shadow_package", TECH.LOST, { CRAFTING_FILTERS.MAGIC },
{ Ingredient("waxpaper", 1), Ingredient("nightmarefuel", 5), Ingredient("featherpencil", 1) })

-------------------------------------- 原版 --------------------------------------
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

-- 弹跳符
rec("aip_jump_paper", TECH.MAGIC_TWO, { CRAFTING_FILTERS.WEAPONS },
	{Ingredient("aip_veggie_wheat", 1, "images/inventoryimages/aip_veggie_wheat.xml"),Ingredient("boomerang", 1),Ingredient("papyrus", 1)})

-- 蜂刺吹箭
rec("aip_blowdart", TECH.SCIENCE_TWO, { CRAFTING_FILTERS.WEAPONS },
	{Ingredient("aip_veggie_wheat", 1, "images/inventoryimages/aip_veggie_wheat.xml"),Ingredient("goldnugget", 2),Ingredient("rope", 1)})

-------------------------------------- 雕塑 --------------------------------------
-- 月光星尘雕像
rec("chesspiece_aip_moon_builder", TECH.SCULPTING_ONE, { CRAFTING_FILTERS.CRAFTING_STATION, CRAFTING_FILTERS.DECOR },
	{Ingredient(TECH_INGREDIENT.SCULPTING, 2), Ingredient("moonrocknugget", 9), Ingredient("frozen_heart", 1, "images/inventoryimages/frozen_heart.xml")},
	{ nounlock=true, actionstr="SCULPTING", atlas = "images/inventoryimages/chesspiece_aip_moon.xml", image = "chesspiece_aip_moon.tex" })

-- 豆酱雕像
rec("chesspiece_aip_doujiang_builder", TECH.SCULPTING_ONE, { CRAFTING_FILTERS.CRAFTING_STATION, CRAFTING_FILTERS.DECOR },
	{Ingredient(TECH_INGREDIENT.SCULPTING, 2), Ingredient("plantmeat_cooked", 1), Ingredient("pinecone", 1)},
	{ nounlock=true, actionstr="SCULPTING", atlas = "images/inventoryimages/chesspiece_aip_doujiang.xml", image = "chesspiece_aip_doujiang.tex" })

-- 守望者雕像
rec("chesspiece_aip_deer_builder", TECH.SCULPTING_ONE, { CRAFTING_FILTERS.CRAFTING_STATION, CRAFTING_FILTERS.DECOR },
{Ingredient(TECH_INGREDIENT.SCULPTING, 2), Ingredient("boneshard", 2), Ingredient("beardhair", 1)},
	{ nounlock=true, actionstr="SCULPTING", atlas = "images/inventoryimages/chesspiece_aip_deer.xml", image = "chesspiece_aip_deer.tex" })

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

------------------------------------ 神秘权杖 ------------------------------------
local scepterData = {
	icon_atlas = "images/inventoryimages/aip_dou_tech.xml",
	icon_image = "aip_dou_tech.tex",
	is_crafting_station = true,
	action_str = "SCULPTING",
	filter_text = _G.STRINGS.UI.CRAFTING_STATION_FILTERS.SCULPTING,
}

env.AddPrototyperDef("aip_dou_scepter", scepterData)
env.AddPrototyperDef("aip_dou_empower_scepter", scepterData)
env.AddPrototyperDef("aip_dou_huge_scepter", scepterData)

-- 符文
local inscriptions = require("utils/aip_scepter_util").inscriptions
for name, info in pairs(inscriptions) do
	rec(name, TECH.AIP_DOU_SCEPTER, { CRAFTING_FILTERS.CRAFTING_STATION, CRAFTING_FILTERS.MAGIC },
	info.recipes, { nounlock=true })
end

------------------------------------ 联结图腾 ------------------------------------
env.AddPrototyperDef("aip_dou_totem", {
	icon_atlas = "images/inventoryimages/aip_totem_tech.xml",
	icon_image = "aip_totem_tech.tex",
	is_crafting_station = true,
	action_str = "SCULPTING",
	filter_text = _G.STRINGS.UI.CRAFTING_STATION_FILTERS.SCULPTING,
})

-- 搬运石偶
rec(
	"aip_shadow_transfer", TECH.AIP_DOU_TOTEM, { CRAFTING_FILTERS.CRAFTING_STATION, CRAFTING_FILTERS.TOOLS, CRAFTING_FILTERS.MAGIC },
	{ Ingredient("moonglass", 2), Ingredient("moonrocknugget", 2), Ingredient("aip_22_fish", 1, "images/inventoryimages/aip_22_fish.xml") },
	{ nounlock=true })

-- 月轨测量仪
rec(
	"aip_track_tool", TECH.AIP_DOU_TOTEM, { CRAFTING_FILTERS.CRAFTING_STATION, CRAFTING_FILTERS.TOOLS, CRAFTING_FILTERS.MAGIC },
	{ Ingredient("moonglass", 6), Ingredient("moonrocknugget", 3), Ingredient("transistor", 1) },
	{ nounlock=true })

-- 玻璃矿车
rec(
	"aip_glass_minecar", TECH.AIP_DOU_TOTEM, { CRAFTING_FILTERS.CRAFTING_STATION, CRAFTING_FILTERS.TOOLS, CRAFTING_FILTERS.MAGIC },
	{ Ingredient("moonglass", 5), Ingredient("goldnugget", 4) },
	{ nounlock=true })

------------------------------------ 古神低语 ------------------------------------
-- 微笑雕像
rec("chesspiece_aip_mouth_builder", TECH.LOST, { CRAFTING_FILTERS.CRAFTING_STATION, CRAFTING_FILTERS.DECOR },
	{ Ingredient(TECH_INGREDIENT.SCULPTING, 2), Ingredient("aip_oldone_plant_broken", 1, "images/inventoryimages/aip_oldone_plant_broken.xml") },
	{ nounlock=true, atlas = "images/inventoryimages/chesspiece_aip_mouth.xml", image = "chesspiece_aip_mouth.tex" })

-- 章鱼雕像
rec("chesspiece_aip_octupus_builder", TECH.LOST, { CRAFTING_FILTERS.CRAFTING_STATION, CRAFTING_FILTERS.DECOR },
	{ Ingredient(_G.TECH_INGREDIENT.SCULPTING, 2), Ingredient("aip_oldone_plant_broken", 1, "images/inventoryimages/aip_oldone_plant_broken.xml") },
	{ nounlock=true, atlas = "images/inventoryimages/chesspiece_aip_octupus.xml", image = "chesspiece_aip_octupus.tex" })

-- 美人鱼雕像
rec("chesspiece_aip_fish_builder", TECH.LOST, { CRAFTING_FILTERS.CRAFTING_STATION, CRAFTING_FILTERS.DECOR },
	{ Ingredient(_G.TECH_INGREDIENT.SCULPTING, 2), Ingredient("aip_oldone_plant_broken", 1, "images/inventoryimages/aip_oldone_plant_broken.xml") },
	{ nounlock=true, atlas = "images/inventoryimages/chesspiece_aip_fish.xml", image = "chesspiece_aip_fish.tex" })

-- 榴星
rec("aip_oldone_durian", TECH.MAGIC_TWO, { CRAFTING_FILTERS.WEAPONS },
	{ Ingredient("durian", 1), Ingredient("aip_oldone_plant_full", 1, "images/inventoryimages/aip_oldone_plant_full.xml"), })

-- 绒线地垫
rec("aip_oldone_thestral_watcher_item", TECH.MAGIC_TWO, { CRAFTING_FILTERS.MAGIC },
	{
		Ingredient("beefalowool", 2),
		Ingredient("aip_oldone_thestral_fur", 1, "images/inventoryimages/aip_oldone_thestral_fur.xml"),
	}, {
		atlas = "images/inventoryimages/aip_oldone_thestral_watcher.xml",
		image = "aip_oldone_thestral_watcher.tex",
	})

------------------------------------ 量子扰动 ------------------------------------
-- 粒子限制器
rec("aip_particles_bottle", TECH.SCIENCE_TWO, { CRAFTING_FILTERS.TOOLS },
	{ Ingredient("messagebottleempty", 1), Ingredient("transistor", 1), })

-- 纠缠粒子
rec("aip_particles_vest_entangled", TECH.SCIENCE_TWO, { CRAFTING_FILTERS.TOOLS },
	{
		Ingredient("aip_particles_bottle_charged", 1, "images/inventoryimages/aip_particles_bottle_charged.xml"),
		Ingredient("heatrock", 2),
	},
	{ atlas = "images/inventoryimages/aip_particles_entangled_blue.xml", image = "aip_particles_entangled_blue.tex" })

	
-- 纠缠粒子
rec("aip_particles_echo", TECH.SCIENCE_TWO, { CRAFTING_FILTERS.TOOLS },
{
	Ingredient("aip_particles_bottle_charged", 1, "images/inventoryimages/aip_particles_bottle_charged.xml"),
	Ingredient("heatrock", 1), Ingredient("thulecite", 1),
})

-- 告密粒子
rec("aip_particles_heart", TECH.SCIENCE_TWO, { CRAFTING_FILTERS.TOOLS },
{
	Ingredient("aip_particles_bottle_charged", 1, "images/inventoryimages/aip_particles_bottle_charged.xml"),
	Ingredient("heatrock", 1), Ingredient("reviver", 1),
})


-- 怠惰的南瓜
rec("aip_tricky_thrower", TECH.MAGIC_TWO, { CRAFTING_FILTERS.STRUCTURES, CRAFTING_FILTERS.MAGIC },
	{ Ingredient("pumpkin_lantern", 1), Ingredient("aip_oldone_deer_eye_fruit", 1, "images/inventoryimages/aip_oldone_deer_eye_fruit.xml"), },
	"aip_tricky_thrower_placer")

-- 展示柜
rec("aip_showcase", TECH.SCIENCE_ONE, { CRAFTING_FILTERS.RESTORATION, CRAFTING_FILTERS.STRUCTURES, CRAFTING_FILTERS.CONTAINERS },
{Ingredient("cutstone", 2), Ingredient("ash", 1)},
"aip_showcase_placer")

-- 图钉展示柜
rec("aip_showcase_ice", TECH.SCIENCE_ONE, { CRAFTING_FILTERS.RESTORATION, CRAFTING_FILTERS.STRUCTURES, CRAFTING_FILTERS.CONTAINERS },
{Ingredient("ice", 8), Ingredient("saltrock", 1)},
"aip_showcase_ice_placer")

-------------------------------------- 联动 --------------------------------------
local modNames = _G.ModManager:GetEnabledServerModNames()

-- 海洋传说
if _G.aipInTable(modNames, "workshop-2827757831") then
	-- 恒温水母
	rec("aip_oldone_jellyfish", TECH.SCIENCE_TWO, { CRAFTING_FILTERS.WINTER, CRAFTING_FILTERS.SUMMER },
	{ Ingredient("saltrock", 5), Ingredient("rain_flower_stone", 1, "images/inventoryimages/rain_flower_stone.xml"), },
	{ atlas = "images/inventoryimages/aip_oldone_jellyfish_cold.xml", image = "aip_oldone_jellyfish_cold.tex" })
end
