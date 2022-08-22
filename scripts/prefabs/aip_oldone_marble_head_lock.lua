local dev_mode = aipGetModConfig("dev_mode") == "enabled"
local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
        NAME = "Bundled Head",
        DESC = "Do not free it",
	},
	chinese = {
        NAME = "捆绑的头颅",
        DESC = "千万别把它放出来",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_OLDONE_MARBLE_HEAD_LOCK = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_MARBLE_HEAD_LOCK = LANG.DESC

local PHYSICS_RADIUS = .45
local PHYSICS_HEIGHT = 1
local PHYSICS_MASS = 10
local HEAD_WALK_SPEED = 1

local assets = {
    Asset("ANIM", "anim/aip_oldone_marble_head_lock.zip"),
    Asset("ATLAS", "images/inventoryimages/aip_oldone_marble_head_lock.xml"),
}

--------------------------------- 战斗 ---------------------------------
local function onequip(inst, owner)
	owner.AnimState:OverrideSymbol("swap_body", "aip_oldone_marble_head_lock", "swap_body")
end

local function onunequip(inst, owner)
	owner.AnimState:ClearOverrideSymbol("swap_body")
end

--------------------------------- 收集 ---------------------------------
local function triggerCollect(inst, hasWatcher)
    local quickInterval = 5
    local longTimes = hasWatcher and 1 or 30 -- 一次性检查多少次
    local finalDuration = quickInterval * longTimes

    if dev_mode then
        finalDuration = 2
    end

    inst.components.aipc_timer:NamedInterval("Collect", finalDuration, function()
        -- 如果是有人拿着的就不再寻找
        local owner = inst.components.inventoryitem:GetGrandOwner()
        if owner ~= nil then
            return
        end

        local dist = 5
        local x, y, z = inst.Transform:GetWorldPosition()
        local plants = TheSim:FindEntities(x, 0, z, dist)

        -- 尝试收集
        local targetPlant = nil
        for times = 1, longTimes do -- 循环实验
            for i, plant in ipairs(plants) do
                if plant ~= nil and plant:IsValid() then -- 无效则不干活了
                    -- 如果可以收集
                    if plant.components.pickable ~= nil then
                        if plant.components.pickable:CanBePicked() then -- 收集
                            plant.components.pickable:Pick(inst)
                            targetPlant = plant
                            break
                        end

                    -- 如果可以 workable
                    elseif plant.components.workable ~= nil then
                        local action = plant.components.workable:GetWorkAction()

                        if action == ACTIONS.CHOP then -- 挖掘
                            plant.components.workable:WorkedBy(inst, 1)
                            targetPlant = plant
                            break
                        elseif action == ACTIONS.MINE then -- 矿
                            plant.components.workable:WorkedBy(inst, 1)
                            targetPlant = plant
                            break
                        end
                    end
                end
            end
        end

        if targetPlant ~= nil then
            if dev_mode then
                aipPrint("Auto Pick:", targetPlant.prefab)
            end

            if hasWatcher then
                aipSpawnPrefab(targetPlant, "aip_shadow_wrapper").DoShow()
            end

            inst.AnimState:PlayAnimation("aipCollect")
            inst.AnimState:PushAnimation("aipStruggle", true)
            inst._aipTargetPos = targetPlant:GetPosition()
        end
    end)
end

local function onGotNewItem(inst, data)
    local item = data.item
    -- 丢起物品
    inst:DoTaskInTime(.001, function()
        if
            inst.components.inventory ~= nil and item ~=nil and item:IsValid() and
            -- 确定是否有 replica
            item.components.inventoryitem ~= nil and
            item.replica.inventoryitem ~= nil
        then
            inst.components.inventory:DropItem(item, true, true, inst._aipTargetPos)
        end
    end)
end

local function onInit(inst)
    if inst.components.inventory ~= nil then
        inst.components.inventory:DropEverything()
    end
end

local function OnEntityWake(inst)
    triggerCollect(inst, true)
end

local function OnEntitySleep(inst)
    triggerCollect(inst, false)
end

local function CanShaveTest(inst, shaver)
    return true
end

-- 刮毛后会飞走
local function onShaved(inst)
    local replaced = aipReplacePrefab(inst, "aip_oldone_marble_head")
    replaced:AddTag("FX")
    replaced:AddTag("NOCLICK")

    replaced.AnimState:PlayAnimation("aipJumpBack")
    replaced:ListenForEvent("animover", replaced.Remove)

    -- 复活破碎的雕像
    local marbles = aipFindEnts("aip_oldone_marble")

    -- 找到破碎的雕像
    local broken = nil
    for i, marble in ipairs(marbles) do
        if marble.components.health ~= nil and marble.components.health:IsDead() then
            broken = marble
            break
        end
    end

    -- 恢复破碎的雕像
    if broken ~= nil then
        broken.components.health:DoDelta(
            broken.components.health.maxhealth,
            true, "regen"
        )

        aipSpawnPrefab(broken, "aip_shadow_wrapper").DoShow()

        broken.AnimState:PlayAnimation("back")
        broken.AnimState:PushAnimation("idle", true)
    end
end

--------------------------------- 实例 ---------------------------------

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeHeavyObstaclePhysics(inst, PHYSICS_RADIUS, PHYSICS_HEIGHT)
    inst:SetPhysicsRadiusOverride(PHYSICS_RADIUS)

    inst.AnimState:SetBank("chesspiece")
    inst.AnimState:SetBuild("aip_oldone_marble_head_lock")
    inst.AnimState:PlayAnimation("aipStruggle", true)

    inst:AddTag("heavy")

    MakeInventoryFloatable(inst, "med", nil, 0.65)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inventory")

    inst:AddComponent("heavyobstaclephysics")
    inst.components.heavyobstaclephysics:SetRadius(PHYSICS_RADIUS)

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.cangoincontainer = false
    inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_oldone_marble_head_lock.xml"

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.BODY
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    inst.components.equippable.walkspeedmult = TUNING.HEAVY_SPEED_MULT

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

     -- 剃刀刮下后，就会飞走
     inst:AddComponent("beard")
     inst.components.beard.bits = 1
     inst.components.beard.canshavetest = CanShaveTest
     inst.components.beard.prize = "aip_oldone_thestral_fur"
     inst:ListenForEvent("shaved", onShaved)

    inst:AddComponent("aipc_timer")

    inst:ListenForEvent("gotnewitem", onGotNewItem)

    inst.OnEntitySleep = OnEntitySleep
    inst.OnEntityWake = OnEntityWake

    inst:DoTaskInTime(0.1, onInit)

    return inst
end

return Prefab("aip_oldone_marble_head_lock", fn, assets)
