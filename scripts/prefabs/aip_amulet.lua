local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Dragon Boat Egg",
		DESC = "Dragon Boat Festival!",
        REC_DESC = "An egg that can be eaten and carried",
	},
	chinese = {
		NAME = "安康蛋",
		DESC = "端午安康",
        REC_DESC = "既能够吃又能戴的蛋",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_AMULET_EGG = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_AMULET_EGG = LANG.DESC
STRINGS.RECIPE_DESC.AIP_AMULET_EGG = LANG.REC_DESC

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_amulet_egg.zip"),
    Asset("ATLAS", "images/inventoryimages/aip_amulet_egg.xml"),
}


--------------------------- 通用 ---------------------------
local function commonfn(name, tag)
    local prefabName = "aip_amulet_"..name

    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:AddSoundEmitter()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank(prefabName)
    inst.AnimState:SetBuild(prefabName)
    inst.AnimState:PlayAnimation("anim")
    inst.scrapbook_anim = "anim"

    if tag ~= nil then
        inst:AddTag(tag)
    end

    inst.foleysound = "dontstarve/movement/foley/jewlery"

    MakeInventoryFloatable(inst, "med", nil, 0.6)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.BODY
    -- inst.components.equippable.dapperness = TUNING.DAPPERNESS_SMALL
    -- inst.components.equippable.is_magic_dapperness = true

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/"..prefabName..".xml"

    return inst
end

--------------------------- 实例 ---------------------------
local function onequip_egg(inst, owner)
    owner.AnimState:OverrideSymbol("swap_body", "aip_amulet_egg", "swap_body")

    if inst.components.perishable then
        inst.components.perishable:StartPerishing()
    end
end

local function onunequip_egg(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_body")
    if inst.components.perishable then
        inst.components.perishable:StopPerishing()
    end
end

local function onequiptomodel_egg(inst, owner, from_ground)
    if inst.components.perishable then
        inst.components.perishable:StopPerishing()
    end
end

local function egg()
    local inst = commonfn("egg")

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(TUNING.PERISH_MED)
    -- inst.components.perishable:StartPerishing()
    inst.components.perishable.onperishreplacement = "rottenegg"

    inst.components.equippable:SetOnEquip(onequip_egg)
    inst.components.equippable:SetOnUnequip(onunequip_egg)
    inst.components.equippable:SetOnEquipToModel(onequiptomodel_egg)

    inst.components.equippable.dapperness = TUNING.DAPPERNESS_MED

    MakeHauntableLaunch(inst)

    return inst
end

--------------------------- 返回 ---------------------------
return Prefab("aip_amulet_egg", egg, assets)