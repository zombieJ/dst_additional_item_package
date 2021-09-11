local dev_mode = aipGetModConfig("dev_mode") == "enabled"

local characterData = require("prefabs/aip_xiyou_card_data")
local charactersList = characterData.charactersList

local weapon_damage = aipGetModConfig("weapon_damage")
local language = aipGetModConfig("language")

-- 默认参数
local DIGEST_SPEED = {
	["less"] = TUNING.SEG_TIME * 15,
	["normal"] = TUNING.SEG_TIME * 5,
	["large"] = TUNING.SEG_TIME * 1,
}
local fuelValue = DIGEST_SPEED[weapon_damage] * (dev_mode and 0.02 or 1)

-- 资源
local assets = {
	Asset("ATLAS", "images/inventoryimages/aip_xiyou_cards.xml"),
	Asset("ATLAS", "images/inventoryimages/aip_xiyou_cards_charge.xml"),
	Asset("ANIM", "anim/aip_xiyou_card.zip"),
}

local prefabs = {
	"aip_projectile",
	"aip_shadow_wrapper",
}

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Myth Cards",
		DESC = "Exquisite card",
		SPEACH = "Shadow go away!",
	},
	chinese = {
		NAME = "神话书说卡组",
		DESC = "装订成册的精致卡组",
		DESC_MYTH = "这样就把我们都集齐啦",
		SPEACH = "邪魅退散!",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_XIYOU_CARDS = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_XIYOU_CARDS = LANG.DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_XIYOU_CARDS_MYTH = LANG.DESC_MYTH
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_XIYOU_CARDS_SPEACH = LANG.SPEACH

----------------------------------- 方法 -----------------------------------
-- 更新充能状态
local function refreshStatus(inst)
	-- 更新贴图
	if inst.components.rechargeable:IsCharged() then
		inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_xiyou_cards_charge.xml"
		inst.components.inventoryitem:ChangeImageName("aip_xiyou_cards_charge")
		inst.AnimState:PlayAnimation("book_charge", true)
	else
		inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_xiyou_cards.xml"
		inst.components.inventoryitem:ChangeImageName("aip_xiyou_cards")
		inst.AnimState:PlayAnimation("book", false)
	end
end

local function onDischarged(inst)
	inst:RemoveTag("aip_readable")
	refreshStatus(inst)
end

local function onCharged(inst)
	inst:AddTag("aip_readable")
	refreshStatus(inst)
end

-- 获取描述
local function getDesc(inst, viewer)
	if aipInTable(charactersList, viewer.prefab) then
		return STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_XIYOU_CARDS_MYTH
	end

	return nil
end

-- 是否可以阅读
local function canBeRead(inst, doer)
	return inst:HasTag("aip_readable")
end

-- 吸收附近的暗影怪 444 点生命值，如果有多个则平均分摊
local function onDoRead(inst, doer)
	if not inst.components.rechargeable:IsCharged() then
		return
	end

	local x, y, z = inst.Transform:GetWorldPosition()
	local ents = TheSim:FindEntities(x, y, z, 15, { "_combat", "_health" })

	local shadowCreatures = _G.aipFilterTable(ents, function(inst)
		return aipIsShadowCreature(inst)
	end)

	-- 说一句酷炫的话
	if doer.components.talker ~= nil then
		doer.components.talker:Say(STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_XIYOU_CARDS_SPEACH)
	end

	-- 对生物造成伤害
	if #shadowCreatures > 0 then
		inst.components.rechargeable:Discharge(fuelValue)

		local avgDmg = 444 / #shadowCreatures
		for i, creature in ipairs(shadowCreatures) do
			creature.components.combat:GetAttacked(doer, avgDmg)

			-- 爆炸效果
			aipSpawnPrefab(creature, "aip_shadow_wrapper").DoShow()
		end
	end
end

local function onDepleted(inst)
	refreshStatus(inst)
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
	inst.AnimState:PlayAnimation("book")

	inst:AddTag("aip_readable")

	inst.entity:SetPristine()

	inst:AddComponent("aipc_action_client")
	inst.components.aipc_action_client.canBeRead = canBeRead

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("fuel")
	inst.components.fuel.fuelvalue = TUNING.SMALL_FUEL

	inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetLoot({})

	inst:AddComponent("rechargeable")
	inst.components.rechargeable:SetOnDischargedFn(onDischarged)
	inst.components.rechargeable:SetOnChargedFn(onCharged)

	inst:AddComponent("aipc_action")
	inst.components.aipc_action.onDoAction = onDoRead

	inst:AddComponent("inspectable")
	inst.components.inspectable.getspecialdescription = getDesc

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_xiyou_cards.xml"
	inst.components.inventoryitem.imagename = "aip_xiyou_cards"

	MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
	MakeSmallPropagator(inst)

	inst:DoTaskInTime(0.1, refreshStatus)
	-- inst.components.rechargeable:Discharge(0.1)

	return inst
end

return Prefab("aip_xiyou_cards", fn, assets, prefabs)