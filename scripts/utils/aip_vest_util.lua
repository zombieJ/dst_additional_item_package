-- 创建客户端马甲单位
function createClientVest(bank, build, animate)
	local inst = CreateEntity()

	inst:AddTag("FX")
	inst:AddTag("NOCLICK")
	--[[Non-networked entity]]
	inst.entity:SetCanSleep(false)
	inst.persists = false

	inst.entity:AddTransform()
	inst.entity:AddAnimState()

	-- MakeFlyingCharacterPhysics(inst, 1, .1)
	MakeProjectilePhysics(inst)

	-- MakeFlyingCharacterPhysics
	-- local phys = inst.entity:AddPhysics()
    -- phys:SetMass(mass)
    -- phys:SetFriction(0)
    -- phys:SetDamping(5)
    -- phys:SetCollisionGroup(COLLISION.FLYERS)
    -- phys:ClearCollisionMask()
    -- phys:CollidesWith((TheWorld.has_ocean and COLLISION.GROUND) or COLLISION.WORLD)
    -- phys:CollidesWith(COLLISION.FLYERS)
    -- phys:SetCapsule(rad, 1)

	-- MakeProjectilePhysics
	-- local phys = inst.entity:AddPhysics()
	-- phys:SetMass(mass or 1)
	-- phys:SetFriction(.1)
	-- phys:SetDamping(0)
	-- phys:SetRestitution(.5)
	-- phys:SetCollisionGroup(COLLISION.ITEMS)
	-- phys:ClearCollisionMask()
	-- phys:CollidesWith(COLLISION.GROUND)
	-- phys:SetSphere(rad or 0.5)

	inst.Physics:ClearCollisionMask()

	inst.AnimState:SetBank(bank)
	inst.AnimState:SetBuild(build)
	inst.AnimState:PlayAnimation(animate)

	return inst
end

-- 创建客户端马甲且动画播放完会消失的单位
function createEffectVest(bank, build, animate)
	local inst = createClientVest(bank, build, animate)

	-- inst.AnimState:SetFinalOffset(-1)
	inst:ListenForEvent("animover", inst.Remove)

	return inst
end

return {
	createClientVest = createClientVest,
	createEffectVest = createEffectVest,
}