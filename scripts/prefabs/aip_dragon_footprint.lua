local assets = {
	Asset("ANIM", "anim/aip_dragon_footprint.zip"),
}

local prefabs = {
    "aip_shadow_wrapper"
}

local function FindSunflower(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
	local ents = TheSim:FindEntities(x, y, z, 100, { "aip_sunflower" })

	for i, v in ipairs(ents) do
		if v.entity:IsVisible() then
			return v
		end
	end

	return nil
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	inst:AddTag("NOCLICK")
	inst:AddTag("FX")

	inst.AnimState:SetBank("aip_dragon_footprint")
	inst.AnimState:SetBuild("aip_dragon_footprint")
	inst.AnimState:PlayAnimation("idle", false)
	inst.AnimState:SetMultColour(1, 1, 1, .7)

	if not TheWorld.ismastersim then
		return inst
	end

	inst.persists = false

	inst:DoTaskInTime(0, function()
		local sunflower = FindSunflower(inst)

		if sunflower ~= nil then
		else

		end
	end)

	return inst
end

return Prefab("aip_dragon", fn, assets, prefabs)