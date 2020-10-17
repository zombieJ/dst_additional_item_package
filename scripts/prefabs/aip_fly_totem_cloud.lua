local assets = {
	Asset("ANIM", "anim/aip_totem_cloud.zip"),
}

local function DeCloud(inst, parent)
	inst:ListenForEvent("animover", function()
		if parent then
			parent:RemoveChild(inst)
		end
		inst:Remove()
	end)

	inst.AnimState:PlayAnimation("remove")
end

function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	inst.AnimState:SetBank("aip_totem_cloud")
	inst.AnimState:SetBuild("aip_totem_cloud")
	inst.AnimState:PlayAnimation("idle", true)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst.DeCloud = DeCloud

	return inst
end

return Prefab("aip_fly_totem_cloud", fn, assets)