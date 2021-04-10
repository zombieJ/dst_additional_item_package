local assets = {
	Asset("ANIM", "anim/aip_dragon_footprint.zip"),
}

local prefabs = {
	"aip_projectile",
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

local function GoToTarget(inst, target)
	local x, y, z = target.Transform:GetWorldPosition()
	local prefab = SpawnPrefab("aip_shadow_wrapper")
	prefab.Transform:SetPosition(x, y, z)
	prefab.DoShow()

	inst:Remove()
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

	inst.AnimState:SetMultColour(1, 1, 1, 1)

	inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
	inst.AnimState:SetLayer(LAYER_WORLD_BACKGROUND)
	inst.AnimState:SetSortOrder(2)

	if not TheWorld.ismastersim then
		return inst
	end

	inst.persists = false

	inst:DoTaskInTime(0, function()
		local sunflower = FindSunflower(inst)
		local x, y, z = inst.Transform:GetWorldPosition()

		if sunflower ~= nil then
			local proj = SpawnPrefab("aip_projectile")
			proj.components.aipc_info_client:SetByteArray( -- 调整颜色
				"aip_projectile_color", { 0, 0, 0, 5 }
			)
			proj.Transform:SetPosition(x, 1, z)
			proj.components.aipc_projectile.speed = 10
			proj.components.aipc_projectile:GoToTarget(sunflower, GoToTarget)
		else
			local prefab = SpawnPrefab("aip_shadow_wrapper")
			prefab.Transform:SetPosition(x, y, z)
			prefab.DoShow()

			inst:Remove()
		end
	end)

	return inst
end

return Prefab("aip_dragon_footprint", fn, assets, prefabs)

--[[



c_give"aip_sunflower"



c_give"aip_dragon_footprint"


]]