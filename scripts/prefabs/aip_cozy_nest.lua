local language = aipGetModConfig("language")

require "prefabutil"

local cozyNestConfig = require("configurations/aip_cozy_nest")
cozyNestConfig.RegisterPrefabSkins()
cozyNestConfig.RegisterInventoryAtlases()

local LANG_MAP = {
	english = {
		NAME = "Cozy Nest",
		REC_DESC = "A soft little nest for decoration",
		DESC = "It looks wonderfully soft.",
	},
	chinese = {
		NAME = "温馨小窝",
		REC_DESC = "一个柔软温馨的小窝，用作装饰",
		DESC = "看起来软乎乎的。",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_COZY_NEST = LANG.NAME
STRINGS.RECIPE_DESC.AIP_COZY_NEST = LANG.REC_DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_COZY_NEST = LANG.DESC
cozyNestConfig.RegisterStrings(language, LANG.DESC)

local assets = {
	Asset("ANIM", "anim/aip_cozy_nest.zip"),
	Asset("ATLAS", "images/inventoryimages/aip_cozy_nest.xml"),
}

for _, skin in ipairs(cozyNestConfig.SKINS) do
	if skin.prefab ~= nil then
		table.insert(assets, Asset("ATLAS", "images/inventoryimages/"..skin.prefab..".xml"))
	end
end

local SKINS = cozyNestConfig.SKINS
local DEFAULT_SKIN = cozyNestConfig.DEFAULT_SKIN
local SKIN_INDEX = {}
local SKIN_ID_BY_PREFAB = {}
local SKIN_PREFAB_BY_ID = {}

for index, skin in ipairs(SKINS) do
	SKIN_INDEX[skin.id] = index

	if skin.prefab ~= nil then
		SKIN_INDEX[skin.prefab] = index
		SKIN_ID_BY_PREFAB[skin.prefab] = skin.id
		SKIN_PREFAB_BY_ID[skin.id] = skin.prefab
	end
end

local function getSkin(skin)
	local index = SKIN_INDEX[skin]
	return index ~= nil and SKINS[index].id or DEFAULT_SKIN
end

local function playSkin(inst, skin, hit)
	skin = getSkin(skin)

	if hit then
		inst.AnimState:PlayAnimation(skin.."_hit")
		inst.AnimState:PushAnimation(skin, true)
	else
		inst.AnimState:PlayAnimation(skin, true)
	end
end

local function applySkin(inst, skin)
	skin = getSkin(skin)
	inst._aipCurrentSkin = skin
	playSkin(inst, skin)
end

local function applySkinName(inst, skin)
	skin = getSkin(skin)
	inst.skinname = SKIN_PREFAB_BY_ID[skin]
	inst.skin_id = nil
	inst.alt_skin_ids = nil
	inst.skin_build_name = nil
end

local function onSkinDirty(inst)
	applySkin(inst, inst._aipCozyNestSkin:value())
end

local function setNestSkin(inst, skin)
	skin = getSkin(skin)
	inst._aipCurrentSkin = skin
	if TheWorld.ismastersim then
		applySkinName(inst, skin)

		if inst._aipCozyNestSkin ~= nil then
			inst._aipCozyNestSkin:set(skin)
		end
	end
	playSkin(inst, skin)
end

local function nextNestSkin(inst)
	local index = SKIN_INDEX[inst._aipCurrentSkin] or 1
	index = index % #SKINS + 1
	local skin = SKINS[index].id

	setNestSkin(inst, skin)

	if inst.SoundEmitter ~= nil then
		inst.SoundEmitter:PlaySound("dontstarve/common/together/skin_change")
	end
end

_G.aip_cozy_nest_clear_fn = function(inst)
	setNestSkin(inst, DEFAULT_SKIN)
end

local function onhammered(inst)
	inst.components.lootdropper:DropLoot()

	local fx = SpawnPrefab("collapse_small")
	fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
	fx:SetMaterial("wood")

	inst:Remove()
end

local function onhit(inst)
	playSkin(inst, inst._aipCurrentSkin, true)
end

local function onbuilt(inst)
	playSkin(inst, inst._aipCurrentSkin)

	if inst.SoundEmitter ~= nil then
		inst.SoundEmitter:PlaySound("dontstarve/common/place_structure_wood")
	end
end

local function onsave(inst, data)
	data.skin = inst._aipCurrentSkin
end

local function onload(inst, data)
	if inst.skinname ~= nil then
		setNestSkin(inst, inst.skinname)
	elseif data ~= nil and data.skin ~= nil then
		setNestSkin(inst, data.skin)
	end
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	MakeObstaclePhysics(inst, .45)

	inst:AddTag("structure")

	inst.AnimState:SetBank("aip_cozy_nest")
	inst.AnimState:SetBuild("aip_cozy_nest")

	inst._aipCozyNestSkin = net_string(inst.GUID, "aip_cozy_nest._aipCozyNestSkin", "aip_cozy_nest_skindirty")
	inst:ListenForEvent("aip_cozy_nest_skindirty", onSkinDirty)

	applySkin(inst, DEFAULT_SKIN)

	inst.scrapbook_anim = DEFAULT_SKIN
	inst.SetNestSkin = setNestSkin
	inst.NextNestSkin = nextNestSkin
	inst.NextSkin = nextNestSkin

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst._aipCozyNestSkin:set(DEFAULT_SKIN)

	inst:AddComponent("inspectable")

	inst:AddComponent("lootdropper")
	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
	inst.components.workable:SetWorkLeft(2)
	inst.components.workable:SetOnFinishCallback(onhammered)
	inst.components.workable:SetOnWorkCallback(onhit)

	inst.OnSave = onsave
	inst.OnLoad = onload

	inst:ListenForEvent("onbuilt", onbuilt)

	MakeHauntableWork(inst)

	return inst
end

local skinAssets = {}
for _, skin in ipairs(SKINS) do
	if skin.prefab ~= nil then
		skinAssets[skin.prefab] = {
			Asset("ATLAS", "images/inventoryimages/"..skin.prefab..".xml"),
		}
	end
end

local prefabs = {
	Prefab("aip_cozy_nest", fn, assets),
	MakePlacer("aip_cozy_nest_placer", "aip_cozy_nest", "aip_cozy_nest", DEFAULT_SKIN),
}

for _, skin in ipairs(SKINS) do
	if skin.prefab ~= nil then
		local skinId = SKIN_ID_BY_PREFAB[skin.prefab]

		table.insert(prefabs, CreatePrefabSkin(skin.prefab, {
			base_prefab = "aip_cozy_nest",
			type = "item",
			rarity = "Complimentary",
			init_fn = function(inst)
				setNestSkin(inst, skinId)
			end,
			skin_tags = { "AIP_COZY_NEST", "CRAFTABLE" },
			assets = skinAssets[skin.prefab],
			release_group = 0,
		}))
	end
end

return unpack(prefabs)
