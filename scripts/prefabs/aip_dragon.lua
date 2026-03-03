-- 开发模式
local dev_mode = aipGetModConfig("dev_mode") == "enabled"

local brain = require("brains/aip_dragon_brain")

local assets = {
    Asset("ANIM", "anim/aip_dragon.zip"),
}


local language = aipGetModConfig("language")

local LANG_MAP = {
	english = {
		NAME = "Dragon Horror",
	},
	chinese = {
		NAME = "游龙梦魇",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

-- 文字描述
STRINGS.NAMES.AIP_DRAGON = LANG.NAME

local sounds = {
	attack = "dontstarve/sanity/creature2/attack",
	attack_grunt = "dontstarve/sanity/creature2/attack_grunt",
	death = "dontstarve/sanity/creature2/die",
	idle = "dontstarve/sanity/creature2/idle",
	taunt = "dontstarve/sanity/creature2/taunt",
	appear = "dontstarve/sanity/creature2/appear",
	disappear = "dontstarve/sanity/creature2/dissappear",
}

local RETARGET_CANT_TAGS = {}
local RETARGET_ONEOF_TAGS = {"character"}
local function Retarget(inst)
    local newtarget = FindEntity(
		inst,
		dev_mode and TUNING.BAT_TARGET_DIST or TUNING.PIG_TARGET_DIST,
		function(guy)
            return inst.components.combat:CanTarget(guy)
        end,
        nil,
        RETARGET_CANT_TAGS,
        RETARGET_ONEOF_TAGS
    )

	return newtarget
end

local function KeepTarget(inst, target)
    return true
end

-- 根据目标的理智值施加更多伤害，最多 50 点真实伤害
local function sanityBonusDamageFn(inst, target, damage, weapon)
	if target.components.sanity ~= nil then
		local ptg = target.components.sanity:GetRealPercent()
		return (1 - ptg) * 50
	end
    return 0
end

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
	inst.Transform:SetScale(2, 2, 2)

	inst:AddTag("shadowcreature")
	inst:AddTag("gestaltnoloot")
	inst:AddTag("monster")
	inst:AddTag("hostile")
	inst:AddTag("shadow")
	inst:AddTag("notraptrigger")

	inst.AnimState:SetBank("aip_dragon")
	inst.AnimState:SetBuild("aip_dragon")
	inst.AnimState:PlayAnimation("idle_loop", true)
	inst.AnimState:SetMultColour(1, 1, 1, .7)

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

	inst:SetStateGraph("SGaip_dragon")
	inst:SetBrain(brain)

	inst:AddComponent("timer")

	inst:AddComponent("sanityaura")

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(dev_mode and 100 or TUNING.LEIF_HEALTH)
	-- inst.components.health.nofadeout = true

	inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "body"
	inst.components.combat:SetDefaultDamage(25)
    inst.components.combat:SetAttackPeriod(TUNING.TERRORBEAK_ATTACK_PERIOD)
    inst.components.combat:SetRange(TUNING.BEEQUEEN_ATTACK_RANGE)
    inst.components.combat:SetRetargetFunction(1, Retarget)
    inst.components.combat:SetKeepTargetFunction(KeepTarget)
	inst.components.combat.bonusdamagefn = sanityBonusDamageFn

	inst:AddComponent("lootdropper")
	inst.components.lootdropper:AddChanceLoot("aip_dou_tooth", 1)
	inst.components.lootdropper:AddChanceLoot("aip_nightmare_package", 1)
	inst.components.lootdropper:AddChanceLoot("nightmarefuel", 1)
	inst.components.lootdropper:AddChanceLoot("nightmarefuel", 0.5)
	-- inst.components.lootdropper.numrandomloot = 1

	-- 尾巴数量
	inst._aipTails = {}

	inst.persists = false

	return inst
end

return Prefab("aip_dragon", fn, assets)

--[[



c_give"aip_armor_gambler"
c_give"aip_dragon"




]]