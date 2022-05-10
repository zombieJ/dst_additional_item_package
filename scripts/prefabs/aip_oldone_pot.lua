local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Haunted Pot",
		DESC = "Seem I need resolve these at same time",
	},
	chinese = {
		NAME = "闹鬼陶罐",
		DESC = "看来得同时解决它们",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_OLDONE_POT = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_POT = LANG.DESC

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_oldone_pot.zip"),
}

------------------------------ 事件 --------------------------------
local function hidePrefab(inst)
    inst:AddTag("NOCLICK")
    inst:AddTag("FX")
    inst.AnimState:PlayAnimation("empty")
end

local function showPrefab(inst)
    inst:RemoveTag("NOCLICK")
    inst:RemoveTag("FX")
    inst.AnimState:PlayAnimation("idle")
end

local function checkAll(inst)
    if inst._aipPots ~= nil then
        local allDead = true

        for i, pot in ipairs(inst._aipPots) do
            if pot.components.health ~= nil and not pot.components.health:IsDead() then
                allDead = false
                break
            end
        end

        if allDead then
            local players = aipFindNearPlayers(inst, 8)
            for i, player in ipairs(players) do
                if player ~= nil and player.components.aipc_oldone ~= nil then
                    player.components.aipc_oldone:DoDelta()
                end
            end

            aipRemove(inst)
        end
    end
end

-- 初始化矩阵
local function initMatrix(inst)
    if inst._aipMaster ~= nil then
        return
    end

    inst._aipPots = {}

    -- 隐藏入口陶罐
    hidePrefab(inst)

    -- 初始化一圈矩阵
    local cx, cy, cz = inst.Transform:GetWorldPosition()

    local dist = 2
    local startAngle = PI * 2 * math.random()

    for i = 1, 3 do
        local angle = startAngle + PI * 2 * i / 3

        local pot = aipSpawnPrefab(
            nil, "aip_oldone_pot",
            cx + math.cos(angle) * dist,
            cy,
            cz + math.sin(angle) * dist
        )

        pot._aipMaster = inst

        table.insert(inst._aipPots, pot)
    end

    inst._aipCheckAll = checkAll
end

local function OnRemoveEntity(inst)
    if inst._aipPots ~= nil then
        for i, pot in ipairs(inst._aipPots) do
            if pot._aipTask ~= nil then
                pot._aipTask:Cancel()
            end

            aipReplacePrefab(pot, "aip_shadow_wrapper").DoShow(0.6)
        end
    end
end

local function onDeath(inst)
    if inst._aipTask ~= nil then
        inst._aipTask:Cancel()
        inst._aipTask = nil
    end

    if inst._aipMaster ~= nil then
        inst.AnimState:PlayAnimation("dead")
        aipSpawnPrefab(inst, "collapse_small")

        inst._aipTask = inst:DoTaskInTime(1, function()
            aipSpawnPrefab(inst, "aip_shadow_wrapper").DoShow(0.6)
            inst.components.health:SetPercent(1)
            inst.AnimState:PlayAnimation("idle")
        end)

        if inst._aipMaster._aipCheckAll ~= nil then
            inst._aipMaster._aipCheckAll(inst._aipMaster)
        end
    end
end

------------------------------ 实体 --------------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("aip_oldone_pot")
    inst.AnimState:SetBuild("aip_oldone_pot")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("aip_olden_flower")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(1)
	inst.components.health.nofadeout = true

	inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "body"

    MakeHauntableLaunch(inst)

    inst:DoTaskInTime(0.1, initMatrix)

    inst.persists = false

    inst.OnRemoveEntity = OnRemoveEntity

    inst:ListenForEvent("death", onDeath)

    return inst
end

return Prefab("aip_oldone_pot", fn, assets)
