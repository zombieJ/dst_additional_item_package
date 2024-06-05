-- 开发模式
local dev_mode = aipGetModConfig("dev_mode") == "enabled"

local brain = require("brains/aip_slime_mold_brain")

local assets = {
    Asset("ANIM", "anim/aip_nectar_bee.zip"),
	Asset("SOUND", "sound/glommer.fsb"),
}


local language = aipGetModConfig("language")

local LANG_MAP = {
	english = {
		NAME = "Greedy Bumblebee",
	},
	chinese = {
		NAME = "贪吃熊蜂",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

-- 文字描述
STRINGS.NAMES.AIP_DRAGON = LANG.NAME

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    inst.DynamicShadow:SetSize(2, .75)

	MakeGhostPhysics(inst, 1, .5)

	inst.Transform:SetTwoFaced()
	-- inst.Transform:SetScale(2, 2, 2)

    inst:AddTag("flying")
    inst:AddTag("ignorewalkableplatformdrowning")

	inst.AnimState:SetBank("aip_nectar_bee")
	inst.AnimState:SetBuild("aip_nectar_bee")
	inst.AnimState:PlayAnimation("idle_loop", true)
	-- inst.AnimState:SetMultColour(1, 1, 1, .7)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
	inst.components.locomotor:EnableGroundSpeedMultiplier(false)
	inst.components.locomotor:SetTriggersCreep(false)
	inst.components.locomotor.pathcaps = { ignorewalls = true, ignorecreep = true, allowocean = true }
	inst.components.locomotor.walkspeed = TUNING.CRAWLINGHORROR_SPEED

	inst.sounds = sounds

	inst:SetStateGraph("SGaip_slime_mold")
	inst:SetBrain(brain)

	inst:AddComponent("timer")

	inst.persists = false

	return inst
end

return Prefab("aip_nectar_bee", fn, assets)
