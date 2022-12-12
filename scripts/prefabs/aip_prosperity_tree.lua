local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Prosperity Tree",
		DESC = "Offer Is Take",
	},
	chinese = {
		NAME = "繁荣之树",
		DESC = "供奉即索取",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_PROSPERITY_TREE = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_PROSPERITY_TREE = LANG.DESC

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_prosperity_tree.zip"),
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

    for key, data in pairs(inst._aipFoods) do
        -- 创建挂载食物
        if data.prefab == nil then
            local clone = aipSpawnPrefab(inst, data.name)
            local symbol = tree_data[key]

            if clone.Follower == nil then
                clone.entity:AddFollower()
            end

            local scale = 0.65
            clone.Transform:SetScale(scale, scale, scale)

            clone:AddTag("fx")
            clone:AddTag("NOCLICK")
            clone.persists = false
            clone.Follower:FollowSymbol(inst.GUID, symbol, 0, 0, 0.1)

            data.prefab = clone
        end

        -- 同步进度
        data.prefab.AnimState:SetMultColour(1, 1, 1, 0.6 + data.ptg * 0.3)
    end
end

-- 获得食物
local function onDoGiveAction(inst, doer, item)
    initData(inst)

    -- 找到一个可以空置的地方
    local cnt = #tree_data
    local foodIndex = math.random(cnt)

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
        prefab = nil, -- 绑定的元素，不会保存
    }

    aipRemove(item)
    syncFoods(inst)
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

    -- inst:AddComponent("workable")
    -- inst.components.workable:SetWorkAction(ACTIONS.CHOP)
    -- inst.components.workable:SetWorkLeft(1)
    -- inst.components.workable:SetOnFinishCallback(onFinish)

    inst:AddComponent("hauntable")
    MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
    MakeMediumPropagator(inst)

    inst:WatchWorldState("isday", OnIsDay)

    initData(inst)

    return inst
end

return Prefab("aip_prosperity_tree", fn, assets)
