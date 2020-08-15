GLOBAL.STRINGS.AIP = {}

-- 资源
Assets =
{
	Asset("ATLAS", "images/inventoryimages/popcorngun.xml"),
	Asset("ATLAS", "images/inventoryimages/incinerator.xml"),
	Asset("ATLAS", "images/inventoryimages/dark_observer.xml"),
	Asset("ATLAS", "images/inventoryimages/aip_fish_sword.xml"),

	-- 豆酱雕塑需要提前加载
	Asset("ATLAS", "images/inventoryimages/aip_dou_tech.xml"),
	Asset("ANIM", "anim/aip_ui_doujiang_chest.zip"),
	Asset("ATLAS", "images/inventoryimages/aip_doujiang_slot_bg.xml"),
	Asset("ATLAS", "images/inventoryimages/aip_doujiang_slot_ash_bg.xml"),
	Asset("ATLAS", "images/inventoryimages/aip_doujiang_slot_electricity_bg.xml"),
	Asset("ATLAS", "images/inventoryimages/aip_doujiang_slot_fire_bg.xml"),
	Asset("ATLAS", "images/inventoryimages/aip_doujiang_slot_plant_bg.xml"),
	Asset("ATLAS", "images/inventoryimages/aip_doujiang_slot_water_bg.xml"),
	Asset("ATLAS", "images/inventoryimages/aip_doujiang_slot_wind_bg.xml"),
}

-- 物品列表
PrefabFiles =
{
	-- Food
	"aip_veggies",
	"foods",
	"aip_nectar_maker",
	"aip_nectar",
	"aip_leaf_note",

	-- Weapon
	"popcorngun",
	"aip_blood_package",
	"aip_fish_sword",
	"aip_beehave",
	"aip_oar_woodead",
	"aip_dou_opal",
	"aip_dou_scepter",
	"aip_dou_scepter_projectile",
	"aip_heal_fx",
	"aip_dou_inscription",

	-- Building
	"incinerator",
	"aip_woodener",

	-- Orbit
	"aip_orbit",
	"aip_mine_car",

	-- Dress
	"aip_dress",
	"aip_armor_gambler",

	-- Chesspiece
	"aip_chesspiece",

	-- Magic
	"dark_observer",
	"dark_observer_vest",
	"aip_shadow_package",
	"aip_shadow_chest",
	"aip_shadow_wrapper",
}


--------------------------------------- 工具 ---------------------------------------
modimport("scripts/aipUtils.lua")

--------------------------------------- 科技 ---------------------------------------
modimport("scripts/custom_tech_tree.lua")

-- 添加一个 Tab
GLOBAL.RECIPETABS.AIP_DOU_SCEPTER = {
    str = "AIP_DOU_SCEPTER",
    sort = 100,
    icon_atlas = "images/inventoryimages/aip_dou_tech.xml",
    icon = "aip_dou_tech.tex",
    crafting_station = true
}
GLOBAL.STRINGS.TABS.AIP_DOU_SCEPTER = "神秘魔法"

GLOBAL.aipAddNewTechTree("AIP_DOU_SCEPTER")

------------------------------------- 组件钩子 -------------------------------------
modimport("scripts/componentsHooker.lua")

--------------------------------------- 图标 ---------------------------------------
AddMinimapAtlas("minimap/dark_observer_vest.xml")

--------------------------------------- 封装 ---------------------------------------
modimport("scripts/recipeWrapper.lua")
modimport("scripts/seedsWrapper.lua")
modimport("scripts/containersWrapper.lua")
modimport("scripts/itemTileWrapper.lua")
modimport("scripts/hudWrapper.lua")
modimport("scripts/shadowPackageAction.lua")

------------------------------------- 测试专用 -------------------------------------
if GetModConfigData("dev_mode") == "enabled" then
	modimport("scripts/dev.lua")
end

--------------------------------------- 矿车 ---------------------------------------
if GetModConfigData("additional_orbit") == "open" then
	modimport("scripts/mineCarAction.lua")
end


------------------------------------- 对象钩子 -------------------------------------
modimport("scripts/prefabsHooker.lua")


-- 世界追踪
function WorldPrefabPostInit(inst)
	inst:AddComponent("world_common_store")
end

if GLOBAL.TheNet:GetIsServer() or GLOBAL.TheNet:IsDedicated() then
	AddPrefabPostInit("world", WorldPrefabPostInit)
end

------------------------------------- 玩家钩子 -------------------------------------
function PlayerPrefabPostInit(inst)
	if not inst.components.aipc_player_client then
		inst:AddComponent("aipc_player_client")
	end

	if not GLOBAL.TheWorld.ismastersim then
		return
	end
	
	if not inst.components.aipc_timer then
		inst:AddComponent("aipc_timer")
	end
end

AddPlayerPostInit(PlayerPrefabPostInit)