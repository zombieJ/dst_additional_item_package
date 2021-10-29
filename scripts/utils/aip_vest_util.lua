-- 创建客户端马甲单位
function createClientVest(bank, build, animate, sound)
	local inst = CreateEntity()

	inst:AddTag("FX")
	inst:AddTag("NOCLICK")
	--[[Non-networked entity]]
	inst.entity:SetCanSleep(false)
	inst.persists = false

	inst.entity:AddTransform()
	inst.entity:AddAnimState()

	if sound ~= nil then
		inst.entity:AddSoundEmitter()
	end

	MakeProjectilePhysics(inst)

	inst.Physics:ClearCollisionMask()

	inst.AnimState:SetBank(bank)
	inst.AnimState:SetBuild(build)
	inst.AnimState:PlayAnimation(animate)

	return inst
end

-- 创建客户端马甲且动画播放完会消失的单位
function createEffectVest(bank, build, animate, sound)
	local inst = createClientVest(bank, build, animate, sound)

	-- inst.AnimState:SetFinalOffset(-1)
	inst:ListenForEvent("animover", inst.Remove)

	if sound ~= nil then
		inst.SoundEmitter:PlaySound(sound)
	end

	return inst
end

-- 创建地面马甲
function createGroudVest(bank, build, animate)
	local inst = CreateEntity()

	inst:AddTag("FX")
	inst:AddTag("NOCLICK")
	--[[Non-networked entity]]
	inst.entity:SetCanSleep(false)
	inst.persists = false

	inst.entity:AddTransform()
	inst.entity:AddAnimState()

	MakeCharacterPhysics(inst, 1, .1)
	RemovePhysicsColliders(inst)

	inst.AnimState:SetBank(bank)
	inst.AnimState:SetBuild(build)
	inst.AnimState:PlayAnimation(animate)

	inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
	inst.AnimState:SetLayer(LAYER_WORLD_BACKGROUND)
	inst.AnimState:SetSortOrder(2)

	inst:ListenForEvent("animover", inst.Remove)

	return inst
end

-- 飞到目标点或者物
function createProjectile(source, target, fn, color, speed)
	local proj = aipSpawnPrefab(source, "aip_projectile")

	-- 设置颜色
	if color ~= nil then
		proj.components.aipc_info_client:SetByteArray( -- 调整颜色
			"aip_projectile_color", color
		)
	end

	if speed ~= nil then
		proj.components.aipc_projectile.speed = 10
	end

	if target ~= nil and target.prefab ~= nil then
		proj.components.aipc_projectile:GoToTarget(target, fn)
	else
		proj.components.aipc_projectile:GoToPoint(target, fn)
	end

	return proj
end

return {
	createClientVest = createClientVest,
	createEffectVest = createEffectVest,
	createGroudVest = createGroudVest,
	createProjectile = createProjectile,
}