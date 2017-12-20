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
local function ondeploywall(inst, pt, deployer)
	local wall = SpawnPrefab("aip_orbit")
	if wall ~= nil then 
		local x = math.floor(pt.x) + .5
		local z = math.floor(pt.z) + .5
		wall.Physics:SetCollides(false)
		wall.Physics:Teleport(x, 0, z)
		-- wall.Physics:SetCollides(true)
		inst.components.stackable:Get():Remove()
		
		wall.SoundEmitter:PlaySound("dontstarve/common/place_structure_wood")
	end
end

local function itemfn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)

	inst:AddTag("wallbuilder")

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
	inst.components.deployable.ondeploy = ondeploywall
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

	MakeObstaclePhysics(inst, .5)
	inst.Physics:SetDontRemoveOnSleep(true)
	inst.Physics:SetCollides(false)

	inst:AddTag("wall")
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

	inst:AddComponent("inspectable")
	inst:AddComponent("lootdropper")

	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
	inst.components.workable:SetWorkLeft(3)
	inst.components.workable:SetOnFinishCallback(onhammered)
	inst.components.workable:SetOnWorkCallback(onhit)

	MakeHauntableWork(inst)

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