local assets = {
	Asset("ANIM", "anim/aip_buffer.zip")
}

local function getFn(data)
	-- 返回函数哦
	local function fn()
		local inst = CreateEntity()

		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddNetwork()

		inst.AnimState:SetBank("aip_buffer")
		inst.AnimState:SetBuild("aip_buffer")

		inst.AnimState:PlayAnimation("idle", true)

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

	return fn
end

return Prefab("aip_buffer_fx", fn, assets)