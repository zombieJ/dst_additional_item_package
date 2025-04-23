local dev_mode = aipGetModConfig("dev_mode") == "enabled"

-- 语言
local language = aipGetModConfig("language")
local LANG_MAP = {
	english = {
		NAME = "Stone Gourd",
		DESC = "It needs to be soaked in magma pool",
	},
	chinese = {
		NAME = "石葫芦",
		DESC = "这得泡岩浆池子里",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

-- 文字描述
STRINGS.NAMES.AIP_STONE_GOURD = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_STONE_GOURD = LANG.DESC

------------------------------- 资源 -------------------------------
local assets = {
	Asset("ANIM", "anim/aip_stone_gourd.zip"),
	Asset("ATLAS", "images/inventoryimages/aip_stone_gourd.xml"),
}

------------------------------- 方法 -------------------------------
local function canActOn(inst, doer, target)
	return target and target:HasTag("lava")
end

local function onDoTargetAction(inst, doer, target)
	if target and target:HasTag("lava") then
		local loot = {
			aip_gourd_lao = 10,
			aip_gourd_zhengxianhong = 1,
			aip_gourd_wugui = 1,
			aip_gourd_baolianyu = 1,
			aip_gourd_qingtian = 1,
		}

		local targetPrefab = aipRandomLoot(loot)
		aipReplacePrefab(inst, targetPrefab)
    end
end

local function replaceRocks(inst)
	aipFlingItem(
		aipReplacePrefab(inst, "rocks")
	)
end

------------------------------- 实体 -------------------------------
local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)
	MakeInventoryFloatable(inst, "small", 0.1, 1)

	inst.AnimState:SetBank("aip_stone_gourd")
	inst.AnimState:SetBuild("aip_stone_gourd")
	inst.AnimState:PlayAnimation("idle")

	inst.entity:SetPristine()

	inst:AddComponent("aipc_action_client")
	inst.components.aipc_action_client.canActOn = canActOn

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("aipc_action")
	inst.components.aipc_action.onDoTargetAction = onDoTargetAction

	inst:AddComponent("inspectable")

	inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.MINE)
	inst.components.workable:SetWorkLeft(1)
	inst.components.workable:SetOnFinishCallback(replaceRocks)

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_stone_gourd.xml"

	MakeHauntableLaunch(inst)

	return inst
end

return Prefab("aip_stone_gourd", fn, assets)