local _G = GLOBAL

_G.STRINGS.AIP = {}

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

	-- 添加一个动作
	-- Asset( "ANIM", "anim/aip_player_surf.zip"),
}

-- 物品列表
PrefabFiles = {
	-- vest
	"aip_vest",
	"aip_projectile",

	-- Food
	"aip_wheat",
	"aip_sunflower",
	"aip_veggies",
	"foods",
	"aip_nectar_maker",
	"aip_nectar",
	"aip_leaf_note",
	"aip_xinyue_hoe",
	"aip_xinyue_gridplacer",
	"aip_22_fish",

	-- survival
	"aip_blood_package",
	"aip_plaster",
	"aip_igloo",
	"aip_dragon",
	"aip_dragon_tail",
	"aip_dragon_footprint",
	"aip_krampus_plus",

	-- Weapon
	"popcorngun",
	"aip_fish_sword",
	"aip_beehave",
	"aip_oar_woodead",
	"aip_dou_scepter_projectile",
	"aip_heal_fx",
	"aip_sanity_fx",
	"aip_dou_inscription",
	"aip_dou_inscription_package",
	"aip_dou_element_guard",
	"aip_aura",
	"aip_buffer_fx",

	-- Scepter
	"aip_dou_opal",
	"aip_dou_tooth",
	"aip_dou_scepter",

	-- Building
	"incinerator",
	"aip_woodener",
	"aip_glass_chest",

	-- 诡影迷踪
	"aip_dou_totem",
	"aip_fly_totem",
	"aip_score_ball",
	"aip_mini_doujiang",
	"aip_mud_crab",
	"aip_cookiecutter_king",
	"aip_map",
	"aip_olden_tea",
	"aip_shell_stone",
	"aip_suwu",
	"aip_suwu_mound",
	"aip_breadfruit_tree",
	"aip_rubik_fire",
	"aip_rubik",
	"aip_legion",
	"aip_rubik_ghost",
	"aip_rubik_heart",
	"aip_wizard_hat",
	"aip_nightmare_package",
	"aip_aura_track",
	"aip_eye_box",
	"aip_track_tool",

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
	"aip_xiyou_card",
	"aip_xiyou_cards",
	"aip_xiyou_card_package",
}

local language = GetModConfigData("language")

--------------------------------------- 工具 ---------------------------------------
modimport("scripts/aipUtils.lua")

--------------------------------------- 科技 ---------------------------------------
-- 添加对应标签
local AIP_DOU_SCEPTER = AddRecipeTab(
	"AIP_DOU_SCEPTER",
	100,
	"images/inventoryimages/aip_dou_tech.xml",
	"aip_dou_tech.tex",
	nil,
	true
)

local TECH_LANG = {
	english = "Mysterious",
	chinese = "神秘魔法",
}

_G.STRINGS.TABS.AIP_DOU_SCEPTER = TECH_LANG[language]

modimport("scripts/techHooker.lua")

local inscriptions = require("utils/aip_scepter_util").inscriptions
for name, info in pairs(inscriptions) do
	AddRecipe(
		name, info.recipes, AIP_DOU_SCEPTER, _G.TECH.AIP_DOU_SCEPTER,
		nil, nil, true, nil, nil,
		"images/inventoryimages/"..name..".xml", name..".tex"
	)
end

------------------------------------- 组件钩子 -------------------------------------
modimport("scripts/componentsHooker.lua")

--------------------------------------- 图标 ---------------------------------------
AddMinimapAtlas("minimap/dark_observer_vest.xml")
AddMinimapAtlas("minimap/aip_dou_totem.xml")
AddMinimapAtlas("minimap/aip_cookiecutter_king.xml")
AddMinimapAtlas("minimap/aip_fly_totem.xml")

--------------------------------------- 封装 ---------------------------------------
modimport("scripts/containersWrapper.lua")
modimport("scripts/writeablesWrapper.lua")
modimport("scripts/itemTileWrapper.lua")
modimport("scripts/hudWrapper.lua")
modimport("scripts/shadowPackageAction.lua")
modimport("scripts/widgetHooker.lua")
modimport("scripts/recpiesHooker.lua")
modimport("scripts/flyWrapper.lua")
modimport("scripts/houseWrapper.lua")
modimport("scripts/sgHooker.lua")

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
AddPrefabPostInit("world", function(inst)
	if _G.TheNet:GetIsServer() or _G.TheNet:IsDedicated() then
		inst:AddComponent("world_common_store")
	end
end)

