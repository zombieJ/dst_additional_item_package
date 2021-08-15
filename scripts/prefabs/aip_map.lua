local language = aipGetModConfig("language")

local LANG_MAP = {
	english = {
    	NAME = "Unverified Map",
		DESC = "Very scribbled",
	},
	chinese = {
		NAME = "不保真的地图",
		DESC = "画的十分潦草",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

-- 资源
local assets = {
	Asset("ANIM", "anim/aip_map.zip"),
	Asset("ATLAS", "images/inventoryimages/aip_map.xml"),
}

local prefabs = {}

-- 文字描述
STRINGS.NAMES.AIP_MAP = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_MAP = LANG.DESC

----------------------------------- 事件 -----------------------------------
local function getRevealTargetPos(inst, doer)
	if TheWorld.components.world_common_store ~= nil then
		local king = TheWorld.components.world_common_store:CreateCoookieKing()
		return king:GetPosition()
	end

	return nil, "NO_TARGET"
end

----------------------------------- 实体 -----------------------------------
function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()
	
	MakeInventoryPhysics(inst)

	inst.AnimState:SetBank("aip_map")
	inst.AnimState:SetBuild("aip_map")
	inst.AnimState:PlayAnimation("idle")

	MakeInventoryFloatable(inst, "small", 0.15, 0.9)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("fuel")
	inst.components.fuel.fuelvalue = TUNING.TINY_FUEL

	inst:AddComponent("inspectable")

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_map.xml"

	inst:AddComponent("mapspotrevealer")
	inst.components.mapspotrevealer:SetGetTargetFn(getRevealTargetPos)
	inst:ListenForEvent("on_reveal_map_spot_pst", inst.Remove)

	MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
	MakeSmallPropagator(inst)

	MakeHauntableLaunchAndIgnite(inst)

	return inst
end

return Prefab("aip_map", fn, assets, prefabs)
