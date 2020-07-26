-- 配置
local additional_weapon = aipGetModConfig("additional_weapon")
if additional_weapon ~= "open" then
	return nil
end

local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	["english"] = {
        ["NAME"] = "Dou Scepter",
        ["REC_DESC"] = "Customize your magic!",
		["DESC"] = "Customize your magic!",
	},
	["chinese"] = {
        ["NAME"] = "豆酱权杖",
        ["REC_DESC"] = "自定义你的魔法！",
		["DESC"] = "自定义你的魔法！",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_DOU_SCEPTER = LANG.NAME
STRINGS.RECIPE_DESC.AIP_DOU_SCEPTER = LANG.REC_DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_DOU_SCEPTER = LANG.DESC

local assets = {
    Asset("ANIM", "anim/cane.zip"), Asset("ANIM", "anim/swap_cane.zip"),
    Asset("ANIM", "anim/floating_items.zip"),
    Asset("ATLAS", "images/inventoryimages/aip_fish_sword.xml"),
}

--------------------------------- 配方 ---------------------------------

-- -- STRINGS.TABS.AIP_DOU_SCEPTER = "测试"

-- local sort_key = 25
-- local fancy_tab = AddRecipeTab("Fancy Stuff", sort_key, "images/hud/fancy.xml", "fancy.tex" )
-- local Ingredient = GLOBAL.IngredientAddRecipe("fancy_item", {Ingredient("goldnugget", 1)}, fancy_tab, GLOBAL.TECH.NONE )

-- local aip_dou_scepter = Recipe("aip_dou_scepter", {Ingredient("pondfish", 1),Ingredient("nightmarefuel", 2),Ingredient("rope", 1)}, RECIPETABS.WAR, TECH.SCIENCE_TWO)
local aip_dou_scepter = Recipe("aip_dou_scepter", {Ingredient("pondfish", 1)}, RECIPETABS.AIP_DOU_SCEPTER, TECH.AIP_DOU_SCEPTER_ONE, nil, nil, true)
aip_dou_scepter.atlas = "images/inventoryimages/aip_fish_sword.xml"

STRINGS.UI.CRAFTING.AIP_DOU_SCEPTER_ONE = "You need a <custom structure name> to make it."

local function onsave(inst, data)
	data.magicSlot = inst._magicSlot
end

local function onload(inst, data)
	if data ~= nil then
        inst._magicSlot = data.magicSlot

        if inst.components.container ~= nil then
            inst.components.container:WidgetSetup("aip_dou_scepter"..tostring(inst._magicSlot))
        end
	end
end

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_cane", "swap_cane")

    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")

    if inst.components.container ~= nil then
        inst.components.container:Open(owner)
    end
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")

    if inst.components.container ~= nil then
        inst.components.container:Close()
    end
end

local function onItemLoaded(inst, data)
	-- if inst.components.weapon ~= nil then
	-- 	if data ~= nil and data.item ~= nil then
	-- 		inst.components.weapon:SetProjectile(data.item.prefab.."_proj")
	-- 		data.item:PushEvent("ammoloaded", {slingshot = inst})
	-- 	end
	-- end
end

local function onItemUnloaded(inst, data)
	-- if inst.components.weapon ~= nil then
	-- 	inst.components.weapon:SetProjectile(nil)
	-- 	if data ~= nil and data.prev_item ~= nil then
	-- 		data.prev_item:PushEvent("ammounloaded", {slingshot = inst})
	-- 	end
	-- end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("cane")
    inst.AnimState:SetBuild("swap_cane")
    inst.AnimState:PlayAnimation("idle")

    -- weapon (from weapon component) added to pristine state for optimization
    inst:AddTag("weapon")

    local swap_data = {sym_build = "swap_cane"}
    MakeInventoryFloatable(inst, "med", 0.05, {0.85, 0.45, 0.85}, true, 1,
                           swap_data)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then return inst end

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(TUNING.CANE_DAMAGE)

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("aip_dou_scepter1")
    -- inst.components.container:WidgetSetup("slingshot")
    inst.components.container.canbeopened = false
    inst:ListenForEvent("itemget", onItemLoaded)
    inst:ListenForEvent("itemlose", onItemUnloaded)

    inst:AddComponent("inspectable")

    -- 本身也是一个合成台
    inst:AddComponent("prototyper")
    -- inst.components.prototyper.onturnon = onturnon
    -- inst.components.prototyper.onturnoff = onturnoff
    -- inst.components.prototyper.onactivate = onactivate
    inst.components.prototyper.trees = TUNING.PROTOTYPER_TREES.AIP_DOU_SCEPTER_ONE

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_fish_sword.xml"
    inst.components.inventoryitem.imagename = "aip_fish_sword"

    inst:AddComponent("equippable")

    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    inst.components.equippable.walkspeedmult = TUNING.CANE_SPEED_MULT

    MakeHauntableLaunch(inst)

    inst._magicSlot = 1

    inst.OnLoad = onload
    inst.OnSave = onsave

    return inst
end

return Prefab("aip_dou_scepter", fn, assets)
