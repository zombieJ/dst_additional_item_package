local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Prosperity Tree",
		DESC = "Offer Is Take. It need some veggie",
        SEED_NAME = "Prosperity Seed",
        SEED_DESC = "Plant It!",
	},
	chinese = {
		NAME = "繁荣之树",
		DESC = "供奉即索取，它需要一些蔬果",
        SEED_NAME = "繁荣之种",
        SEED_DESC = "种下它！",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_PROSPERITY_TREE = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_PROSPERITY_TREE = LANG.DESC
STRINGS.NAMES.AIP_PROSPERITY_SEED = LANG.SEED_NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_PROSPERITY_SEED = LANG.SEED_DESC


-- 资源
local prefabs = {
    "cane_harlequin_fx",
}

local assets = {
    Asset("ANIM", "anim/aip_prosperity_tree.zip"),
    Asset("ANIM", "anim/aip_prosperity_tree_leaf.zip"),
    Asset("ANIM", "anim/aip_prosperity_seed.zip"),
    Asset("ATLAS", "images/inventoryimages/aip_prosperity_seed.xml"),
}

------------------------------------ 数据 ------------------------------------
local tree_data = {
    "item_five",
    "item_three",
    "item_nine",
    "item_one",
    "item_six",
    "item_seven",
    "item_two",
    "item_four",
    "item_eight",
}

------------------------------------ 事件 ------------------------------------
local PLANT_DEFS = require("prefabs/farm_plant_defs").PLANT_DEFS

local function initData(inst)
    if inst._aipFoods == nil then
        inst._aipFoods = {}
    end
end

-- 给予（只接受可以种植的）
local function canBeGiveOn(inst, doer, item)
    return PLANT_DEFS[item.prefab] ~= nil
end

local function syncFoods(inst)
    initData(inst)

    local needResync = false

    for key, data in pairs(inst._aipFoods) do
        local symbol = tree_data[key]

        -- 创建挂载叶子
        if data.leaf == nil then
            local clone = aipSpawnPrefab(inst, "aip_prosperity_tree_leaf")

            if clone.Follower == nil then
                clone.entity:AddFollower()
            end

            local scale = 0.8
            clone.Transform:SetScale(scale, scale, scale)

            clone.Follower:FollowSymbol(inst.GUID, symbol, 0, 0, 0.05)

            data.leaf = clone
        end

        -- 创建挂载食物
        if data.prefab == nil or not data.prefab:IsValid() then
            local clone = aipSpawnPrefab(inst, data.name)

            if clone.Follower == nil then
                clone.entity:AddFollower()
            end

            if clone.components.perishable ~= nil then
                clone.components.perishable:StopPerishing()
            end

            local scale = 0.8
            clone.Transform:SetScale(scale, scale, scale)

            clone:AddTag("fx")
            clone:AddTag("NOCLICK")
            clone.persists = false
            clone.Follower:FollowSymbol(inst.GUID, symbol, 0, 0, 0.1)

            data.prefab = clone
        end

        -- 同步进度
        -- data.prefab.AnimState:OverrideMultColour(1, 1, 1, 0.6 + data.ptg * 0.3)
        local prefabScale = math.min(1, 0.4 + data.ptg * 0.6)
        data.prefab.Transform:SetScale(prefabScale, prefabScale, prefabScale)

        -- 如果食物成熟，则掉落
        if data.ptg >= 1 then
            data.ptg = 0

            local clone = aipSpawnPrefab(inst, data.name)
            aipFlingItem(clone)

            needResync = true
        end
    end

    if needResync then
        syncFoods(inst)
    end
end

-- 获得食物
local function onDoGiveAction(inst, doer, item)
    initData(inst)

    -- 找到一个可以空置的地方
    local cnt = #tree_data
    local foodIndex = math.random(cnt)

    -- 如果和之前相同，我们再随机一次
    while(foodIndex == inst._aipLastIndex)
    do
        foodIndex = math.random(cnt)
    end

    for i = 1, cnt do
        if inst._aipFoods[i] == nil then
            foodIndex = i
            break
        end
    end

    -- 移除原来的植物
    if inst._aipFoods[foodIndex] ~= nil then
        aipRemove(inst._aipFoods[foodIndex].prefab)
    end

    -- 按照位置插入
    inst._aipFoods[foodIndex] = {
        name = item.prefab,
        ptg = 0,
        prefab = nil,   -- 绑定的元素，不会保存
        leaf = nil,     -- 绑定叶子
    }

    aipRemove(item)
    syncFoods(inst)

    inst._aipLastIndex = foodIndex
end

-- 每天提升一点食物价值
local function OnIsDay(inst, isday)
    if not isday then
        return
    end

    local total = #tree_data
    local foodIndex = math.random(total)

    if inst._aipFoods[foodIndex] ~= nil then
        inst._aipFoods[foodIndex].ptg = math.min(inst._aipFoods[foodIndex].ptg + 0.4, 1)
    else
        for i = 1, total do
            if inst._aipFoods[i] ~= nil then
                inst._aipFoods[i].ptg = math.min(inst._aipFoods[i].ptg + 0.04, 1)
            end
        end
    end

    syncFoods(inst)
end

local function onFinish(inst, doer)
    aipFlingItem(
        aipSpawnPrefab(inst, "aip_prosperity_seed")
    )
    aipReplacePrefab(inst, "aip_shadow_wrapper").DoShow()
end

local function onRemove(inst)
    initData(inst)

    for key, data in pairs(inst._aipFoods) do
        aipRemove(data.prefab)
        aipRemove(data.leaf)
    end
end

-------------------------- 存取 --------------------------
local function onSave(inst, data)
    data._aipFoods = {}

    for key, value in pairs(inst._aipFoods) do
        data._aipFoods[key] = {
            name = value.name,
            ptg = value.ptg,
        }
    end
end

local function onLoad(inst, data)
	if data ~= nil and data._aipFoods ~= nil then
        inst._aipFoods = data._aipFoods
        syncFoods(inst)
    end
end

------------------------------------ 实体 ------------------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, .2)

    inst.AnimState:SetBank("aip_prosperity_tree")
    inst.AnimState:SetBuild("aip_prosperity_tree")
    inst.AnimState:PlayAnimation("idle", true)

    inst:AddComponent("aipc_action_client")
    inst.components.aipc_action_client.canBeGiveOn = canBeGiveOn

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    -- 可以接受物品
    inst:AddComponent("aipc_action")
    inst.components.aipc_action.onDoGiveAction = onDoGiveAction

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.MINE)
    inst.components.workable:SetWorkLeft(3)
    inst.components.workable:SetOnFinishCallback(onFinish)

    inst:AddComponent("hauntable")
    -- MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
    -- MakeMediumPropagator(inst)

    inst:WatchWorldState("isday", OnIsDay)
    inst:ListenForEvent("onremove", onRemove)

    initData(inst)

    inst.OnLoad = onLoad
	inst.OnSave = onSave

    return inst
