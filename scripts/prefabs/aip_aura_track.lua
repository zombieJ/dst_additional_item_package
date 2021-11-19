-- 资源
local assets = {
	Asset("ANIM", "anim/aip_aura_track.zip"),
}

local scale = 1.2

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	inst:AddTag("NOCLICK")
    inst:AddTag("FX")

	inst.AnimState:SetBank("aip_aura_track")
	inst.AnimState:SetBuild("aip_aura_track")
	inst.AnimState:PlayAnimation("idle")

	inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
	inst.AnimState:SetLayer(LAYER_WORLD_BACKGROUND)
	inst.AnimState:SetSortOrder(2)

	inst.Transform:SetScale(scale, scale, scale)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	return inst
end

return Prefab("aip_aura_track", fn, assets)