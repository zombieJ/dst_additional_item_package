-- 配置
local additional_weapon = aipGetModConfig("additional_weapon")
if additional_weapon ~= "open" then
	return nil
end

local BASIC_USE = TUNING.LARGE_FUEL / 20
local ATTACK_USE = BASIC_USE / 5
local MAX_USES = BASIC_USE * 20

local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
        NAME = "XinYue Hoe",
        REC_DESC = "Nothing faster than this",
        DESC = "Time is money",
	},
	chinese = {
        NAME = "心悦锄",
        REC_DESC = "快速打理你的花园",
        DESC = "时间就是金钱",
	},
	russian = {
        NAME = "Мотыга СинЮэ",
        REC_DESC = "Нет ничего быстрее, чем это",
        DESC = "Время - деньги",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_XINYUE_HOE = LANG.NAME
STRINGS.RECIPE_DESC.AIP_XINYUE_HOE = LANG.REC_DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_XINYUE_HOE = LANG.DESC

local assets = {
    Asset("ANIM", "anim/aip_xinyue_hoe.zip"),
    Asset("ANIM", "anim/aip_xinyue_hoe_swap.zip"),
    Asset("ANIM", "anim/floating_items.zip"),
    Asset("ATLAS", "images/inventoryimages/aip_xinyue_hoe.xml"),
}


local prefabs = {
}

-- --------------------------------- 功能 ---------------------------------
-- 装备
local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "aip_xinyue_hoe_swap", "aip_xinyue_hoe_swap")

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

local digDiff = 1.3

local function onDoPointAction(inst, doer, point)
    if inst.components.fueled:IsEmpty() then
        return
    end

    local tile_x, tile_y, tile_z = TheWorld.Map:GetTileCenterPoint(point.x, 0, point.z)

    -- 一次性挖 3x3 个地
    local index = 1
    for z = -1, 1 do
        for x = 1, -1, -1 do
            local tx = tile_x + x * digDiff
            local tz = tile_z + z * digDiff

            if TheWorld.Map:CanTillSoilAtPoint(tx, 0, tz, false) then
                TheWorld.Map:CollapseSoilAtPoint(tx, 0, tz)
                local soil = SpawnPrefab("farm_soil")
                soil.Transform:SetPosition(tx, 0, tz)

                -- 给予植物
                local item =inst.components.container:GetItemInSlot(index)
                if item ~= nil and item.components.farmplantable ~= nil then
                    local left = item
                    if item.components.stackable ~= nil then
                        left = item.components.stackable:Get(1)
                    end

                    left.components.farmplantable:Plant(soil, doer)
                end
            end

            index = index + 1
        end
    end

    -- 范围内植物全部快乐一次
    for _, v in pairs(TheSim:FindEntities(tile_x, tile_y, tile_z, math.sqrt(digDiff * digDiff * 2) * 1.1, {"tendable_farmplant"})) do
        if v.components.farmplanttendable ~= nil then
            v.components.farmplanttendable:TendTo(doer)
        end
    end

    -- 惩罚施法者对应的理智值
    if doer.components.sanity ~= nil then
        doer.components.sanity:DoDelta(-20)
    end

    inst.components.fueled:DoDelta(-BASIC_USE)
end

-- 平分种子
local function onAvgItems(inst)
    local numslots = inst.components.container:GetNumSlots()

    -- 遍历 slot 看看哪个是空的
    for slot = 1, numslots do
        local item = inst.components.container:GetItemInSlot(slot)

        -- 把有的填充到这里来
        if item == nil then
            for i = 1, numslots do
                local other = inst.components.container:GetItemInSlot(i)
                if
                    other ~= nil and
                    other.components.stackable ~= nil and
                    other.components.stackable:IsStack()
                then
                    local left = other.components.stackable:Get(1)
                    inst.components.container:GiveItem(left, slot)
                    break
                end
            end
        end
    end
end

-- 启动
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("aip_xinyue_hoe")
    inst.AnimState:SetBuild("aip_xinyue_hoe")
    inst.AnimState:PlayAnimation("idle")

    -- weapon (from weapon component) added to pristine state for optimization
    inst:AddTag("weapon")

	MakeInventoryFloatable(inst, "med", 0.1, 0.75)

    inst:AddTag("wateringcan")

    -- 施法
    inst:AddComponent("aipc_action_client")
    inst.components.aipc_action_client.canActOnPoint = function(inst, doer, pos)
        return TheWorld.Map:GetTileAtPoint(pos:Get()) == GROUND.FARMING_SOIL
    end
    inst.components.aipc_action_client.gridplacer = true

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    -- 接受元素提炼
    inst:AddComponent("container")
    inst.components.container:WidgetSetup("aip_xinyue_hoe")
    inst.components.container.canbeopened = false

    inst:AddComponent("inspectable")

    inst:AddComponent("fueled")
    inst.components.fueled.fueltype = "AIP_NEVER"
    inst.components.fueled:InitializeFuelLevel(MAX_USES)
    inst.components.fueled.accepting = true

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(TUNING.FARM_HOE_DAMAGE)

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_xinyue_hoe.xml"
    inst.components.inventoryitem.imagename = "aip_xinyue_hoe"

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    -- 施法
    inst:AddComponent("aipc_action")
    inst.components.aipc_action.onDoPointAction = onDoPointAction
    inst.components.aipc_action.onDoAction = onAvgItems

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("aip_xinyue_hoe", fn, assets, prefabs)

--[[

c_give"aip_xinyue_hoe" c_give("goldnugget", 5)


c_give"shovel"  c_give"aip_xinyue_hoe"  c_give"farm_plow_item"
c_give"carrot_seeds"  c_give"corn_seeds"  c_give"eggplant_seeds"  c_give"durian_seeds"  c_give"dragonfruit_seeds"  c_give"watermelon_seeds"
c_give"tomato_seeds"  c_give"potato_seeds"  c_give"onion_seeds"

]]
