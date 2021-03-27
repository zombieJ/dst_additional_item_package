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

	inst:AddTag("shadowcreature")
	inst:AddTag("gestaltnoloot")
	inst:AddTag("monster")
	inst:AddTag("hostile")
	inst:AddTag("shadow")
	inst:AddTag("notraptrigger")

	inst.AnimState:SetBank("aip_dragon")
	inst.AnimState:SetBuild("aip_dragon")
	inst.AnimState:PlayAnimation("idle", true)
	inst.AnimState:SetMultColour(1, 1, 1, .5)

	-- 纯粹更新一下玩家的显示透明度
	-- inst:AddComponent("transparentonsanity")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
	inst.components.locomotor.walkspeed = TUNING.TERRORBEAK_SPEED
	inst.components.locomotor:SetTriggersCreep(false)
	inst.components.locomotor.pathcaps = { ignorecreep = true }

	-- inst.sounds = sounds
	-- inst:SetStateGraph("SGshadowcreature")

	inst:SetBrain(brain)

	-- inst:AddComponent("sanityaura")
	-- inst.components.sanityaura.aurafn = CalcSanityAura

	-- inst:AddComponent("health")
	-- inst.components.health:SetMaxHealth(data.health)
	-- inst.components.health.nofadeout = true

	-- inst.sanityreward = data.sanityreward

	-- inst:AddComponent("combat")
	-- inst.components.combat:SetDefaultDamage(data.damage)
	-- inst.components.combat:SetAttackPeriod(data.attackperiod)
	-- inst.components.combat:SetRetargetFunction(3, retargetfn)
	-- inst.components.combat.onkilledbyother = onkilledbyother

	-- inst:AddComponent("shadowsubmissive")

	-- inst:AddComponent("lootdropper")
	-- inst.components.lootdropper:SetChanceLootTable('shadow_creature')

	-- inst:ListenForEvent("attacked", OnAttacked)
	-- inst:ListenForEvent("newcombattarget", OnNewCombatTarget)
	-- inst:ListenForEvent("death", OnDeath)

	-- if data.name == "terrorbeak" then
	-- 	inst.followtosea = true
	-- 	inst.ExchangeWithOceanTerror = ExchangeWithOceanTerror
	-- end


	-- inst.persists = false

	return inst
end

return Prefab("aip_dragon", fn, assets)

--[[




c_give"aip_dragon"




]]