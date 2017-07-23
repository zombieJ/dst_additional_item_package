TUNING.ZOMBIEJ_ADDTIONAL_PACKAGE = "Additional Item Package DEV"

-- 资源
Assets =
{
	Asset("ATLAS", "images/inventoryimages/popcorngun.xml"),
	Asset("ATLAS", "images/inventoryimages/incinerator.xml"),
	Asset("ATLAS", "images/inventoryimages/dark_observer.xml"),
}

-- 物品列表
PrefabFiles =
{
	"popcorngun",
	"incinerator",
	"foods",
	"dark_observer",
	"dark_observer_vest",
}

--------------------------------------- 图标 ---------------------------------------
AddMinimapAtlas("minimap/dark_observer_vest.xml")

--------------------------------------- 食谱 ---------------------------------------
modimport("scripts/recipeWrapper.lua")

--------------------------------------- 钩子 ---------------------------------------
-- 暗影跟随者
function ShadowFollowerPrefabPostInit(inst)
	if not GLOBAL.TheWorld.ismastersim then
		return
	end

	if not inst.components.shadow_follower then
		inst:AddComponent("shadow_follower")
	end
end


AddPrefabPostInit("dragonfly", function(inst) ShadowFollowerPrefabPostInit(inst) end)
AddPrefabPostInit("deerclops", function(inst) ShadowFollowerPrefabPostInit(inst) end)
AddPrefabPostInit("bearger", function(inst) ShadowFollowerPrefabPostInit(inst) end)
AddPrefabPostInit("moose", function(inst) ShadowFollowerPrefabPostInit(inst) end)

-- 世界追踪
function WorldPrefabPostInit(inst)
	if inst:HasTag("forest") then
		inst:AddComponent("world_common_store")
	end
end

if GLOBAL.TheNet:GetIsServer() or GLOBAL.TheNet:IsDedicated() then
	AddPrefabPostInit("world", WorldPrefabPostInit)
end