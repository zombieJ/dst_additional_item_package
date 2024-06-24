require "prefabs/veggies"

local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Transform Mushroom",
		DESC = "What can it do?",
	},
	chinese = {
		NAME = "变形环蘑",
		DESC = "它能对什么起作用呢？",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_TURN_MUSHROON = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_TURN_MUSHROON = LANG.DESC

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_turn_mushroom.zip"),
}

------------------------------ 变化 --------------------------------
local DIST = 1.5

-- 种子池
local seedsPool = {
    seeds = 0,  -- 不允许变回种子
}

for veggieName, veggieInfo in pairs(VEGGIES) do
    if veggieInfo.seed_weight and veggieInfo.seed_weight > 0 then
        seedsPool[veggieName.."_seeds"] = veggieInfo.seed_weight
    end
end

-- 树种池
local treeSeedsPool = {
    pinecone = 1,
    acorn = 1,
    twiggy_nut = 1,
    seeds = 2,
    palmcone_seed = 0.1,
    marblebean = 0.5, -- 大理石豌豆
    rock_avocado_fruit = 1, -- 石果
}

-- 宝石池
local gemsPool = {
    redgem = 1,
    bluegem = 1,
    purplegem = 1,
    orangegem = 1,
    yellowgem = 1,
    greengem = 1,
    opalpreciousgem = 0.1,
}

-- 石头池
local stonesPool = {
    thulecite_pieces = 0.1,
    rocks = 1,
    flint = 1,
    nitre = 1,
}

-- 芦苇 与 草
local reedsPool = {
    cutgrass = 1,
    cutreeds = 1,
}

-- 木头类
local woodsPool = {
    log = 1,
    driftwood_log = 1,
    livinglog = 0.2,
    twigs =
     1,
}

-- 光明与黑暗
local lightPool = {
    purebrilliance = 0.5,   -- 纯净辉煌
    moonglass_charged = 1,  -- 注能月亮碎片
    moonglass = 2,          -- 月光玻璃
    horrorfuel = 0.5,       -- 纯粹恐惧
    dreadstone = 1,        -- 绝望石
    nightmarefuel = 2,     -- 梦魇燃料
}

-- 花与叶
local flowerPool = {
    petals = 1,             -- 花瓣
    petals_evil = 1,        -- 恶魔花瓣
    foliage = 1,            -- 蕨叶
    kelp = 1,               -- 海带
    kelp_dried = 1,         -- 干海带
}

-- 肉类
local meatPool = {
    meat = 1,
    cookedmeat = 1,
    meat_dried = 1,

    monstermeat = 1,
    cookedmonstermeat = 1,
    monstermeat_dried = 1,

    plantmeat = 1,
    plantmeat_cooked = 1,

    fishmeat = 1,
    fishmeat_cooked = 1,

    trunk_summer = 1,
    trunk_winter = 1,
    trunk_cooked = 1,
}

-- 小肉类
local smallMeatPool = {
    fishmeat_small = 1,
    fishmeat_small_cooked = 1,

    drumstick = 1,
    drumstick_cooked = 1,

    froglegs = 1,
    froglegs_cooked = 1,

    batwing = 1,
    batwing_cooked = 1,

    smallmeat = 1,
    cookedsmallmeat = 1,
    smallmeat_dried = 1,

    batnose = 1,
    batnose_cooked = 1,

    eel = 1,
    eel_cooked = 1,
}

-- 水果类
local fruitsPool = {
}

local randomPools = {
    seedsPool,
    treeSeedsPool, -- 树种会变成种子，所以要在种子池后面
    gemsPool,
    stonesPool,
    reedsPool,
    woodsPool,
    lightPool,
    flowerPool,
    meatPool,
    smallMeatPool,
}

------------------------------ 事件 --------------------------------
local function hidePrefab(inst)
    inst:AddTag("NOCLICK")
    inst:AddTag("FX")
    inst.AnimState:PlayAnimation("empty")
