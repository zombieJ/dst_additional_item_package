local dev_mode = aipGetModConfig("dev_mode") == "enabled"

-- 配置
local additional_weapon = aipGetModConfig("additional_weapon")
if additional_weapon ~= "open" then
	return nil
end

local weapon_uses = aipGetModConfig("weapon_uses")
local weapon_damage = aipGetModConfig("weapon_damage")
local language = aipGetModConfig("language")

-- 默认参数
local USES_MAP = {
	less = 200,
	normal = dev_mode and 10 or 400,
	much = 1000,
}

local DAMAGE_MAP = {
	less = TUNING.NIGHTSWORD_DAMAGE / 68 * 22,
	normal = TUNING.NIGHTSWORD_DAMAGE / 68 * 33,
	large = TUNING.NIGHTSWORD_DAMAGE / 68 * 44,
}

local DAMAGE_FRIEND_MAP = {
	less = 22,
	normal = 33,
	large = 44,
}

local LANG_MAP = {
	english = {
		NAME = "Divine Rapier",
		DESC = "The combination of light and dark",
		REC_DESC = "Fusing the power of both, it is powerful with slaughter and full of power because of companions",
	},
	chinese = {
		NAME = "圣剑",
		DESC = "光与暗的结合",
		REC_DESC = "融合两者的力量，即随着杀戮而强大，又因为同伴而充满力量。圣剑会继承杀生数和耐久度。",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

TUNING.AIP_DIVINE_RAPIER_USES = USES_MAP[weapon_uses]
TUNING.AIP_DIVINE_RAPIER_DAMAGE = DAMAGE_MAP[weapon_damage]
TUNING.AIP_DIVINE_RAPIER_DAMAGE_FIREND = DAMAGE_FRIEND_MAP[weapon_damage]

-- 资源
local assets = {
	Asset("ATLAS", "images/inventoryimages/aip_divine_rapier.xml"),
	Asset("ANIM", "anim/aip_divine_rapier.zip"),
	Asset("ANIM", "anim/aip_divine_rapier_swap.zip"),
}

local prefabs = {}

-- 文字描述
STRINGS.NAMES.AIP_DIVINE_RAPIER = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_DIVINE_RAPIER = LANG.DESC
STRINGS.RECIPE_DESC.AIP_DIVINE_RAPIER = LANG.REC_DESC

-------------------------- 方法 --------------------------
local function calcDamage(inst, attacker, target)
	local DAMAGE = TUNING.AIP_DIVINE_RAPIER_DAMAGE

	-- 杀生伤害累加，最多 200% 基础伤害
	local killDmg = math.min(DAMAGE * 2, inst._aipKillerCount or 0)

	-- 友伤伤害累加，最多 4 倍叠加伤害
	local nearPlayerCount = math.max(0, #aipFindNearPlayers(attacker, 20) - 1)
	if
		attacker ~= nil and
		attacker.components.aipc_pet_owner ~= nil and
		attacker.components.aipc_pet_owner.showPet ~= nil
	then
		nearPlayerCount = nearPlayerCount + 1
	end
	local friendDmg = math.min(nearPlayerCount, 4) * TUNING.AIP_DIVINE_RAPIER_DAMAGE_FIREND

	return DAMAGE + killDmg + friendDmg
end

local function OnKilledOther(owner)
	if owner.components.inventory ~= nil then
		local handitem = owner.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)

		if handitem ~= nil and handitem._aipKillerCount ~= nil then
			handitem._aipKillerCount = handitem._aipKillerCount + 1
		end
	end
end

-- 合成的圣剑会继承耐久度
local function OnPreBuilt(inst, builder, materials, recipe)
	local aip_oldone_hand = materials.aip_oldone_hand
	local aip_living_friendship = materials.aip_living_friendship

	local count = 0
	local totalPtg = 0

	for prefabName, ents in pairs(materials) do
		for prefab, needCount in pairs(ents) do
			local badUses = aipGet(prefab, "components|finiteuses")
			if badUses ~= nil then
				count = count + 1
				totalPtg = totalPtg + badUses:GetPercent()
			end

			-- 继承 杀生数
			if prefab._aipKillerCount ~= nil then
				inst._aipKillerCount = prefab._aipKillerCount
			end
		end
	end

	if inst.components.finiteuses ~= nil and count > 0 then
		inst.components.finiteuses:SetPercent((totalPtg) / count)
	end
end

-- 耐久度用完后，删除圣剑。创建一个
local function OnFinished(inst)
	if aipUnique() ~= nil then
		aipUnique():OldoneKillCount(inst._aipKillerCount)
	end

	aipReplacePrefab(inst, "aip_shadow_wrapper").DoShow()
end

local function onRemoveAfterimage(inst)
	if inst._aipRapiers ~= nil then -- 遍历所有的剑并删除
		for i, v in ipairs(inst._aipRapiers) do
			aipReplacePrefab(v, "aip_shadow_wrapper").DoShow()
		end
		inst._aipRapiers = nil
	end
end

local function onCreateAfterimage(inst, doer)
	if inst._aipRapiers == nil then
		local light = aipSpawnPrefab(inst, "aip_divine_rapier_fx")
		light.setupFX(doer, "light", 0, 2, inst)

		local dark = aipSpawnPrefab(inst, "aip_divine_rapier_fx")
		dark.setupFX(doer, "dark", 1, 2, inst)

		inst._aipRapiers = { light, dark }
	end
end

-- 释放圣剑
local function onSpell(inst, target, pos, doer)
	-- 如果有目标 或者 没有 剑痕 则召唤出来
	if target ~= nil or inst._aipRapiers == nil then
		onCreateAfterimage(inst, doer)
	else -- 遍历所有的剑并删除
		onRemoveAfterimage(inst)
	end

	if target ~= nil then
		for i, afterimage in ipairs(inst._aipRapiers) do
			if afterimage.components.aipc_divine_rapier ~= nil then
				afterimage.components.aipc_divine_rapier:Attack(target)
			end
		end
	end
end

-------------------------- 装备 --------------------------
local function onequip(inst, owner)
	owner.AnimState:OverrideSymbol("swap_object", "aip_divine_rapier_swap", "aip_divine_rapier_swap")
	owner.SoundEmitter:PlaySound("dontstarve/wilson/equip_item_gold")
	owner.AnimState:Show("ARM_carry")
	owner.AnimState:Hide("ARM_normal")

	owner:ListenForEvent("killed", OnKilledOther)
end

local function onunequip(inst, owner)
	owner.AnimState:ClearOverrideSymbol("swap_object")
	owner.AnimState:Hide("ARM_carry")
	owner.AnimState:Show("ARM_normal")

	owner:RemoveEventCallback("killed", OnKilledOther)

	onRemoveAfterimage(inst)
end

-------------------------- 存取 --------------------------
local function onSave(inst, data)
	data.killCount = inst._aipKillerCount
end

local function onLoad(inst, data)
	if data ~= nil then
		inst._aipKillerCount = data.killCount
	end
end

-------------------------- 实例 --------------------------
local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()
	
	MakeInventoryPhysics(inst)

	inst:AddTag("irreplaceable")
	inst:AddTag("aip_DivineRapier_bad")
	inst:AddTag("aip_DivineRapier_good")
	
	inst.AnimState:SetBank("aip_divine_rapier")
	inst.AnimState:SetBuild("aip_divine_rapier")
	inst.AnimState:PlayAnimation("idle")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(calcDamage)

	inst:AddComponent("finiteuses")
	inst.components.finiteuses:SetMaxUses(TUNING.AIP_DIVINE_RAPIER_USES)
	inst.components.finiteuses:SetUses(TUNING.AIP_DIVINE_RAPIER_USES)
	inst.components.finiteuses:SetOnFinished(OnFinished)

	inst:AddComponent("inspectable")

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_divine_rapier.xml"

	MakeHauntableLaunch(inst)

	inst:AddComponent("equippable")
	inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)

	-- 可以对目标释放技能
    inst:AddComponent("spellcaster")
    inst.components.spellcaster.canuseontargets = true
	inst.components.spellcaster.canuseonpoint = true
    inst.components.spellcaster.canonlyuseoncombat = true
    inst.components.spellcaster.quickcast = true
    inst.components.spellcaster:SetSpellFn(onSpell)

	inst._aipKillerCount = 0

	inst.onPreBuilt = OnPreBuilt

	inst.OnLoad = onLoad
	inst.OnSave = onSave

	return inst
end

--------------------------------------------------------------
--                           剑痕                           --
--------------------------------------------------------------
local function afterimageFn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	MakeProjectilePhysics(inst)

	inst:AddTag("NOCLICK")
	inst:AddTag("FX")
	
	inst.AnimState:SetBank("aip_divine_rapier")
	inst.AnimState:SetBuild("aip_divine_rapier")
	inst.AnimState:PlayAnimation("dark")

	inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
	inst.AnimState:SetLayer(LAYER_WORLD_BACKGROUND)
	inst.AnimState:SetSortOrder(1)
    inst.AnimState:SetFinalOffset(2)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("aipc_divine_rapier")

	-- 启动剑痕
	inst.setupFX = function(player, anim, index, total, weapon)
		inst.AnimState:PlayAnimation(anim)
		inst.components.aipc_divine_rapier:Setup(player, index, total, weapon)
		inst.components.aipc_divine_rapier.onUse = function()
			if weapon ~= nil and weapon.components.finiteuses ~= nil then
				weapon.components.finiteuses:Use()
			end
		end
	end

	inst.persists = false

	-- 测试用：如果没有守护目标，选第一个玩家
	if dev_mode then
		inst:DoTaskInTime(0.5, function()
			if inst.components.aipc_divine_rapier.guardTarget == nil then
				local player = aipFindNearPlayers(inst, 20)[1]
				if player ~= nil then
					inst.components.aipc_divine_rapier:Setup(player, 0, 2)
				end
			end
		end)
	end

	return inst
end

return	Prefab("aip_divine_rapier", fn, assets),
		Prefab("aip_divine_rapier_fx", afterimageFn, assets)
