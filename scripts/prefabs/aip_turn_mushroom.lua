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
-- 种子池
local seedsPool = {
    seeds = 0,  -- 不允许变回种子
}

for veggieName, veggieInfo in pairs(VEGGIES) do
    if SEEDLESS_VEGGIES[k] ~= true then
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

local randomPools = {
    seedsPool,
    treeSeedsPool,
    gemsPool,
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

    inst.components.aipc_timer:NamedInterval("PlayerNear", 0.4, function()
        -- TODO: 实现逻辑

        local rocks = aipFindNearEnts(inst, { "rocks" }, 0.6)

        if #rocks > 0 then
            aipRemove(rocks[1])

            for i = 1, #rocks do
                aipFlingItem(rocks[i])
            end

            -- 播放一个闪现特效
            aipSpawnPrefab(inst, "aip_shadow_wrapper").DoShow(0.6)

            inst:RemoveComponent("aipc_timer")

            -- 增加模因因子
            local players = aipFindNearPlayers(inst, 3)
            for i, player in ipairs(players) do
                if player ~= nil and player.components.aipc_oldone ~= nil then
                    player.components.aipc_oldone:DoDelta()
                end
            end

            -- 消失吧
            inst:DoTaskInTime(1, function()
                if inst._aipMaster ~= nil then
                    inst._aipMaster:Remove()
                end
            end)
        end
    end)
end

local function onFar(inst)
    inst.components.aipc_timer:KillName("PlayerNear")
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
    local min = 8
    local max = 10
    local count = math.random(min, max)

    local dist = 1.8 + (count - min) * 0.15
    local startAngle = PI * 2 * math.random()

    for i = 1, count do
        local angle = startAngle + PI * 2 * i / count

        local stone = aipSpawnPrefab(
            nil, "aip_turn_mushroom",
            cx + math.cos(angle) * dist,
            cy,
            cz + math.sin(angle) * dist
        )

        stone._aipMaster = inst

        table.insert(inst._aipStones, stone)
    end

     -- 创建监听器
     inst:AddComponent("playerprox")
     inst.components.playerprox:SetDist(8, 8)
     inst.components.playerprox:SetOnPlayerNear(onNear)
     inst.components.playerprox:SetOnPlayerFar(onFar)
end

local function OnRemoveEntity(inst)
    if inst._aipStones ~= nil then
        for i, stone in ipairs(inst._aipStones) do
            aipReplacePrefab(stone, "aip_shadow_wrapper").DoShow(0.6)
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
    inst.AnimState:PlayAnimation("m1")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    -- 算了，不要查看了吧
    -- inst:AddComponent("inspectable")

    inst:DoTaskInTime(0.1, initMatrix)

    inst.persists = false

    inst.OnRemoveEntity = OnRemoveEntity

    return inst
end

return Prefab("aip_turn_mushroom", fn, assets)