end

local function onNear(inst, player)
    -- 触发后会移除 timer 组件，这里需要跳过
    if inst.components.aipc_timer == nil then
        return
    end

     -- 我们先把 randomPools 里的所有池子合并到一个表里
     local allValidPrefabs = {}
     for i, pool in ipairs(randomPools) do
         for prefabName, weight in pairs(pool) do
             table.insert(allValidPrefabs, prefabName)
         end
     end

     aipPrint("allValidPrefabs", allValidPrefabs)

    inst.components.aipc_timer:NamedInterval("PlayerNear", 0.4, function()
        -- 把东西拿出来吧
        local prefabs = aipFindNearEnts(inst, allValidPrefabs, DIST - 0.2, false)
        if #prefabs <= 0 then
            return
        end

        -- 如果存在，我们则随机其中一个进行转化
        local targetPrefab = aipRandomEnt(prefabs)

        -- 遍历原始的 randomPools 表，找到对应的池子
        local targetPool = nil
        for i, pool in ipairs(randomPools) do
            if pool[targetPrefab.prefab] ~= nil then
                targetPool = pool
                break
            end
        end
        if targetPool == nil then
            return
        end

        -- 替换为新的物品，随机 20 次如果都不行就算了
        for i = 1, 20 do
            local nextPrefab = aipRandomLoot(targetPool)
            if nextPrefab and nextPrefab ~= targetPrefab.prefab then
                aipSpawnPrefab(targetPrefab, "aip_fx_splode").DoShow()
                local nextItem = aipSpawnPrefab(targetPrefab, nextPrefab)

                aipFlingItem(nextItem)
                aipRemove(targetPrefab)

                -- 好了，拜拜
                inst:Remove()
                break
            end
        end
        
    end)
end

local function onFar(inst)
    if inst.components.aipc_timer ~= nil then
        inst.components.aipc_timer:KillName("PlayerNear")
    end
end

-- 初始化矩阵
local function initMatrix(inst)
    if inst._aipMaster ~= nil then
        return
    end

    inst._aipStones = {}

    -- 隐藏入口石头
    hidePrefab(inst)

    -- 初始化一圈矩阵
    local cx, cy, cz = inst.Transform:GetWorldPosition()
    local min = 6
    local max = 8
    local count = math.random(min, max)

    local startAngle = PI * 2 * math.random()

    for i = 1, count do
        local angle = startAngle + PI * 2 * i / count

        local stone = aipSpawnPrefab(
            nil, "aip_turn_mushroom",
            cx + math.cos(angle) * DIST,
            cy,
            cz + math.sin(angle) * DIST
        )

        stone._aipMaster = inst

        table.insert(inst._aipStones, stone)
    end

     -- 创建监听器
     local playerDist = DIST + 2
     inst:AddComponent("playerprox")
     inst.components.playerprox:SetDist(playerDist, playerDist)
     inst.components.playerprox:SetOnPlayerNear(onNear)
     inst.components.playerprox:SetOnPlayerFar(onFar)
end

local function OnRemoveEntity(inst)
    if inst._aipStones ~= nil then
        for i, stone in ipairs(inst._aipStones) do
            aipReplacePrefab(stone, "aip_shadow_wrapper").DoShow(0.2)
        end
    end
end

------------------------------ 实体 --------------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("aip_turn_mushroom")
    inst.AnimState:SetBuild("aip_turn_mushroom")
    inst.AnimState:PlayAnimation("m"..math.random(4))   -- m1, m2, m3, m4

    local scale = 0.4 + math.random() * 0.3
    inst.Transform:SetScale(scale, scale, scale)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("aipc_timer")

    inst:DoTaskInTime(0.1, initMatrix)

    inst.persists = false

    inst.OnRemoveEntity = OnRemoveEntity

    return inst
end

return Prefab("aip_turn_mushroom", fn, assets)
