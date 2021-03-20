local assets =
{
    Asset("ANIM", "anim/aip_sunflower.zip"),
}

------------------------------- 不同阶段 -------------------------------
local function sunflower(stage)
	local function fn()
		local inst = CreateEntity()

		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddSoundEmitter()
		inst.entity:AddMiniMapEntity()
		inst.entity:AddNetwork()

		MakeObstaclePhysics(inst, .25)

		inst.MiniMapEntity:SetIcon("twiggy.png")

		inst.MiniMapEntity:SetPriority(-1)

		inst:AddTag("plant")
		inst:AddTag("tree")

		inst.AnimState:SetBuild("aip_sunflower")
		inst.AnimState:SetBank("aip_sunflower")
		inst.AnimState:PlayAnimation("idle_"..stage, true)

		inst.AnimState:Hide("snow")

		-- MakeSnowCoveredPristine(inst)

		inst.entity:SetPristine()

		if not TheWorld.ismastersim then
			return inst
		end

		MakeLargeBurnable(inst, TUNING.TREE_BURN_TIME)
		MakeMediumPropagator(inst)

		-- MakeSnowCovered(inst)

		return inst
	end

	return Prefab("aip_sunflower_"..stage, fn, assets)
end

---------------------------------- 树 ----------------------------------
local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddMiniMapEntity()
	inst.entity:AddNetwork()

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:DoTaskInTime(0, function()
		aipReplacePrefab(inst, "aip_sunflower_tall")
	end)

	return inst
end

--------------------------------- 遍历 ---------------------------------

local PLANTS = { "tall" }
local prefabs = {
	Prefab("aip_sunflower", fn, assets)
}

for i, stage in ipairs(PLANTS) do
	table.insert(prefabs, sunflower(stage))
end

return unpack(prefabs)

--                                              c_give"aip_sunflower"