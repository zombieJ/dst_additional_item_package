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
	Asset("ANIM", "anim/aip_orbit.zip"),
}

local prefabs =
{
}

-- 文字描述
STRINGS.NAMES.AIP_ORBIT = LANG.NAME
STRINGS.RECIPE_DESC.AIP_ORBIT = LANG.REC_DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_ORBIT = LANG.DESC

-- 配方
local aip_orbit = Recipe("aip_orbit", {Ingredient("boards", 1)}, RECIPETABS.TOWN, TECH.SCIENCE_ONE, "aip_orbit_placer")
aip_orbit.atlas = "images/inventoryimages/aip_orbit.xml"

-----------------------------------------------------------
local function onhammered(inst, worker)
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

	MakeObstaclePhysics(inst, 0)

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
end

return Prefab("aip_orbit", fn, assets, prefabs),
	MakePlacer("aip_orbit_placer", "aip_orbit", "aip_orbit", "idle", nil, nil, nil, nil, -90, "eight")