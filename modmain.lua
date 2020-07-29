GLOBAL.STRINGS.AIP = {}

-- 资源
Assets =
{
	Asset("ATLAS", "images/inventoryimages/popcorngun.xml"),
	Asset("ATLAS", "images/inventoryimages/incinerator.xml"),
	Asset("ATLAS", "images/inventoryimages/dark_observer.xml"),
	Asset("ATLAS", "images/inventoryimages/aip_fish_sword.xml"),
	Asset("ANIM", "anim/aip_ui_doujiang_chest.zip"),
}

-- 物品列表
PrefabFiles =
{
	-- Food
	"aip_veggies",
	"foods",
	"aip_nectar_maker",
	"aip_nectar",

	-- Weapon
	"popcorngun",
	"aip_blood_package",
	"aip_fish_sword",
	"aip_beehave",
	"aip_oar_woodead",
	"aip_dou_scepter",

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

GLOBAL.RECIPETABS.AIP_DOU_SCEPTER = {
    str = "SCEPTER",
    sort = 100,
    icon_atlas = "images/inventoryimages/aip_fish_sword.xml",
    icon = "aip_fish_sword.tex",
    crafting_station = true
}

AddNewTechTree("AIP_DOU_SCEPTER")

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

------------------------------------ 贪婪观察者 ------------------------------------
-- 暗影跟随者
function ShadowFollowerPrefabPostInit(inst)
	if not GLOBAL.TheWorld.ismastersim then
		return
	end

	if not inst.components.shadow_follower then
		inst:AddComponent("shadow_follower")
	end
end


AddPrefabPostInit("dragonfly", function(inst) ShadowFollowerPrefabPostInit(inst) end) -- 龙蝇
AddPrefabPostInit("deerclops", function(inst) ShadowFollowerPrefabPostInit(inst) end) -- 鹿角怪
AddPrefabPostInit("bearger", function(inst) ShadowFollowerPrefabPostInit(inst) end) -- 熊獾
AddPrefabPostInit("moose", function(inst) ShadowFollowerPrefabPostInit(inst) end) -- 麋鹿鹅
AddPrefabPostInit("beequeen", function(inst) ShadowFollowerPrefabPostInit(inst) end) -- 蜂后
AddPrefabPostInit("klaus", function(inst) ShadowFollowerPrefabPostInit(inst) end) -- 克劳斯
AddPrefabPostInit("klaus_sack", function(inst) ShadowFollowerPrefabPostInit(inst) end) -- 克劳斯袋子
AddPrefabPostInit("antlion", function(inst) ShadowFollowerPrefabPostInit(inst) end) -- 蚁狮
AddPrefabPostInit("toadstool", function(inst) ShadowFollowerPrefabPostInit(inst) end) -- 蟾蜍王
AddPrefabPostInit("toadstool_dark", function(inst) ShadowFollowerPrefabPostInit(inst) end) -- 苦难蟾蜍王

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