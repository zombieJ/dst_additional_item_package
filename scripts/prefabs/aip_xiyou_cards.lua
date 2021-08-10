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
local fuelValue = DIGEST_SPEED[weapon_damage] * (dev_mode and 0.1 or 1)

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
		FULL = "It's full!",
	},
	chinese = {
		NAME = "神话书说卡组",
		DESC = "装订成册的精致卡组",
		DESC_MYTH = "这样就把我们都集齐啦",
		SPEACH = "邪魅退散!",
		FULL = "它还没消化完",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_XIYOU_CARDS = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_XIYOU_CARDS = LANG.DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_XIYOU_CARDS_MYTH = LANG.DESC_MYTH
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_XIYOU_CARDS_SPEACH = LANG.SPEACH
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_XIYOU_CARDS_FULL = LANG.FULL

----------------------------------- 方法 -----------------------------------
-- 更新充能状态
local function refreshStatus(inst)
	-- 更新贴图
	if inst.components.fueled:IsEmpty() then
		inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_xiyou_cards.xml"
		inst.components.inventoryitem:ChangeImageName("aip_xiyou_cards")
		inst.AnimState:PlayAnimation("book", false)
	else
		inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_xiyou_cards_charge.xml"
		inst.components.inventoryitem:ChangeImageName("aip_xiyou_cards_charge")
		inst.AnimState:PlayAnimation("book_charge", true)
	end
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
	return true
end

-- 吸收附近的暗影怪 444 点生命值，如果有多个则平均分摊
local function onDoRead(inst, doer)
	if not inst.components.fueled:IsEmpty() then
		-- 说一句酷炫的话
		if doer.components.talker ~= nil then
			doer.components.talker:Say(STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_XIYOU_CARDS_FULL)
		end

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
		local avgDmg = 444 / #shadowCreatures
		for i, creature in ipairs(shadowCreatures) do
			creature.components.combat:GetAttacked(doer, avgDmg)

			-- 特效
			local proj = aipSpawnPrefab(creature, "aip_projectile")
			proj.components.aipc_projectile.speed = 15
			proj.components.aipc_info_client:SetByteArray( -- 调整颜色
				"aip_projectile_color", { 0, 0, 0, 5 }
			)
			proj.components.aipc_projectile:GoToTarget(doer, function()
				-- 充满
				inst.components.fueled:DoDelta(fuelValue / #shadowCreatures)
				inst.components.fueled:StartConsuming()
				refreshStatus(inst)
			end)

			-- 爆炸效果
			aipSpawnPrefab(creature, "aip_shadow_wrapper").DoShow()
		end
	end
end

local function onDepleted(inst)
	-- inst.components.lootdropper:SpawnLootPrefab("nightmarefuel")
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

	inst.entity:SetPristine()

	inst:AddComponent("aipc_action_client")
	inst.components.aipc_action_client.canBeRead = canBeRead

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetLoot({})

	inst:AddComponent("fueled")
	inst.components.fueled.fueltype = FUELTYPE.MAGIC
	inst.components.fueled.maxfuel = fuelValue
	inst.components.fueled.depleted = onDepleted
	inst.components.fueled:InitializeFuelLevel(0)

	inst:AddComponent("aipc_action")
	inst.components.aipc_action.onDoAction = onDoRead

	inst:AddComponent("inspectable")
	inst.components.inspectable.getspecialdescription = getDesc

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_xiyou_cards.xml"
	inst.components.inventoryitem.imagename = "aip_xiyou_cards"

	MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
	MakeSmallPropagator(inst)

	return inst
end

return Prefab("aip_xiyou_cards", fn, assets, prefabs)