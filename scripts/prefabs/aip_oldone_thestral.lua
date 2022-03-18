-- 开发模式
local dev_mode = aipGetModConfig("dev_mode") == "enabled"

local brain = require("brains/aip_oldone_thestral_brain")

local assets = {
    Asset("ANIM", "anim/aip_oldone_thestral.zip"),
	Asset("ANIM", "anim/aip_oldone_thestral_full.zip"),
}


local language = aipGetModConfig("language")

local LANG_MAP = {
	english = {
		NAME = "Sock Snake",
		DESC = "Hmmm, strange...",
	},
	chinese = {
		NAME = "袜子蛇",
		DESC = "千人千面！",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

-- 文字描述
STRINGS.NAMES.AIP_OLDONE_THESTRAL = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_THESTRAL = LANG.DESC

local sounds = {
	attack = "dontstarve/sanity/creature2/attack",
	attack_grunt = "dontstarve/sanity/creature2/attack_grunt",
	death = "dontstarve/sanity/creature2/die",
	idle = "dontstarve/sanity/creature2/idle",
	taunt = "dontstarve/sanity/creature2/taunt",
	appear = "dontstarve/sanity/creature2/appear",
	disappear = "dontstarve/sanity/creature2/dissappear",
}

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	MakeCharacterPhysics(inst, 10, 1.5)
	RemovePhysicsColliders(inst)
	inst.Physics:SetCollisionGroup(COLLISION.SANITY)
	inst.Physics:CollidesWith(COLLISION.SANITY)

	inst.Transform:SetTwoFaced()
	inst.Transform:SetScale(0.8, 0.8, 0.8)

	-- inst:AddTag("monster")

	inst.AnimState:SetBank("aip_oldone_thestral")
	inst.AnimState:SetBuild("aip_oldone_thestral")
	inst.AnimState:PlayAnimation("idle_loop", true)

	inst.AnimState:SetClientsideBuildOverride(
		"aip_see_eyes", -- 客户端替换贴图，有疯狂的 aip_see_eyes buff 的人才能看到
		"aip_oldone_thestral",
		"aip_oldone_thestral_full"
	)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("inspectable")

	inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
	inst.components.locomotor.walkspeed = TUNING.CRAWLINGHORROR_SPEED

	inst.sounds = sounds

	inst:SetStateGraph("SGaip_oldone_thestral")
	inst:SetBrain(brain)

	inst:AddComponent("timer")

	inst:AddComponent("sanityaura")

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(dev_mode and 6 or 66)

	inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "body"

	inst:AddComponent("lootdropper")
	inst.components.lootdropper:AddChanceLoot("aip_dou_tooth", 1)

	return inst
end

return Prefab("aip_oldone_thestral", fn, assets)

--[[



c_give"aip_armor_gambler"
c_give"aip_oldone_thestral"




]]