local function onRemove(inst)
	-- local smoke = inst:SpawnChild("thurible_smoke")
	-- inst:DoTaskInTime(0.5, inst.Remove)

	local smoke = aipReplacePrefab(inst, "thurible_smoke", nil, 1)
	smoke:DoTaskInTime(0.5, smoke.Remove)

	-- aipTypePrint("POS:", inst:GetPosition())
	-- aipTypePrint("SMOKE:", smoke:GetPosition())
end

---------------------------- 环形球 ----------------------------
local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	MakeProjectilePhysics(inst, .1, .1)

	inst.AnimState:SetBank("projectile")
	inst.AnimState:SetBuild("staff_projectile")
	inst.AnimState:PlayAnimation("fire_spin_loop", true)
	inst.AnimState:OverrideMultColour(0, 0, 0, 0.5)
	
	inst:AddTag("projectile")
	inst:AddTag("flying")
	inst:AddTag("ignorewalkableplatformdrowning")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

    inst:AddComponent("aipc_float")

	inst._aipRemove = onRemove

    -- inst:SpawnChild("thurible_smoke")

    inst.persists = false

	return inst
end


return Prefab("aip_grave_cloak", fn, { Asset("ANIM", "anim/staff_projectile.zip") }, { "torchfire_shadow" })