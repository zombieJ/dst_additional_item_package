local survival_effect = aipGetModConfig("survival_effect")
local language = aipGetModConfig("language")

local ARMOR = TUNING.ARMORWOOD / 450 * 666;
local ARMO_ABSORPTION = TUNING.ARMORWOOD_ABSORPTION / .8 * .7;

local LANG_MAP = {
	english = {
		NAME = "Angry Fire Armor",
		REC_DESC = "Immune to burning damage, and can deal a powerful blow every period of time.",
		DESC = "Strength and skill coexist",
    BUFF_NAME = "balrog",
	},
	chinese = {
		NAME = "佛怒莲甲",
		REC_DESC = "免疫燃烧伤害，每隔一段时间使你获得火莲标记能打出强力一击。",
		DESC = "力量与技巧并存",
    BUFF_NAME = "火莲",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

local prefabs = {}

local assets = {
  Asset("ANIM", "anim/aip_armor_balrog.zip"),
  Asset("ATLAS", "images/inventoryimages/aip_armor_balrog.xml"),
}

-- 文字描述
STRINGS.NAMES.AIP_ARMOR_BALROG = LANG.NAME
STRINGS.RECIPE_DESC.AIP_ARMOR_BALROG = LANG.REC_DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_ARMOR_BALROG = LANG.DESC

--------------------------- 状态 ---------------------------
-- 青尘 BUFF: 没用到
aipBufferRegister("aip_balrog", {
	name = LANG.BUFF_NAME,
	showFX = true,
})

--------------------------- 方法 ---------------------------
local function onequip(inst, owner)
  owner.AnimState:OverrideSymbol("swap_body", "aip_armor_balrog", "swap_body")

  if owner.components.health ~= nil then
    owner.components.health.externalfiredamagemultipliers:SetModifier(inst, 1 - TUNING.ARMORDRAGONFLY_FIRE_RESIST)
  end

  inst.components.aipc_timer:NamedInterval("patchBalrog", 5, function()
    aipBufferPatch(inst, owner, "aip_balrog", 9999999)
  end)
end

local function onunequip(inst, owner)
  owner.AnimState:ClearOverrideSymbol("swap_body")

  if owner.components.health ~= nil then
    owner.components.health.externalfiredamagemultipliers:RemoveModifier(inst)
  end

  inst.components.aipc_timer:KillName("patchBalrog")
  aipBufferRemove(owner, "aip_balrog")
end

--------------------------- 实例 ---------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("aip_armor_balrog")
    inst.AnimState:SetBuild("aip_armor_balrog")
    inst.AnimState:PlayAnimation("anim")

    MakeInventoryFloatable(inst, "small", 0.2, 0.80)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("aipc_timer")

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_armor_balrog.xml"
    inst.components.inventoryitem.imagename = "aip_armor_balrog"

    inst:AddComponent("armor")
    inst.components.armor:InitCondition(ARMOR, ARMO_ABSORPTION)

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.BODY

    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("aip_armor_balrog", fn, assets, prefabs)
