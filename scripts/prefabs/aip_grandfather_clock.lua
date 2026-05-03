local language = aipGetModConfig("language")

require "prefabutil"

local skinUtil = require("utils/aip_skin_util")
local clockConfig = require("configurations/skin/aip_grandfather_clock")

local LANG_MAP = {
	english = {
		NAME = "Grandfather Clock",
		REC_DESC = "A stately clock for decoration",
		DESC = "It keeps time with a patient little tick.",
	},
	chinese = {
		NAME = "座钟",
		REC_DESC = "一座稳重的装饰座钟。",
		DESC = "它耐心地滴答着。",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_GRANDFATHER_CLOCK = LANG.NAME
STRINGS.RECIPE_DESC.AIP_GRANDFATHER_CLOCK = LANG.REC_DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_GRANDFATHER_CLOCK = LANG.DESC
skinUtil.RegisterBuildSkinConfig(clockConfig, language, LANG.DESC)

local assets = {
	Asset("ANIM", "anim/aip_grandfather_clock.zip"),
}

for _, asset in ipairs(clockConfig.GetInventoryAtlasAssets(true)) do
	table.insert(assets, asset)
end

local DEFAULT_SKIN = clockConfig.DEFAULT_SKIN

local function playSkin(inst, skin, hit)
	skin = clockConfig.GetSkin(skin)

	if hit then
		inst.AnimState:PlayAnimation(skin.."_hit")
		inst.AnimState:PushAnimation(skin, true)
	else
		inst.AnimState:PlayAnimation(skin, true)
	end
end

local skinner = skinUtil.CreatePrefabSkinner(clockConfig, {
	net_field = "_aipGrandfatherClockSkin",
	current_field = "_aipCurrentSkin",
	dirty_event = "aip_grandfather_clock_skindirty",
	set_fn_name = "SetClockSkin",
	next_fn_name = "NextClockSkin",
	play_fn = playSkin,
})

local function onhammered(inst)
	inst.components.lootdropper:DropLoot()

	local fx = SpawnPrefab("collapse_small")
	fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
	fx:SetMaterial("wood")

	inst:Remove()
end

local function onhit(inst)
	skinner.PlayCurrent(inst, true)
end

local function onbuilt(inst)
	skinner.PlayCurrent(inst)

	if inst.SoundEmitter ~= nil then
		inst.SoundEmitter:PlaySound("dontstarve/common/place_structure_wood")
	end
end

local function onload(inst, data)
	skinner.OnLoad(inst, data)
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	inst:AddTag("structure")

	MakeObstaclePhysics(inst, .25)

	inst.AnimState:SetBank("aip_grandfather_clock")
	inst.AnimState:SetBuild("aip_grandfather_clock")

	skinner.SetupNetwork(inst)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	skinner.SetupMaster(inst)

	inst:AddComponent("inspectable")

	inst:AddComponent("lootdropper")
	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
	inst.components.workable:SetWorkLeft(2)
	inst.components.workable:SetOnFinishCallback(onhammered)
	inst.components.workable:SetOnWorkCallback(onhit)

	inst.OnSave = skinner.OnSave
	inst.OnLoad = onload

	inst:ListenForEvent("onbuilt", onbuilt)

	MakeHauntableWork(inst)

	return inst
end

local prefabs = {
	Prefab("aip_grandfather_clock", fn, assets),
	MakePlacer("aip_grandfather_clock_placer", "aip_grandfather_clock", "aip_grandfather_clock", DEFAULT_SKIN),
}

for _, skinPrefab in ipairs(skinner.CreatePrefabSkins()) do
	table.insert(prefabs, skinPrefab)
end

return unpack(prefabs)
