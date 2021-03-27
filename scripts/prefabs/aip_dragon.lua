-- 开发模式
local dev_mode = aipGetModConfig("dev_mode") == "enabled"

local brain = require("brains/aip_dragon_brain")

local assets =
{
    Asset("ANIM", "anim/aip_dragon.zip"),
}

local sounds =
{
	attack = "dontstarve/sanity/creature2/attack",
	attack_grunt = "dontstarve/sanity/creature2/attack_grunt",
	death = "dontstarve/sanity/creature2/die",
	idle = "dontstarve/sanity/creature2/idle",
	taunt = "dontstarve/sanity/creature2/taunt",
	appear = "dontstarve/sanity/creature2/appear",
	disappear = "dontstarve/sanity/creature2/dissappear",
}

local RETARGET_CANT_TAGS = {"bat"}
local RETARGET_ONEOF_TAGS = {"character", "monster"}
local function Retarget(inst)
    local newtarget = FindEntity(inst, TUNING.BAT_TARGET_DIST, function(guy)
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

	-- 纯粹更新一下玩家的显示透明度
	-- inst:AddComponent("transparentonsanity")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
	inst.components.locomotor.walkspeed = TUNING.KNIGHT_WALK_SPEED
	inst.components.locomotor:SetTriggersCreep(false)
	inst.components.locomotor.pathcaps = { ignorecreep = true }

	-- inst.sounds = sounds

	inst:SetStateGraph("SGaip_dragon")
	inst:SetBrain(brain)

	inst:AddComponent("sanityaura")

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(dev_mode and 1 or TUNING.LEIF_HEALTH)
	-- inst.components.health.nofadeout = true

	inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "body"
	inst.components.combat:SetDefaultDamage(1)
    inst.components.combat:SetAttackPeriod(TUNING.TERRORBEAK_ATTACK_PERIOD)
    inst.components.combat:SetRange(TUNING.BAT_ATTACK_DIST)
    inst.components.combat:SetRetargetFunction(3, Retarget)
    inst.components.combat:SetKeepTargetFunction(KeepTarget)

	-- inst:AddComponent("combat")
	-- inst.components.combat.hiteffectsymbol = "body"
	-- inst.components.combat:SetRetargetFunction(3, retargetfn)

	-- inst:AddComponent("shadowsubmissive")

	inst:AddComponent("lootdropper")
	inst.components.lootdropper:AddRandomLoot("honey", 1)
	inst.components.lootdropper.numrandomloot = 1

	-- inst:ListenForEvent("attacked", OnAttacked)
	-- inst:ListenForEvent("newcombattarget", OnNewCombatTarget)
	-- inst:ListenForEvent("death", OnDeath)

	-- if data.name == "terrorbeak" then
	-- 	inst.followtosea = true
	-- 	inst.ExchangeWithOceanTerror = ExchangeWithOceanTerror
	-- end


	inst.persists = false

	return inst
end

return Prefab("aip_dragon", fn, assets)

--[[




c_give"aip_dragon"




]]