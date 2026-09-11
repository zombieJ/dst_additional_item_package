local language = aipGetModConfig("language")

local LANG_MAP = {
	english = {
		NAME = "Train Ticket Fragment",
		DESC = "Three fragments become a Pig King train ticket.",
	},
	chinese = {
		NAME = "列车体验券碎片",
		DESC = "集齐三张会自动合成一张正式体验券",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english
local ticket = require("aip_pig_village_ticket")

STRINGS.NAMES.AIP_TRAIN_TICKET_FRAGMENT = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_TRAIN_TICKET_FRAGMENT = LANG.DESC

local assets = {
	Asset("ANIM", "anim/aip_train_ticket_fragment.zip"),
	Asset("ATLAS", "images/inventoryimages/aip_train_ticket_fragment.xml"),
}

-- 保留公共合成入口，供任务奖励和其他发放路径统一触发。
function aipMergeTrainTicketFragments(owner)
	return ticket.ScheduleMerge(owner)
end

-- 物品进入玩家物品栏后检查是否能够合并。
local function OnPutInInventory(inst, owner)
	ticket.ScheduleMerge(owner)
end

-- 创建可以堆叠并自动参与合成的体验券碎片。
local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)

	inst.AnimState:SetBank("aip_train_ticket_fragment")
	inst.AnimState:SetBuild("aip_train_ticket_fragment")
	inst.AnimState:PlayAnimation("idle")

	MakeInventoryFloatable(inst, "small", 0.2, 0.8)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("inspectable")

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.imagename = "aip_train_ticket_fragment"
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_train_ticket_fragment.xml"
	inst.components.inventoryitem:SetOnPutInInventoryFn(OnPutInInventory)

	inst:AddComponent("stackable")
	MakeHauntableLaunch(inst)

	return inst
end

return Prefab("aip_train_ticket_fragment", fn, assets)
