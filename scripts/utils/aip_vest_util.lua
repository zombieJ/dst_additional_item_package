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

	MakeInventoryPhysics(inst)
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