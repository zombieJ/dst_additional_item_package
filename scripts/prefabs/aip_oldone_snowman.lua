local dev_mode = aipGetModConfig("dev_mode") == "enabled"
local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Snow Man",
		DESC = "It's so happy to build a snow man",
        SNOWBALL_NAME = "Snowball",
        SNOWBALL_DESC = "Let's build a snow man",
	},
	chinese = {
		NAME = "雪团",
		DESC = "堆雪人真是件快乐的事情",
        SNOWBALL_NAME = "雪球",
        SNOWBALL_DESC = "用来堆雪人就对了",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_OLDONE_SNOWMAN = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_SNOWMAN = LANG.DESC
STRINGS.NAMES.AIP_OLDONE_SNOWBALL = LANG.SNOWBALL_NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_SNOWBALL = LANG.SNOWBALL_DESC

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_oldone_snowman.zip"),
}

------------------------------- 事件 -------------------------------
local BASE_DIST = dev_mode and 5 or 20
local MAX_LEVEL = 2

local function symcStatus(inst)
    if inst._aipLevel == 0 then
        inst.AnimState:PlayAnimation("low")
    elseif inst._aipLevel == 1 then
        inst.AnimState:PlayAnimation("mid")
    elseif inst._aipLevel >= MAX_LEVEL then
        inst.AnimState:PlayAnimation(inst._aipSnowName)
    end
end

local function initPuzzle(inst)
    inst._aipLevel = 0
    inst._snowballs = {}
    inst._aipSnowName = aipRandomEnt({ "rabbit", "spider", "snowman" })
    symcStatus(inst)

    -- 在附近随机创建 3 个雪球
    local center = inst:GetPosition()
    local cnt = 0

    for i = 1, 10 do
        local dist = math.random(BASE_DIST, BASE_DIST + 10)
        local pt = aipGetSecretSpawnPoint(center, dist, dist + 10, 2)

        if pt ~= nil then
            local snowball = aipSpawnPrefab(nil, "aip_oldone_snowball", pt.x, pt.y, pt.z)
            snowball._aipMaster = inst
            table.insert(inst._snowballs, snowball)

            -- 超过 3 个就不再创建了
            cnt = cnt + 1
            if cnt >= 3 then
                break
            end
        end
    end
end

local function collectBalls(inst)
    local balls = aipFindNearEnts(inst, { "aip_oldone_snowball" }, 2)

    for i, ball in ipairs(balls) do
        aipRemove(ball)

        inst._aipLevel = inst._aipLevel + 1
    end
    symcStatus(inst)

    if inst._aipLevel >= MAX_LEVEL then
        inst.aipCollect = nil

        -- 奖励附近的玩家
        local players = aipFindNearPlayers(inst, 5)
        for i, player in ipairs(players) do
            if player ~= nil and player.components.aipc_oldone ~= nil then
                player.components.aipc_oldone:DoDelta()
            end
        end

        inst:ListenForEvent("animover", function()
            aipReplacePrefab(inst, "aip_shadow_wrapper").DoShow(1.5)
        end)
    end
end

local function onWorldState(inst, season)
    if season ~= "winter" then
        aipReplacePrefab(inst, "aip_shadow_wrapper").DoShow(1.5)
    end
end

local function OnRemoveEntity(inst)
    if inst._snowballs ~= nil then
        for i, ball in ipairs(inst._snowballs) do
            aipRemove(ball)
        end
    end
end

------------------------------- 实例：雪人 -------------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 1)

    inst.AnimState:SetBank("aip_oldone_snowman")
    inst.AnimState:SetBuild("aip_oldone_snowman")
    inst.AnimState:PlayAnimation("low")

    inst:AddTag("aip_olden_flower")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("hauntable")
    inst.components.hauntable.cooldown = TUNING.HAUNT_COOLDOWN_MEDIUM

    inst.aipCollect = collectBalls

    inst.persists = false

    inst:DoTaskInTime(0, initPuzzle)

    inst:WatchWorldState("season", onWorldState)

    inst.OnRemoveEntity = OnRemoveEntity

    return inst
end

-- ======================================================================
------------------------------- 实例：雪球 -------------------------------
-- ======================================================================
local PHYSICS_RADIUS = 1

local snowballAssets = {
    Asset("ANIM", "anim/aip_oldone_snowball.zip"),
    Asset("ATLAS", "images/inventoryimages/aip_oldone_snowball.xml"),
}

local function onequip(inst, owner)
	owner.AnimState:OverrideSymbol("swap_body", "aip_oldone_snowball", "swap_body")
end

local function onunequip(inst, owner)
	owner.AnimState:ClearOverrideSymbol("swap_body")
end

local function onBallDropped(inst)
    if inst._aipMaster ~= nil and inst._aipMaster.aipCollect ~= nil then
        inst._aipMaster.aipCollect(inst._aipMaster)
    end
end

local function snowballFn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeHeavyObstaclePhysics(inst, PHYSICS_RADIUS, 1)
    inst:SetPhysicsRadiusOverride(PHYSICS_RADIUS)

    inst.AnimState:SetBank("chesspiece")
    inst.AnimState:SetBuild("aip_oldone_snowball")
    inst.AnimState:PlayAnimation("idle")

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
    inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_oldone_snowball.xml"

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.BODY
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    inst.components.equippable.walkspeedmult = TUNING.HEAVY_SPEED_MULT

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

    inst:ListenForEvent("ondropped", onBallDropped)

    inst.persists = false

    return inst
end

return  Prefab("aip_oldone_snowman", fn, assets),
        Prefab("aip_oldone_snowball", snowballFn, snowballAssets)
