local dev_mode = aipGetModConfig("dev_mode") == "enabled"

-- 配置
local additional_survival = aipGetModConfig("additional_survival")
if additional_survival ~= "open" then
	return nil
end

-- 语言
local language = aipGetModConfig("language")

local LANG_MAP = {
	english = {
		NAME = "Miser Pack",
		DESC = "Move faster when full but drop be attacked",
		DESCRIBE = "Not safty but valuable",
	},
	chinese = {
		NAME = "守财奴的背包",
		DESC = "越满跑的越快，但被攻击会掉落",
		DESCRIBE = "掩耳盗铃",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

-- 资源
local assets = {
	Asset("ANIM", "anim/aip_krampus_plus.zip"),
	Asset("ATLAS", "images/inventoryimages/aip_krampus_plus.xml"),
}

local prefabs = {}

-- 文字描述
STRINGS.NAMES.AIP_KRAMPUS_PLUS = LANG.NAME
STRINGS.RECIPE_DESC.AIP_KRAMPUS_PLUS = LANG.DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_KRAMPUS_PLUS = LANG.DESCRIBE

-- 配方
local aip_krampus_plus = Recipe("aip_krampus_plus", {Ingredient("klaussackkey", 1)}, RECIPETABS.SURVIVAL, TECH.SCIENCE_TWO)
aip_krampus_plus.atlas = "images/inventoryimages/aip_krampus_plus.xml"

---------------------------- 事件 ----------------------------
-- 刷新速度
local function refreshSpeed(inst)
    if inst.components.equippable ~= nil and inst.components.container ~= nil then
        local num = aipCountTable(inst.components.container:GetAllItems())
        local speed = 1 + num * (dev_mode and 0.1 or 0.02)
        inst.components.equippable.walkspeedmult = speed

        -- 开发者提示
        if dev_mode and ThePlayer ~= nil and ThePlayer.components.talker ~= nil then
            ThePlayer.components.talker:Say("速度倍速："..tostring(speed))
        end
    end
end

local function onequip(inst, owner)
	owner.AnimState:OverrideSymbol("backpack", "aip_krampus_plus", "backpack")
	owner.AnimState:OverrideSymbol("swap_body", "aip_krampus_plus", "swap_body")
    inst.components.container:Open(owner)

    refreshSpeed(inst)

    inst:ListenForEvent("attacked", inst._onAttacked, owner)
end

local function onunequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_body")
    owner.AnimState:ClearOverrideSymbol("backpack")
    inst.components.container:Close(owner)

    inst:RemoveEventCallback("attacked", inst._onAttacked, owner)
end

---------------------------- 实体 ----------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.MiniMapEntity:SetIcon("backpack.png")

    inst.AnimState:SetBank("aip_krampus_plus")
    inst.AnimState:SetBuild("aip_krampus_plus")
    inst.AnimState:PlayAnimation("anim")

    inst.foleysound = "dontstarve/movement/foley/krampuspack"

    inst:AddTag("backpack")

    --waterproofer (from waterproofer component) added to pristine state for optimization
    inst:AddTag("waterproofer")

    MakeInventoryFloatable(inst, "med", 0.1, 0.65)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.cangoincontainer = false
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_krampus_plus.xml"
    inst.components.inventoryitem.imagename = "aip_krampus_plus"

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.BODY
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    inst.components.equippable.walkspeedmult = 1

    inst:AddComponent("waterproofer")
    inst.components.waterproofer:SetEffectiveness(0)

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("aip_krampus_plus")
    inst.components.container.skipclosesnd = true
    inst.components.container.skipopensnd = true

    inst:ListenForEvent("dropitem", refreshSpeed)
    inst:ListenForEvent("gotnewitem", refreshSpeed)
    inst:ListenForEvent("itemget", refreshSpeed)
    inst:ListenForEvent("itemlose", refreshSpeed)

    -- 被攻击，随机掉落一样东西
    inst._onAttacked = function(owner)
        if inst.components.container ~= nil then
            local items = inst.components.container:GetAllItems()
            local item = aipRandomEnt(items)

            inst.components.container:DropItem(item)
        end
    end

    MakeHauntableLaunchAndDropFirstItem(inst)

    return inst
end

return Prefab("aip_krampus_plus", fn, assets)
