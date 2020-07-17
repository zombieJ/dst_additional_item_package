local ARMOR = TUNING.ARMORWOOD / 450 * 400;
local ARMO_ABSORPTION = TUNING.ARMORWOOD_ABSORPTION / .8 * .7;

local assets =
{
  -- Asset("ANIM", "anim/aip_armor_gambler.zip"),
  Asset("ANIM", "anim/armor_wood.zip"),
}

local function OnBlocked(owner)
  owner.SoundEmitter:PlaySound("dontstarve/wilson/hit_armour")
end

local function onAttacked(owner, data)
  inst.components.armor:SetAbsorption(TUNING.FULL_ABSORPTION)
  inst._task = inst:DoTaskInTime(0.1, function()
    inst.components.armor:SetAbsorption(ARMO_ABSORPTION)
  end)
end

local function onequip(inst, owner)
  -- owner.AnimState:OverrideSymbol("swap_body", "aip_armor_gambler", "swap_body")
  owner.AnimState:OverrideSymbol("swap_body", "armor_wood", "swap_body")
  inst:ListenForEvent("blocked", OnBlocked, owner)
  inst:ListenForEvent("attacked", onAttacked, owner)
end

local function onunequip(inst, owner)
  owner.AnimState:ClearOverrideSymbol("swap_body")
  inst:RemoveEventCallback("blocked", OnBlocked, owner)
  inst:RemoveEventCallback("attacked", onAttacked, owner)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    -- inst.AnimState:SetBank("aip_armor_gambler")
    -- inst.AnimState:SetBuild("aip_armor_gambler")
    inst.AnimState:SetBank("armor_wood")
    inst.AnimState:SetBuild("armor_wood")
    inst.AnimState:PlayAnimation("anim")

    inst:AddTag("grass")

    -- 福利声音，移动的时候会循环触发
    inst.foleysound = "dontstarve/movement/foley/grassarmour"

    MakeInventoryFloatable(inst, "small", 0.2, 0.80)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.LARGE_FUEL

    MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
    MakeSmallPropagator(inst)

    inst:AddComponent("armor")
    inst.components.armor:InitCondition(ARMOR, ARMO_ABSORPTION)
    inst.components.armor:AddWeakness("beaver", TUNING.BEAVER_WOOD_DAMAGE)

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.BODY

    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("aip_armor_grambler", fn, assets)
