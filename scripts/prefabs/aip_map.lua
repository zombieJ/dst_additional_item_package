local language = aipGetModConfig("language")

local LANG_MAP = {
	english = {
    	NAME = "Paper Bag",
		DESC = "About a big guy",
	},
	chinese = {
		NAME = "油纸包",
		DESC = "一个关于大家伙的秘密",
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
local function onRemove(inst)
	inst.components.stackable:Get():Remove()
end

-- 如果帝王蟹是隐身状态就 投石问路
local function prereveal(inst, doer)
	if TheWorld.components.world_common_store ~= nil then
		local king = TheWorld.components.world_common_store:CreateCoookieKing()

		if king and king.aipStatus ~= "hunger_1" then
			local cnt = math.random(2, 3) -- 随机 2 ~ 3 个石头
			for i = 1, cnt do
				inst.components.lootdropper:SpawnLootPrefab("aip_shell_stone")
			end
			onRemove(inst)
			return false
		end
	end
	return true
end

-- 展示帝王蟹位置
local function getRevealTargetPos(inst, doer)
	if TheWorld.components.world_common_store ~= nil then
		local king = TheWorld.components.world_common_store:CreateCoookieKing()

		if king ~= nil then
			return king:GetPosition()
		end
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

	inst:AddComponent("lootdropper")

	inst:AddComponent("stackable")
	inst.components.stackable.maxsize = TUNING.STACK_SIZE_LARGEITEM

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_map.xml"

	inst:AddComponent("mapspotrevealer")
	inst.components.mapspotrevealer:SetGetTargetFn(getRevealTargetPos)
	inst.components.mapspotrevealer:SetPreRevealFn(prereveal)
	inst:ListenForEvent("on_reveal_map_spot_pst", onRemove)

	MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
	MakeSmallPropagator(inst)

	MakeHauntableLaunchAndIgnite(inst)

	return inst
end

return Prefab("aip_map", fn, assets, prefabs)
