local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Fixed Rocks",
		DESC = "looks like a puzzle",
	},
	chinese = {
		NAME = "固定的石头",
		DESC = "看起来是个谜题",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_OLDONE_ROCK = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_ROCK = LANG.DESC

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_oldone_rock.zip"),
}

------------------------------ 事件 --------------------------------
local function hidePrefab(inst)
    inst:AddTag("NOCLICK")
    inst:AddTag("FX")
    inst.AnimState:OverrideMultColour(0, 0, 0, 0)
end

local function showPrefab(inst)
    inst:RemoveTag("NOCLICK")
    inst:RemoveTag("FX")
    inst.AnimState:OverrideMultColour(1, 1, 1, 1)
end

local function onNear(inst, player)
    inst.components.aipc_timer:NamedInterval("PlayerNear", 0.4, function()
        local rocks = aipFindNearEnts(inst, { "rocks" }, 0.6)

        if #rocks > 0 then
            aipRemove(rocks[1])

            for i = 1, #rocks do
                aipFlingItem(rocks[i])
            end

            -- 播放一个闪现特效
            showPrefab(inst)
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
            nil, "aip_oldone_rock",
            cx + math.cos(angle) * dist,
            cy,
            cz + math.sin(angle) * dist
        )

        stone._aipMaster = inst

        table.insert(inst._aipStones, stone)

        -- 创建监听器
        if i == 1 then
            stone:AddComponent("playerprox")
            stone.components.playerprox:SetDist(8, 8)
            stone.components.playerprox:SetOnPlayerNear(onNear)
            stone.components.playerprox:SetOnPlayerFar(onFar)

            stone:AddComponent("aipc_timer")

            hidePrefab(stone)
        end
    end
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

    inst.AnimState:SetBank("aip_oldone_rock")
    inst.AnimState:SetBuild("aip_oldone_rock")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("aip_olden_flower")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    MakeHauntableLaunch(inst)

    inst:DoTaskInTime(0.1, initMatrix)

    inst.persists = false

    inst.OnRemoveEntity = OnRemoveEntity

    return inst
end

return Prefab("aip_oldone_rock", fn, assets)
