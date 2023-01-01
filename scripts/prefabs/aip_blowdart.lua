-- 配置
local additional_weapon = aipGetModConfig("additional_weapon")
if additional_weapon ~= "open" then
	return nil
end

local weapon_uses = aipGetModConfig("weapon_uses")
local weapon_damage = aipGetModConfig("weapon_damage")
local language = aipGetModConfig("language")

-- 默认参数
local PERISH_MAP = {
	less = 0.5,
	normal = 1,
	much = 2,
}
local DAMAGE_MAP = {
	less = 0.5,
	normal = 1,
	large = 2,
}

TUNING.AIP_BLOWDART_USES = PERISH_MAP[weapon_uses] * 30
TUNING.AIP_BLOWDART_DAMAGE = DAMAGE_MAP[weapon_damage] * 20

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Stinger Blowdart",
		DESC = "Sustainable development",
        REC_DESC = "Blow darts using stinger as ammunition",
	},
	chinese = {
		NAME = "蜂刺吹箭",
		DESC = "可持续发展",
        REC_DESC = "使用蜂刺作为弹药的吹箭",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_BLOWDART = LANG.NAME
STRINGS.RECIPE_DESC.AIP_BLOWDART = LANG.REC_DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_BLOWDART = LANG.DESC



--------------------------------- 弹药 ---------------------------------
local stingerAssets = {
    Asset("ANIM", "anim/aip_blowdart_stinger.zip"),
}

local function stingerFn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    RemovePhysicsColliders(inst)

    inst.AnimState:SetBank("aip_blowdart_stinger")
    inst.AnimState:SetBuild("aip_blowdart_stinger")
    inst.AnimState:PlayAnimation("idle")

    --projectile (from projectile component) added to pristine state for optimization
    inst:AddTag("projectile")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

	inst.persists = false

    inst:AddComponent("projectile")
    inst.components.projectile:SetSpeed(50)
    inst.components.projectile:SetOnHitFn(inst.Remove)
    inst.components.projectile:SetOnMissFn(inst.Remove)
    inst.components.projectile:SetOnHitFn(inst.Remove)

    return inst
end

--------------------------------- 武器 ---------------------------------
local assets = {
    Asset("ANIM", "anim/blow_dart.zip"),
    Asset("ANIM", "anim/swap_blowdart.zip"),
    Asset("ANIM", "anim/swap_blowdart_pipe.zip"),
    Asset("ATLAS", "images/inventoryimages/aip_blowdart.xml"),
}

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_blowdart_pipe", "swap_blowdart_pipe")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")

    if inst.components.container ~= nil then
        inst.components.container:Open(owner)
    end
end

local function onunequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_object")
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")

    if inst.components.container ~= nil then
        inst.components.container:Close()
    end
end

local function syncAmmo(inst)
    local hasAmmo = false

    if inst.components.container ~= nil then
        local ammo = inst.components.container:GetItemInSlot(1)
        hasAmmo = ammo ~= nil
    end

    if hasAmmo then
        inst.components.weapon:SetDamage(TUNING.AIP_BLOWDART_DAMAGE)
        inst.components.weapon:SetProjectile("aip_blowdart_stinger")
    else
        inst.components.weapon:SetDamage(0)
        inst.components.weapon:SetProjectile(nil)
    end
end

local function onAttack(inst)
    if inst.components.container ~= nil then
        local ammo = inst.components.container:GetItemInSlot(1)
        aipRemove(ammo)

        syncAmmo(inst)
    end
end

local function pipe()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("blow_dart")
    inst.AnimState:SetBuild("blow_dart")
    inst.AnimState:PlayAnimation("idle_pipe")

    inst:AddTag("blowdart")
    inst:AddTag("sharp")

    --weapon (from weapon component) added to pristine state for optimization
    inst:AddTag("weapon")

    --projectile (from projectile component) added to pristine state for optimization
    inst:AddTag("projectile")

    MakeInventoryFloatable(inst, "small", 0.05, {0.75, 0.5, 0.75})

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("weapon")
    inst.components.weapon:SetRange(8, 10)
    inst.components.weapon:SetDamage(0)
    inst.components.weapon:SetProjectileOffset(1)
    inst.components.weapon:SetOnAttack(onAttack)

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_blowdart.xml"

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(TUNING.AIP_BLOWDART_USES)
    inst.components.finiteuses:SetUses(TUNING.AIP_BLOWDART_USES)
    inst.components.finiteuses:SetOnFinished(inst.Remove)

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    inst.components.equippable.equipstack = true

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("aip_blowdart")
	inst.components.container.canbeopened = false
    inst:ListenForEvent("itemget", syncAmmo)
    inst:ListenForEvent("itemlose", syncAmmo)

    local swap_data = {sym_build = "swap_blowdart_pipe", bank = "blow_dart", anim = "idle_pipe"}
    inst.components.floater:SetBankSwapOnFloat(true, -4, swap_data)

    MakeHauntableLaunch(inst)

    inst:DoTaskInTime(0.1, syncAmmo)

    return inst
end

-------------------------------------------------------------------------------

return  Prefab("aip_blowdart", pipe, assets),
        Prefab("aip_blowdart_stinger", stingerFn, stingerAssets)
