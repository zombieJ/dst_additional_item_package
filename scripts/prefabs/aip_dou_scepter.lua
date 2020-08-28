-- 配置
local additional_weapon = aipGetModConfig("additional_weapon")
if additional_weapon ~= "open" then
	return nil
end

local calculateProjectile = require("utils/aip_scepter_util")

local language = aipGetModConfig("language")

local BASIC_USE = TUNING.LARGE_FUEL / 10
local MAX_USES = BASIC_USE * 10 * 5

-- 文字描述
local LANG_MAP = {
	["english"] = {
        ["NAME"] = "Mystic Scepter",
        ["REC_DESC"] = "Customize your magic!",
        ["DESC"] = "Customize your magic!",
        ["EMPTY"] = "No more mana!",
	},
	["chinese"] = {
        ["NAME"] = "神秘权杖",
        ["REC_DESC"] = "自定义你的魔法！",
        ["DESC"] = "自定义你的魔法！",
        ["EMPTY"] = "权杖需要充能了",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_DOU_SCEPTER = LANG.NAME
STRINGS.RECIPE_DESC.AIP_DOU_SCEPTER = LANG.REC_DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_DOU_SCEPTER = LANG.DESC

local assets = {
    Asset("ANIM", "anim/aip_dou_scepter.zip"),
    Asset("ANIM", "anim/aip_dou_scepter_swap.zip"),
    Asset("ANIM", "anim/floating_items.zip"),
    Asset("ATLAS", "images/inventoryimages/aip_dou_scepter.xml"),
}


local prefabs = {
    "aip_dou_scepter_projectile",
}

--------------------------------- 配方 ---------------------------------
local function refreshScepter(inst)
    local projectileInfo = { queue = {} }

    if inst.components.container ~= nil then
        projectileInfo = calculateProjectile(inst.components.container:GetAllItems())
    elseif inst.replica.container ~= nil then
        projectileInfo = calculateProjectile(inst.replica.container:GetItems())
    end

    inst._projectileInfo = projectileInfo

    if inst.components.aipc_caster ~= nil then
        inst.components.aipc_caster:SetUp(
            projectileInfo.action
        )
    end

    return projectileInfo
end

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

-- 合成科技
local function onturnon(inst)
    inst.AnimState:PlayAnimation("proximity_pre")
    inst.AnimState:PushAnimation("proximity_loop", true)
end

local function onturnoff(inst)
    if not inst.components.inventoryitem:IsHeld() then
        inst.AnimState:PlayAnimation("proximity_pst")
        inst.AnimState:PushAnimation("idle", false)
    else
        inst.AnimState:PlayAnimation("idle")
    end
end

-- 装备
local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "aip_dou_scepter_swap", "aip_dou_scepter_swap")

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

-- 添加元素
local function onCasterEquip(inst)
    refreshScepter(inst)
end

local function onCasterUnequip(inst)
    refreshScepter(inst)
end

-- 使用消耗
local function beforeAction(inst, projectileInfo, doer)
    if inst.components.fueled:IsEmpty() then
        doer.components.talker:Say(LANG.EMPTY)
        return false
    end

    inst.components.fueled:DoDelta(-BASIC_USE * projectileInfo.uses)
    return true
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("aip_dou_scepter")
    inst.AnimState:SetBuild("aip_dou_scepter")
    inst.AnimState:PlayAnimation("idle")

    -- weapon (from weapon component) added to pristine state for optimization
    inst:AddTag("weapon")
    inst:AddTag("prototyper")
    inst:AddTag("throw_line")

    MakeInventoryFloatable(inst, "med", 0.1, 0.75)

    inst.entity:SetPristine()

    -- 添加施法者
    inst:AddComponent("aipc_caster")
    inst.components.aipc_caster.onEquip = onCasterEquip
    inst.components.aipc_caster.onUnequip = onCasterUnequip

    -- 鼠标类型判断，在判断的时候会刷新一下指针类型，这样利用了 POINT 就实现了动态刷新的效果。学到了就给我的 mod 点个赞吧
    inst:AddComponent("aipc_action_client")
    inst.components.aipc_action_client.canActOn = function(inst, doer, target)
        refreshScepter(inst)
        return inst._projectileInfo.action == "FOLLOW" and target.components.health ~= nil
    end
    inst.components.aipc_action_client.canActOnPoint = function()
        refreshScepter(inst)
        return inst._projectileInfo.action ~= "FOLLOW"
    end

    if not TheWorld.ismastersim then
        return inst
    end

    -- 施法
    inst:AddComponent("aipc_action")

    inst.components.aipc_action.onDoPointAction = function(inst, doer, point)
        local projectileInfo = refreshScepter(inst)

        if beforeAction(inst, projectileInfo, doer) then
            local projectile = SpawnPrefab("aip_dou_scepter_projectile")
            projectile.components.aipc_projectile:StartBy(doer, projectileInfo.queue, nil, point)
        end
    end

    inst.components.aipc_action.onDoTargetAction = function(inst, doer, target)
        local projectileInfo = refreshScepter(inst)

        if beforeAction(inst, projectileInfo, doer) then
            local projectile = SpawnPrefab("aip_dou_scepter_projectile")
            projectile.components.aipc_projectile:StartBy(doer, projectileInfo.queue, target)
        end
    end

    -- 接受元素提炼
    inst:AddComponent("container")
    inst.components.container:WidgetSetup("aip_dou_scepter4")
    inst.components.container.canbeopened = false

    inst:AddComponent("inspectable")

    -- 本身也是一个合成台
    inst:AddComponent("prototyper")
    inst.components.prototyper.onturnon = onturnon
    inst.components.prototyper.onturnoff = onturnoff
    -- inst.components.prototyper.onactivate = onactivate
    inst.components.prototyper.trees = TUNING.PROTOTYPER_TREES.AIP_DOU_SCEPTER_ONE

    -- 需要充能
    inst:AddComponent("fueled")
    inst.components.fueled.fueltype = FUELTYPE.NIGHTMARE
    inst.components.fueled:InitializeFuelLevel(MAX_USES)
    -- inst.components.fueled:SetDepletedFn(nofuel)
    -- inst.components.fueled:SetTakeFuelFn(ontakefuel)
    inst.components.fueled.accepting = true

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_dou_scepter.xml"
    inst.components.inventoryitem.imagename = "aip_dou_scepter"

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

return Prefab("aip_dou_scepter", fn, assets, prefabs)
