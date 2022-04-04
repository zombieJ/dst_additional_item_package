local language = aipGetModConfig("language")

-- local brain = require("brains/aip_oldone_marble_brain")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Defaced Statue",
		DESC = "It has a heavy head",
        HEAD_NAME = "Head Part",
        HEAD_DESC = "This is the main part",
	},
	chinese = {
		NAME = "污损的雕像",
		DESC = "它的头似乎很沉重",
        HEAD_NAME = "头颅部件",
        HEAD_DESC = "这是它的本体",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_OLDONE_MARBLE = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_MARBLE = LANG.DESC

STRINGS.NAMES.AIP_OLDONE_MARBLE_HEAD = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_MARBLE_HEAD = LANG.DESC

--------------------------------- 雕塑 ---------------------------------
-- 简易版 brain，不需要 Stage 配合
local function doBrain(inst)
    aipQueue(
        -- 附近有玩家的时候投掷脓包
        function()
            -- CD 中则不执行其他操作了
            if inst.components.timer:TimerExists("aip_throw") then
                return true
            end

            -- 没有玩家则跳过
            local players = aipFindNearPlayers(inst, 6)
            local player = aipRandomEnt(players)
            if player == nil then
                return false
            end

            inst.components.timer:StartTimer("aip_throw", 2.55)
            local ball = aipSpawnPrefab(inst, "aip_oldone_plant_full")
            local x, y, z = player.Transform:GetWorldPosition()
            ball.components.complexprojectile:SetLaunchOffset(Vector3(0, 5, 0))
            ball.components.complexprojectile:Launch(
                Vector3(
                    x,
                    0,
                    z
                ),
                inst
            )

            return true
        end
    )
end

local function stopBrain(inst)
    if inst._aipBrain ~= nil then
        inst._aipBrain:Cancel()
    end

    inst._aipBrain = nil
end

local function startBrain(inst)
    stopBrain(inst)

    inst._aipBrain = inst:DoPeriodicTask(0.25, function()
		doBrain(inst)
	end, 0.1)
end

local function onNear(inst)
    startBrain(inst)
end

local function onFar(inst)
    stopBrain(inst)
end

---------------------------------- AI ----------------------------------
local assets = {
    Asset("ANIM", "anim/aip_oldone_marble.zip"),
}

local function onremovebody(body)
    body._aipBody._aipHead = nil
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 1.5)

    inst.AnimState:SetBank("aip_oldone_marble")
    inst.AnimState:SetBuild("aip_oldone_marble")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("largecreature")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("timer")

    inst:AddComponent("inspectable")

    -- 创造跟随的头部
    inst:DoTaskInTime(3, function()
        -- inst.AnimState:Hide("head")
    end)

    inst:AddComponent("playerprox")
	inst.components.playerprox:SetDist(15, 30)
	inst.components.playerprox:SetOnPlayerNear(onNear)
	inst.components.playerprox:SetOnPlayerFar(onFar)

    return inst
end

--------------------------------- 头像 ---------------------------------
local PHYSICS_RADIUS = .45

local headAssets = {
    Asset("ANIM", "anim/aip_oldone_marble_head.zip"),
    Asset("ATLAS", "images/inventoryimages/aip_oldone_marble_head.xml"),
}

local function onequip(inst, owner)
	owner.AnimState:OverrideSymbol("swap_body", "aip_oldone_marble_head", "swap_body")
end

local function onunequip(inst, owner)
	owner.AnimState:ClearOverrideSymbol("swap_body")
end

local function headFn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeHeavyObstaclePhysics(inst, PHYSICS_RADIUS)

    inst.AnimState:SetBank("chesspiece")
    inst.AnimState:SetBuild("aip_oldone_marble_head")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("heavy")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    -- 这个是头，别放错地方！

    inst:AddComponent("heavyobstaclephysics")
    inst.components.heavyobstaclephysics:SetRadius(PHYSICS_RADIUS)

    inst:AddComponent("inspectable")

    inst:AddComponent("lootdropper")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.cangoincontainer = false
    inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_oldone_marble_head.xml"

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.BODY
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    inst.components.equippable.walkspeedmult = TUNING.HEAVY_SPEED_MULT

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

    inst.persists = false

    -- 这个是头，别放错地方！

    return inst
end

return Prefab("aip_oldone_marble", fn, assets), Prefab("aip_oldone_marble_head", headFn, headAssets)
