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
local questConfig = require("configurations/aip_pig_village_quest")

STRINGS.NAMES.AIP_TRAIN_TICKET_FRAGMENT = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_TRAIN_TICKET_FRAGMENT = LANG.DESC

local assets = {
	Asset("ANIM", "anim/aip_train_ticket_fragment.zip"),
	Asset("ATLAS", "images/inventoryimages/aip_train_ticket_fragment.xml"),
}

-- 合并玩家物品栏内所有满足三张一组的体验券碎片。
local function DoMergeFragments(owner)
	if owner == nil or not owner:IsValid() or owner.components.inventory == nil then
		return
	end

	local _, fragmentCount = owner.components.inventory:Has("aip_train_ticket_fragment", 1)
	local ticketCount = math.floor(fragmentCount / questConfig.TICKET_FRAGMENT_COUNT)
	if ticketCount <= 0 then
		return
	end

	owner.components.inventory:ConsumeByName(
		"aip_train_ticket_fragment",
		ticketCount * questConfig.TICKET_FRAGMENT_COUNT
	)
	for _ = 1, ticketCount do
		local ticket = aipSpawnPrefab(owner, "aip_train_ticket")
		if ticket ~= nil then
			owner.components.inventory:GiveItem(ticket, nil, owner:GetPosition())
		end
	end

	if owner.components.talker ~= nil then
		owner.components.talker:Say(questConfig.LANG.TICKET_MERGED)
	end
end

-- 安排玩家级合并检查，避免多个碎片回调在同一帧重复消费。
function aipMergeTrainTicketFragments(owner)
	if owner == nil or not owner:HasTag("player") or owner._aipTrainTicketMergeTask ~= nil then
		return
	end

	owner._aipTrainTicketMergeTask = owner:DoTaskInTime(0, function(player)
		player._aipTrainTicketMergeTask = nil
		DoMergeFragments(player)
	end)
end

-- 物品进入玩家物品栏后检查是否能够合并。
local function OnPutInInventory(inst, owner)
	aipMergeTrainTicketFragments(owner)
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
