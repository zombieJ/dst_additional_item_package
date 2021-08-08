local dev_mode = aipGetModConfig("dev_mode") == "enabled"

local language = aipGetModConfig("language")

local characterData = require("prefabs/aip_xiyou_card_data")
local charactersChance = characterData.charactersChance

-- 资源
local assets = {
	Asset("ATLAS", "images/inventoryimages/aip_xiyou_card_package.xml"),
	Asset("ANIM", "anim/aip_xiyou_card.zip"),
}

local prefabs = {}

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Character Package",
		DESC = "Don't over indulge in it ",
	},
	chinese = {
		NAME = "人物卡盲盒",
		DESC = "不要过度沉迷其中",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_XIYOU_CARD_PACKAGE = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_XIYOU_CARD_PACKAGE = LANG.DESC

----------------------------------- 方法 -----------------------------------
local function canBeActOn(inst, doer)
	return true
end

local function onDoAction(inst, doer)
	local cnt = 2 + math.random() * 2
	for i = 1, cnt do
		inst.components.lootdropper:DropLoot()
	end

	inst.components.stackable:Get():Remove()
end

----------------------------------- 实体 -----------------------------------
function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()
	
	MakeInventoryPhysics(inst)
	MakeInventoryFloatable(inst, "med", nil, 0.75)
	
	inst.AnimState:SetBank("aip_xiyou_card")
	inst.AnimState:SetBuild("aip_xiyou_card")
	inst.AnimState:PlayAnimation("package")

	inst.entity:SetPristine()

	inst:AddComponent("aipc_action_client")
	inst.components.aipc_action_client.canBeActOn = canBeActOn

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("lootdropper")
	for name, chance in pairs(charactersChance) do
		inst.components.lootdropper:AddRandomLoot(name, chance)
	end
	inst.components.lootdropper.numrandomloot = 1

	inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

	inst:AddComponent("aipc_action")
	inst.components.aipc_action.onDoAction = onDoAction

	inst:AddComponent("inspectable")

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_xiyou_card_package.xml"

	MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
	MakeSmallPropagator(inst)

	return inst
end

return Prefab("aip_xiyou_card_package", fn, assets, prefabs)