end

-- ==========================================================================
-- ==                                 叶子                                 ==
-- ==========================================================================
local function leafFn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("aip_prosperity_tree_leaf")
    inst.AnimState:SetBuild("aip_prosperity_tree_leaf")
    inst.AnimState:PlayAnimation("idle"..tostring(math.random(3)), true)

    inst:AddTag("fx")
    inst:AddTag("NOCLICK")
    inst.persists = false

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    return inst
end


-- ==========================================================================
-- ==                                 种子                                 ==
-- ==========================================================================
local function onDeploy(inst, pt, deployer)
	local tgt = SpawnPrefab("aip_prosperity_tree")
	tgt.Transform:SetPosition(pt.x, pt.y, pt.z)

    aipSpawnPrefab(tgt, "aip_shadow_wrapper").DoShow()

	aipRemove(inst)
end

local function seedFn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("aip_prosperity_seed")
    inst.AnimState:SetBuild("aip_prosperity_seed")
    inst.AnimState:PlayAnimation("idle")

    MakeInventoryFloatable(inst, "med", 0.3, 1)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_prosperity_seed.xml"

    inst:AddComponent("deployable")
    inst.components.deployable:SetDeployMode(DEPLOYMODE.PLANT)
    inst.components.deployable.ondeploy = onDeploy

    return inst
end

return Prefab("aip_prosperity_tree", fn, assets, prefabs),
        Prefab("aip_prosperity_tree_leaf", leafFn, assets),
        Prefab("aip_prosperity_seed", seedFn, assets)
