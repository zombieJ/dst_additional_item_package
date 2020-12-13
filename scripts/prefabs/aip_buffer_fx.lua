local assets = {
	Asset("ANIM", "anim/aip_buffer.zip")
}

local function fn(data)
	local inst = CreateEntity()

		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddNetwork()

		inst.AnimState:SetBank("aip_buffer")
		inst.AnimState:SetBuild("aip_buffer")

		inst.AnimState:PlayAnimation("idle", true)
		inst.AnimState:SetMultColour(0.24, 0.27, 0.38, 1)

		inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
		inst.AnimState:SetLayer(LAYER_WORLD_BACKGROUND)
		inst.AnimState:SetSortOrder(2)

		inst.entity:SetPristine()

		if not TheWorld.ismastersim then
			return inst
		end

		inst.persists = false

		return inst
end

return Prefab("aip_buffer_fx", fn, assets)