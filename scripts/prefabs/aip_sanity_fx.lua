local language = aipGetModConfig("language")

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddNetwork()
	
  MakeInventoryPhysics(inst)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
  end

  inst:AddComponent("sanityaura")
  inst.components.sanityaura.aura = TUNING.SANITYAURA_SMALL

  inst.persists = false

  inst:DoTaskInTime(7, inst.Remove)

	return inst
end

return Prefab("aip_sanity_fx", fn)
