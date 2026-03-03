-- 配置
local additional_weapon = aipGetModConfig("additional_weapon")
if additional_weapon ~= "open" then
	return nil
end

local language = aipGetModConfig("language")

local LANG_MAP = {
	english = {
		NAME = "Misery Lamp",
		DESC = "Seems lost power forever",
	},
	chinese = {
		NAME = "苦难之灯",
		DESC = "似乎已经失去了作用",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

-- 资源
local assets = {
	Asset("ATLAS", "images/inventoryimages/aip_cost_lamp.xml"),
	Asset("ANIM", "anim/aip_cost_lamp_swap.zip"),
}

local prefabs = {}

-- 文字描述
STRINGS.NAMES.AIP_COST_LAMP = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_COST_LAMP = LANG.DESC

------------------------------- 方法 -------------------------------

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "aip_cost_lamp_swap", "aip_cost_lamp_swap")

    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")

end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
end

------------------------------- 实例 -------------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("aip_cost_lamp_swap")
    inst.AnimState:SetBuild("aip_cost_lamp_swap")
    inst.AnimState:PlayAnimation("BUILD")

    -- inst:AddTag("light")

    MakeInventoryFloatable(inst, "med", 0.2, 0.65)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_cost_lamp.xml"

    -- inst.components.inventoryitem:SetOnDroppedFn(ondropped)
    -- inst.components.inventoryitem:SetOnPutInInventoryFn(turnoff)

    inst:AddComponent("equippable")

    -- inst:AddComponent("fueled")

    -- inst:AddComponent("machine")
    -- inst.components.machine.turnonfn = turnon
    -- inst.components.machine.turnofffn = turnoff
    -- inst.components.machine.cooldowntime = 0

    -- inst.components.fueled.fueltype = FUELTYPE.CAVE
    -- inst.components.fueled:InitializeFuelLevel(TUNING.LANTERN_LIGHTTIME)
    -- inst.components.fueled:SetDepletedFn(nofuel)
    -- inst.components.fueled:SetUpdateFn(fuelupdate)
    -- inst.components.fueled:SetTakeFuelFn(ontakefuel)
    -- inst.components.fueled:SetFirstPeriod(TUNING.TURNON_FUELED_CONSUMPTION, TUNING.TURNON_FULL_FUELED_CONSUMPTION)
    -- inst.components.fueled.accepting = true

    -- inst._light = nil

    MakeHauntableLaunch(inst)

    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    -- inst.components.equippable:SetOnEquipToModel(onequiptomodel)

    -- inst.OnRemoveEntity = OnRemove

    -- inst._onownerequip = function(owner, data)
    --     if data.item ~= inst and
    --         (   data.eslot == EQUIPSLOTS.HANDS or
    --             (data.eslot == EQUIPSLOTS.BODY and data.item:HasTag("heavy"))
    --         ) then
    --         turnoff(inst)
    --     end
    -- end

    return inst
end

return Prefab("aip_cost_lamp", fn, assets)
