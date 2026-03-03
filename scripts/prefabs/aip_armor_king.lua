local language = aipGetModConfig("language")
local dev_mode = aipGetModConfig("dev_mode") == "enabled"

local ARMOR = TUNING.ARMORWOOD / 450 * 999;
local ARMO_ABSORPTION = TUNING.ARMORWOOD_ABSORPTION / .8 * .999;

local LANG_MAP = {
    english = {
        NAME = "King's New Clothes",
        DESC = "Hope not to be seen by others",
        NAME_BROKEN = "Broken Clothes",
        DESC_BROKEN = "It will come back",
    },
    chinese = {
      NAME = "国王的新衣",
      DESC = "希望不要被人看到",
      NAME_BROKEN = "破损的新衣",
      DESC_BROKEN = "它会回来的",
  }
}

local LANG = LANG_MAP[language] or LANG_MAP.english

local prefabs = {}

local assets = {
    Asset("ANIM", "anim/aip_armor_king.zip"),
    Asset("ATLAS", "images/inventoryimages/aip_armor_king.xml")
}

-- 文字描述
STRINGS.NAMES.AIP_ARMOR_KING = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_ARMOR_KING = LANG.DESC
STRINGS.NAMES.AIP_ARMOR_KING_BROKEN = LANG.NAME_BROKEN
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_ARMOR_KING_BROKEN = LANG.DESC_BROKEN

--------------------------- 方法 ---------------------------
local function onFinished(inst)
  aipReplacePrefab(inst, "aip_armor_king_broken")
end

local function onequip(inst, owner)
  inst.components.aipc_timer:NamedInterval("refreshArmor", 3, function()
    local players = aipFindNearPlayers(owner, 20)

    if #players == 1 then
      inst.components.armor:SetAbsorption(ARMO_ABSORPTION)
    else
      inst.components.armor:SetAbsorption(0)
    end
  end)
end

local function onunequip(inst, owner)
  inst.components.aipc_timer:KillName("refreshArmor")
end

--------------------------- 实例 ---------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("aip_armor_king")
    inst.AnimState:SetBuild("aip_armor_king")
    inst.AnimState:PlayAnimation("anim")

    MakeInventoryFloatable(inst, "small", 0.2, 0.8)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
      return inst
    end

    inst:AddComponent("aipc_timer")

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_armor_king.xml"
    inst.components.inventoryitem.imagename = "aip_armor_king"

    inst:AddComponent("armor")
    inst.components.armor:InitCondition(ARMOR, ARMO_ABSORPTION)
    inst.components.armor:SetOnFinished(onFinished)

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.BODY

    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    return inst
end

local function brokenFn()
  local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("aip_armor_king")
    inst.AnimState:SetBuild("aip_armor_king")
    inst.AnimState:PlayAnimation("anim")

    inst:AddTag("show_spoilage")

    MakeInventoryFloatable(inst, "small", 0.2, 0.8)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
      return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_armor_king.xml"
    inst.components.inventoryitem.imagename = "aip_armor_king"

    -- 腐烂
    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(dev_mode and 10 or (TUNING.TOTAL_DAY_TIME * 1.5))
    inst.components.perishable:StartPerishing()
    inst.components.perishable.onperishreplacement = "aip_armor_king"

    return inst
end

return Prefab("aip_armor_king", fn, assets, prefabs),
Prefab("aip_armor_king_broken", brokenFn, assets, prefabs)
