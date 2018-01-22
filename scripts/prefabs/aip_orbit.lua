local foldername = KnownModIndex:GetModActualName(TUNING.ZOMBIEJ_ADDTIONAL_PACKAGE)

------------------------------------ 配置 ------------------------------------
-- 轨道关闭
local additional_orbit = GetModConfigData("additional_orbit", foldername)
if additional_orbit ~= "open" then
	return nil
end

local language = GetModConfigData("language", foldername)

local LANG_MAP = {
	["english"] = {
		["NAME"] = "Orbit",
		["REC_DESC"] = "Play with the train!",
		["DESC"] = "That's old style",
	},
	["chinese"] = {
		["NAME"] = "轨道模组",
		["REC_DESC"] = "在饥荒里搭火车吧！",
		["DESC"] = "古老的艺术",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

-- 资源
local assets =
{
	Asset("ATLAS", "images/inventoryimages/aip_orbit.xml"),
	Asset("ATLAS", "images/inventoryimages/aip_orbit_item.xml"),
	Asset("ANIM", "anim/aip_orbit.zip"),
	Asset("ANIM", "anim/aip_orbit_x.zip"),
}

local prefabs =
{
}

-- 文字描述
STRINGS.NAMES.AIP_ORBIT_ITEM = LANG.NAME
STRINGS.RECIPE_DESC.AIP_ORBIT_ITEM = LANG.REC_DESC
STRINGS.NAMES.AIP_ORBIT = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_ORBIT = LANG.DESC

-- 配方
local aip_orbit_item = Recipe("aip_orbit_item", {Ingredient("boards", 1)}, RECIPETABS.TOWN, TECH.SCIENCE_ONE, nil, nil, nil, 4)
aip_orbit_item.atlas = "images/inventoryimages/aip_orbit_item.xml"

--------------------------- 轨道物品 ---------------------------
-- 重置轨道角度
local function updateOrbitRotation(inst, vertical, horizontal)
	if vertical and horizontal then
		inst.AnimState:SetBank("aip_orbit_x")
		inst.AnimState:SetBuild("aip_orbit_x")

		inst.Transform:SetRotation(180)
	else
		inst.AnimState:SetBank("aip_orbit")
		inst.AnimState:SetBuild("aip_orbit")
		
		if vertical then
			inst.Transform:SetRotation(90)
		else
			inst.Transform:SetRotation(180)
		end
	end

	inst.AnimState:PlayAnimation("idle")
end

-- 遍历轨道
local function adjustOrbit(inst, conductive)
	local x, y, z = inst.Transform:GetWorldPosition()
	local orbits = TheSim:FindEntities(x, y, z, 1.2, { "orbit" })

	local vertical = false
	local horizontal = false

	for i, target in ipairs(orbits) do
		if target ~= inst then
			local e_x, e_y, e_z = target.Transform:GetWorldPosition()

			if e_z ~= z then
				vertical = true
			elseif e_x ~= x then
				horizontal = true
			end

			if conductive then
				adjustOrbit(target, false)
			end
		end
	end

	updateOrbitRotation(inst, vertical, horizontal)
end

local function onDeployOrbit(inst, pt, deployer)
	local orbit = SpawnPrefab("aip_orbit")
	if orbit ~= nil then 
		local x = math.floor(pt.x) + .5
		local y = 0
		local z = math.floor(pt.z) + .5
		orbit.Physics:SetCollides(false)
		orbit.Physics:Teleport(x, y, z)
		-- wall.Physics:SetCollides(true)
		inst.components.stackable:Get():Remove()

		-- 轨道重排
		adjustOrbit(orbit, true)

		orbit.SoundEmitter:PlaySound("dontstarve/common/place_structure_wood")
	end
end

local function itemfn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)

	inst:AddTag("orbitbuilder")

	inst.AnimState:SetBank("aip_orbit")
	inst.AnimState:SetBuild("aip_orbit")
	inst.AnimState:PlayAnimation("idle")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("stackable")
	inst.components.stackable.maxsize = TUNING.STACK_SIZE_MEDITEM

	inst:AddComponent("inspectable")
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_orbit_item.xml"

	inst:AddComponent("deployable")
	inst.components.deployable.ondeploy = onDeployOrbit
	inst.components.deployable:SetDeployMode(DEPLOYMODE.WALL)

	MakeHauntableLaunch(inst)

	return inst
end

----------------------------- 轨道 -----------------------------
local function onhammered(inst, worker)
	if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
		inst.components.burnable:Extinguish()
	end
	-- inst.components.lootdropper:DropLoot()
	inst.components.lootdropper:SpawnLootPrefab('log')

	local fx = SpawnPrefab("collapse_small")
	fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
	fx:SetMaterial("wood")
	inst:Remove()
end

local function onhit(inst, worker)
	if not inst:HasTag("burnt") then
		inst.AnimState:PlayAnimation("hit")
		inst.AnimState:PushAnimation("idle", false)
	end
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	inst.Transform:SetEightFaced()
	-- inst.Transform:SetScale(0.5, 0.5, 0.5)
	-- inst.AnimState:GetCurrentFacing()
	-- https://forums.kleientertainment.com/topic/71094-modding-help/
	-- https://forums.kleientertainment.com/topic/72978-is-it-possible-to-access-variables-from-behaviors/

	MakeObstaclePhysics(inst, .5)
	inst.Physics:SetDontRemoveOnSleep(true)
	inst.Physics:SetCollides(false)

	inst:AddTag("orbit")
	inst:AddTag("noauradamage")
	inst:AddTag("nointerpolate")
	inst:AddTag("wood")

	inst.AnimState:SetBank("aip_orbit")
	inst.AnimState:SetBuild("aip_orbit")
	inst.AnimState:PlayAnimation("idle")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("savedrotation")

	inst:AddComponent("inspectable")
	inst:AddComponent("lootdropper")

	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
	inst.components.workable:SetWorkLeft(3)
	inst.components.workable:SetOnFinishCallback(onhammered)
	inst.components.workable:SetOnWorkCallback(onhit)

	MakeHauntableWork(inst)

	inst:DoTaskInTime(0.5, function()
		adjustOrbit(inst, false)
	end)

	--[[ inst:DoPeriodicTask(1, function()
		local x, y, z = inst.Transform:GetWorldPosition()
		print(">>> Facing:"..tostring(inst.AnimState:GetCurrentFacing()))
		print(">>> Rotation:"..tostring(inst.Transform:GetRotation()))
		print(">>> Position:"..tostring(x).."/"..tostring(y).."/"..tostring(z))
	end) ]]

	return inst
end

-----------------------------------------------------------
--[[local function onhammered(inst, worker)
	if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
		inst.components.burnable:Extinguish()
	end
	inst.components.lootdropper:DropLoot()
	local fx = SpawnPrefab("collapse_small")
	fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
	fx:SetMaterial("wood")
	inst:Remove()
end

local function onhit(inst, worker)
	if not inst:HasTag("burnt") then
		inst.AnimState:PlayAnimation("hit")
		inst.AnimState:PushAnimation("idle", false)
	end
end

local function onbuilt(inst)
	inst.SoundEmitter:PlaySound("dontstarve/common/sign_craft")
end

function fn()
	local inst = CreateEntity()
	
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddMiniMapEntity()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)

	inst.AnimState:SetBank("aip_orbit")
	inst.AnimState:SetBuild("aip_orbit")
	inst.AnimState:PlayAnimation("idle")

	inst.Transform:SetEightFaced()

	inst:AddTag("structure")
	inst:AddTag("orbit")

	inst.entity:SetPristine()
	
	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("inspectable")
	inst:AddComponent("lootdropper")
	
	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
	inst.components.workable:SetWorkLeft(4)
	inst.components.workable:SetOnFinishCallback(onhammered)
	inst.components.workable:SetOnWorkCallback(onhit)

	inst:AddComponent("savedrotation")

	inst:ListenForEvent("onbuilt", onbuilt)

	return inst
end]]

return Prefab("aip_orbit", fn, assets, prefabs),
	Prefab("aip_orbit_item", itemfn, assets, { "aip_orbit", "aip_orbit_item_placer" }),
	MakePlacer("aip_orbit_item_placer", "aip_orbit", "aip_orbit", "idle", false, false, true, nil, -90, "eight")