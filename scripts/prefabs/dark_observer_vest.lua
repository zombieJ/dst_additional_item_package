local foldername = KnownModIndex:GetModActualName(TUNING.ZOMBIEJ_ADDTIONAL_PACKAGE)

-- 配置
local additional_food = GetModConfigData("additional_food", foldername)
local language = GetModConfigData("language", foldername)

if additional_food ~= "open" then
	return nil
end

local LANG_MAP = {
	["english"] = {
		["NAME"] = "Observer",
		["DESC"] = "The icon from dark observer",
		["DESCRIBE"] = "Following the monster",
	},
	["chinese"] = {
		["NAME"] = "观察者",
		["DESC"] = "跟随Boss的马甲单位",
		["DESCRIBE"] = "紧跟着怪物",
	},
}

local LANG = LANG_MAP[language]

-- 文字描述
STRINGS.NAMES.DARK_OBSERVER_VEST = LANG.NAME
STRINGS.RECIPE_DESC.DARK_OBSERVER_VEST = LANG.DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.DARK_OBSERVER_VEST = LANG.DESCRIBE

-----------------------------------------------------------
require "prefabutil"

local assets =
{
	-- Asset("ANIM", "anim/dark_observer_vest.zip"),
	-- Asset("ATLAS", "images/inventoryimages/dark_observer_vest.xml"),
	-- Asset("IMAGE", "images/inventoryimages/dark_observer_vest.tex"),
	Asset("ATLAS", "minimap/dark_observer_vest.xml"),
	Asset("IMAGE", "minimap/dark_observer_vest.tex"),
}

local prefabs =
{
	"globalmapiconunderfog",
}

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	-- inst.entity:AddAnimState()
	inst.entity:AddMiniMapEntity()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	-- 小地图
	inst.MiniMapEntity:SetIcon("dark_observer_vest.tex")
	inst.MiniMapEntity:SetCanUseCache(false)
	inst.MiniMapEntity:SetDrawOverFogOfWar(true)
	inst.MiniMapEntity:SetRestriction("player")
	inst.MiniMapEntity:SetPriority(10)

	-- 探知地图
	inst:AddComponent("maprevealable")
	inst.components.maprevealable:SetIconPrefab("globalmapiconunderfog")
	inst.components.maprevealable:SetIcon("dark_observer_vest.tex")

	-- 动画
	-- inst.AnimState:SetBank("dark_observer_vest")
	-- inst.AnimState:SetBuild("dark_observer_vest")
	-- inst.AnimState:PlayAnimation("idle", true)

	-- inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	-- 可检查
	inst:AddComponent("inspectable")

	return inst
end

return Prefab("dark_observer_vest", fn, assets, prefabs)