------------------------------------- 玩家钩子 -------------------------------------
function PlayerPrefabPostInit(inst)
	if not inst.components.aipc_player_client then
		inst:AddComponent("aipc_player_client")
	end

	-- inst:ListenForEvent("setowner", function()
	-- 	-- 禁止除了键盘外的所有行为
	-- 	if inst.components.playercontroller ~= nil then
	-- 		inst.components.playercontroller.DoAction = function() end
	-- 	end
	-- end)

	-- 黏住目标
	-- inst.components.pinnable:Stick()

	-- 不让走路
	-- inst.components.locomotor.WalkForward = function() end
	-- inst.components.locomotor.RunForward = function()
	-- 	GLOABLa.test()
	-- end

	if not _G.TheWorld.ismastersim then
		return
	end
	
	if not inst.components.aipc_timer then
		inst:AddComponent("aipc_timer")
	end
end

AddPlayerPostInit(PlayerPrefabPostInit)




-- AddPlayerSgPostInit(function(self)
-- 	-- local run_start = self.states.run_start
-- 	-- if run_start then
-- 	-- 	function run_start.onenter(inst, ...)
-- 	-- 	end

-- 	-- 	function run_start.onupdate(inst, ...)
-- 	-- 	end
-- 	-- end

-- 	-- _G.aipTypePrint(self.events)

-- 	-- 移除动画能力
-- 	-- local originLocomoteFn = self.events.locomote.fn

-- 	-- self.events.locomote.fn = function(...)
-- 	-- 	originLocomoteFn(_G.unpack(arg))
-- 	-- end

-- 	-- 修改走路动画
-- 	local run = self.states.run 
-- 	if run then
-- 		local old_enter = run.onenter
-- 		function run.onenter(inst, ...)
-- 			if old_enter then 
-- 				old_enter(inst, ...)
-- 			end
-- 			-- if IsFlying(inst) then
-- 				if not inst.AnimState:IsCurrentAnimation("fall_off") then
-- 					inst.AnimState:PlayAnimation("sand_idle_loop", true)
-- 				end
-- 				inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength() + .5 * FRAMES)
-- 			-- end
-- 		end
-- 	end
-- end)

-- 添加一个状态
-- AddStategraphState("wilson", JumpState(false, true))
-- AddStategraphState("wilson_client", JumpState(true, true))

-- MakeFlyingCharacterPhysics(inst, 1, .5)

-- 船是一个平台，理论上来说，我们可以让玩家坐飞机
-- AddPrefabPostInit("boat", function(inst)
-- 	-- _G.MakeTinyFlyingCharacterPhysics(inst, 1, .5)

-- 	-- -- 边界变大后就会提前跳，然后淹死
-- 	-- inst.components.walkableplatform.radius = 5

-- 	-- 改变物理可以让它飞起来
-- 	-- inst.Physics:SetMass(500)
--     -- inst.Physics:SetFriction(0)
--     -- inst.Physics:SetDamping(5)
--     -- inst.Physics:SetCollisionGroup(_G.COLLISION.FLYERS)
--     -- inst.Physics:ClearCollisionMask()
--     -- inst.Physics:CollidesWith((_G.TheWorld.has_ocean and _G.COLLISION.GROUND) or _G.COLLISION.WORLD)
--     -- inst.Physics:CollidesWith(_G.COLLISION.FLYERS)
--     -- inst.Physics:SetCapsule(.5, 1)
-- end)

-- AddComponentPostInit("drownable", function(self)
-- 	-- 淹不死
-- 	function self:ShouldDrown()
-- 		-- Map:GetPlatformAtPoint(pos_x, pos_y, pos_z, extra_radius) 获取站着的平台
-- 		_G.aipTypePrint("Platform:", self.inst:GetCurrentPlatform())
-- 		return false
-- 	end
-- end)