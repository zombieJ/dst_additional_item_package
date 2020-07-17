local survival_effect = aipGetModConfig("survival_effect")
local language = aipGetModConfig("language")

local gamblerChance = .6
if survival_effect == "less" then
  gamblerChance = .4
elseif survival_effect == "large" then
  gamblerChance = .9
end

local ARMOR = TUNING.ARMORWOOD / 450 * 400;
local ARMO_ABSORPTION = TUNING.ARMORWOOD_ABSORPTION / .8 * .7;

local LANG_MAP = {
	["english"] = {
		["NAME"] = "Gambler Armor",
		["REC_DESC"] = "There exist 60% chance to survive",
		["DESC"] = "Death and immortality are a matter of probability",
	},
	["chinese"] = {
		["NAME"] = "赌徒护甲",
		["REC_DESC"] = "有 60% 概率免疫致死伤害",
		["DESC"] = "是我心理作祟还是它真的金刚不坏？",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

local prefabs = {
  "shadow_shield2"
}

local assets =
{
  -- Asset("ANIM", "anim/aip_armor_gambler.zip"),
  Asset("ANIM", "anim/armor_wood.zip"),
  Asset("ATLAS", "images/inventoryimages/aip_fish_sword.xml"),
}

-- 文字描述
STRINGS.NAMES.AIP_ARMOR_GAMBLER = LANG.NAME
STRINGS.RECIPE_DESC.AIP_ARMOR_GAMBLER = LANG.REC_DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_ARMOR_GAMBLER = LANG.DESC

-- 配方
local aip_armor_gambler = Recipe("aip_armor_gambler", {
    Ingredient("papyrus", 3),
    Ingredient("nightmarefuel", 1),
    Ingredient("rope", 1)
  },
  RECIPETABS.WAR,
  TECH.SCIENCE_TWO
)

-----------------------------------------------------------

local function OnBlocked(owner)
  owner.SoundEmitter:PlaySound("dontstarve/wilson/hit_armour")
end

local function onequip(inst, owner)
  -- owner.AnimState:OverrideSymbol("swap_body", "aip_armor_gambler", "swap_body")
  owner.AnimState:OverrideSymbol("swap_body", "armor_wood", "swap_body")
  inst:ListenForEvent("blocked", OnBlocked, owner)

  -- 注入生命变更
  inst._originHealthDoDelta = nil
  if owner.components.health ~= nil then
    local originHealthDoDelta = owner.components.health.DoDelta
    inst._originHealthDoDelta = originHealthDoDelta

    owner.components.health.DoDelta = function(self, delta, ...)
      local newDelta = delta
      local hp = owner.components.health.currenthealth
      if hp + newDelta <= 0 and math.random() <= gamblerChance then
        newDelta = 1 - hp
        owner.SoundEmitter:PlaySound("dontstarve/common/staff_blink")

        local fx = SpawnPrefab("shadow_shield2")
        fx.entity:SetParent(owner.entity)
      end

      return originHealthDoDelta(self, newDelta, unpack(arg))
    end
  end
end

local function onunequip(inst, owner)
  owner.AnimState:ClearOverrideSymbol("swap_body")
  inst:RemoveEventCallback("blocked", OnBlocked, owner)

  -- 恢复原本的生命变更
  if inst._originHealthDoDelta then
    owner.components.health.DoDelta = inst._originHealthDoDelta
  end
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
    inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_fish_sword.xml"
    inst.components.inventoryitem.imagename = "aip_fish_sword"

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

return Prefab("aip_armor_gambler", fn, assets, prefabs)
