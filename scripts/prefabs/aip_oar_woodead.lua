-- 配置
local additional_weapon = aipGetModConfig("additional_weapon")
local weapon_uses = aipGetModConfig("weapon_uses")
local weapon_damage = aipGetModConfig("weapon_damage")
local language = aipGetModConfig("language")

local usageTimes = 1
if weapon_uses == "less" then
    usageTimes = 0.5
elseif weapon_uses == "much" then
    usageTimes = 2
end

local damageTimes = 1
if weapon_uses == "less" then
    damageTimes = 0.5
elseif weapon_uses == "large" then
    damageTimes = 2
end

-- 树精木浆，使用量和投入的木头数量相关
local woodead_info = {
    FORCE = 0.5,
    DAMAGE = TUNING.NIGHTSWORD_DAMAGE / 68 * 3 * damageTimes,
    DAMAGE_STEP = TUNING.NIGHTSWORD_DAMAGE / 68 * 3 * damageTimes, -- 每次递增的伤害量
    DAMAGE_MAX = TUNING.NIGHTSWORD_DAMAGE / 68 * 100 * damageTimes, -- 最大造成伤害量
    ROW_FAIL_WEAR = 6 / usageTimes,
    ATTACKWEAR = 57 / usageTimes,
    USES = 1,
}

local assets = {
    Asset("ATLAS", "images/inventoryimages/aip_oar_woodead.xml"),
    Asset("ANIM", "anim/aip_oar_woodead.zip"),
    Asset("ANIM", "anim/aip_oar_woodead_swap.zip"),
}

-- 文字描述
local LANG_MAP = {
    ["english"] = {
        ["NAME"] = "Woodead Oar",
        ["REC_DESC"] = "Good at fight",
        ["DESC"] = "Will harm more with same target",
        ["ATTACH_SPEECH"] = "A new enemy!",
    },
   ["chinese"] = {
        ["NAME"] = "树精木浆",
        ["REC_DESC"] = "更擅长战斗",
        ["DESC"] = "打人要专注，效果会更好",
        ["ATTACH_SPEECH"] = "一个新的敌人！",
    },
   ["russian"] = {
        ["NAME"] = "Весло Вудеда",
        ["REC_DESC"] = "Хорошо в бою",
        ["DESC"] = "Бъёт болнее по одной цели.",
        ["ATTACH_SPEECH"] = "О, новый враг!",
    },
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_OAR_WOODEAD = LANG.NAME
STRINGS.RECIPE_DESC.AIP_OAR_WOODEAD = LANG.REC_DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OAR_WOODEAD = LANG.DESC

-- 代码区域
local function damage_calculation(inst, attacker, target, damage, damage_step, damage_max)
    if target ~= inst._aip_target then
        inst._aip_target_times = 0
        return damage
    end

    local dmg = math.min(damage + inst._aip_target_times * damage_step, damage_max)
    return dmg
end
local function OnAttack(inst, owner, target)
    -- 重置时语音播报
    if owner.components.talker ~= nil and inst._aip_target_times == 0 then
        owner.components.talker:Say(LANG.ATTACH_SPEECH)
    end

    -- 计数器更新
    inst._aip_target = target
    inst._aip_target_times = inst._aip_target_times + 1
end

local function onequip(inst, owner, swap_build)
    owner.AnimState:OverrideSymbol("swap_object", swap_build, swap_build)
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
end

local function onfiniteusesfinished(inst)
    if inst.components.inventoryitem ~= nil and inst.components.inventoryitem.owner ~= nil then
        inst.components.inventoryitem.owner:PushEvent("toolbroke", { tool = inst })
    end

    inst:Remove()
end

local function onsave(inst, data)
    data.finiteusesTotal = inst.components.finiteuses.total
    data.finiteusesCurrent = inst.components.finiteuses:GetUses()
end

local function onload(inst, data)
    if data ~= nil then
        inst.components.finiteuses:SetMaxUses(data.finiteusesTotal)
        inst.components.finiteuses:SetUses(data.finiteusesCurrent)
    end
end

local function makeOar(data, build, swap_build, fuel_value, is_wooden)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    inst:AddTag("allow_action_on_impassable")

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank(build)
    inst.AnimState:SetBuild(build)
    inst.AnimState:PlayAnimation("idle", true)

    MakeInventoryFloatable(inst, "small", nil, 0.68)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

	if is_wooden then
		inst:AddComponent("edible")
		inst.components.edible.foodtype = FOODTYPE.WOOD
		inst.components.edible.healthvalue = 0
		inst.components.edible.hungervalue = 0
	end

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_oar_woodead.xml"

    inst:AddComponent("oar")
    inst.components.oar.force = data.FORCE
    inst:AddComponent("inspectable")

    if additional_weapon == "open" then
        inst:AddComponent("weapon")
        inst.components.weapon:SetDamage(function(inst, attacker, target)
            return damage_calculation(inst, attacker, target, data.DAMAGE, data.DAMAGE_STEP, data.DAMAGE_MAX)
        end)
        inst.components.weapon.attackwear = data.ATTACKWEAR
        inst.components.weapon:SetOnAttack(OnAttack)
        inst._aip_target = nil
        inst._aip_target_times = 0
    end


    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(function(inst, owner) onequip(inst, owner, swap_build) end)
    inst.components.equippable:SetOnUnequip(onunequip)

    MakeSmallBurnable(inst)
    MakeSmallPropagator(inst)

    if fuel_value ~= nil then
        inst:AddComponent("fuel")
        inst.components.fuel.fuelvalue = fuel_value
    end

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(data.USES)
    inst.components.finiteuses:SetUses(data.USES)
    inst.components.finiteuses:SetOnFinished(onfiniteusesfinished)
    inst.components.finiteuses:SetConsumption(ACTIONS.ROW, 1)
    inst.components.finiteuses:SetConsumption(ACTIONS.ROW_FAIL, data.ROW_FAIL_WEAR)

    MakeHauntableLaunch(inst)

    -- 载入保存
    inst.OnLoad = onload
    inst.OnSave = onsave

    return inst
end

local function aip_oar_woodead()
    return makeOar(woodead_info, "aip_oar_woodead", "aip_oar_woodead_swap", TUNING.MED_LARGE_FUEL, true)
end

return Prefab(
    "aip_oar_woodead",
    aip_oar_woodead,
    assets
)
