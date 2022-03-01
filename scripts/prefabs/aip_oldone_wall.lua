require "prefabutil"

local language = aipGetModConfig("language")
local dev_mode = aipGetModConfig("dev_mode") == "enabled"

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Rhythmic Wall",
		DESC = "It's alive",
	},
	chinese = {
		NAME = "律动之墙",
		DESC = "看起来像是活的",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_OLDONE_WALL = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_WALL = LANG.DESC
STRINGS.NAMES.AIP_OLDONE_WALL_ITEM = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_WALL_ITEM = LANG.DESC

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_oldone_wall.zip"),
	Asset("ATLAS", "images/inventoryimages/aip_oldone_wall_item.xml"),
}

--------------------------------- 路径 ---------------------------------
local function OnIsPathFindingDirty(inst)
    if inst:GetCurrentPlatform() == nil then
        local wall_x, wall_y, wall_z = inst.Transform:GetWorldPosition()
        if inst._ispathfinding:value() then
            if inst._pfpos == nil then
                inst._pfpos = Point(wall_x, wall_y, wall_z)
                TheWorld.Pathfinder:AddWall(wall_x, wall_y, wall_z)
            end
        elseif inst._pfpos ~= nil then
            TheWorld.Pathfinder:RemoveWall(wall_x, wall_y, wall_z)
            inst._pfpos = nil
        end
    end
end

local function InitializePathFinding(inst)
    inst:ListenForEvent("onispathfindingdirty", OnIsPathFindingDirty)
    OnIsPathFindingDirty(inst)
end

local function onremove(inst)
    inst._ispathfinding:set_local(false)
    OnIsPathFindingDirty(inst)
end

local function makeobstacle(inst)
    inst.Physics:SetActive(true)
    inst._ispathfinding:set(true)
end

--------------------------------- 事件 ---------------------------------
local function ondeploywall(inst, pt, deployer)
    local wall = SpawnPrefab("aip_oldone_wall")
    if wall ~= nil then
        local x = math.floor(pt.x) + .5
        local z = math.floor(pt.z) + .5
        wall.Physics:SetCollides(false)
        wall.Physics:Teleport(x, 0, z)
        wall.Physics:SetCollides(true)
        inst.components.stackable:Get():Remove()

        wall.SoundEmitter:PlaySound("dontstarve/common/place_structure_straw")
    end
end

--------------------------------- 实例：物品 ---------------------------------
local function itemfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst:AddTag("wallbuilder")

    inst.AnimState:SetBank("aip_oldone_wall")
    inst.AnimState:SetBuild("aip_oldone_wall")
    inst.AnimState:PlayAnimation("item", true)

    MakeInventoryFloatable(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_MEDITEM

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_oldone_wall_item.xml"

    MakeSmallBurnable(inst, TUNING.MED_BURNTIME)
    MakeSmallPropagator(inst)


    inst:AddComponent("deployable")
    inst.components.deployable.ondeploy = ondeploywall
    inst.components.deployable:SetDeployMode(DEPLOYMODE.WALL)

    MakeHauntableLaunch(inst)

    return inst
end

--------------------------------- 事件 ---------------------------------
local function keeptargetfn()
    return false
end

local function onhit(inst)
    inst.SoundEmitter:PlaySound("dontstarve/common/destroy_straw")

    if not inst.components.health:IsDead() then
        inst.AnimState:PlayAnimation("hit")
        inst.AnimState:PushAnimation("idle", false)
    end
end


local function OnKilled(inst)
    inst.AnimState:PlayAnimation("dead")

    RemovePhysicsColliders(inst)
end

local function nextAnimate(inst)
    if inst.AnimState:IsCurrentAnimation("idle") or inst.AnimState:IsCurrentAnimation("idle2") then
        if math.random() < 0.5 then
            inst.AnimState:PlayAnimation("idle2", false)
        else
            inst.AnimState:PlayAnimation("idle", false)
        end
    end

    if inst.AnimState:IsCurrentAnimation("dead") then
        inst:Remove()
    end
end

--------------------------------- 实例：墙壁 ---------------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    -- inst.Transform:SetEightFaced() -- 不需要这么多面

    MakeObstaclePhysics(inst, .5)
    inst.Physics:SetDontRemoveOnSleep(true)

    --inst.Transform:SetScale(1.3,1.3,1.3)

    inst:AddTag("wall")
    inst:AddTag("noauradamage")

    inst.AnimState:SetBank("aip_oldone_wall")
    inst.AnimState:SetBuild("aip_oldone_wall")
    inst.AnimState:PlayAnimation("idle", false)

    -- MakeSnowCoveredPristine(inst) -- 懒得做雪

    inst._pfpos = nil
    inst._ispathfinding = net_bool(inst.GUID, "_ispathfinding", "onispathfindingdirty")
    makeobstacle(inst)
    --Delay this because makeobstacle sets pathfinding on by default
    --but we don't to handle it until after our position is set
    inst:DoTaskInTime(0, InitializePathFinding)

    inst.OnRemoveEntity = onremove

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("lootdropper")

    inst:AddComponent("combat")
    inst.components.combat:SetKeepTargetFunction(keeptargetfn)
    inst.components.combat.onhitfn = onhit

    local maxHealth = dev_mode and 66 or TUNING.MOONROCKWALL_HEALTH
    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(maxHealth)
    inst.components.health:SetCurrentHealth(maxHealth)
    inst.components.health:StartRegen(5, 3)
    -- inst.components.health.ondelta = onhealthchange
    -- inst.components.health.nofadeout = true
    -- inst.components.health.canheal = false -- 可以治疗

    -- 可以点燃
    MakeSmallBurnableCharacter(inst, "body")
    MakeSmallPropagator(inst)

    MakeHauntableWork(inst)

    -- inst.OnLoad = onload

    -- MakeSnowCovered(inst) -- 懒得做雪

    inst:ListenForEvent("animover", nextAnimate)
    inst:ListenForEvent("death", OnKilled)

    return inst
end

return Prefab("aip_oldone_wall", fn, assets),
Prefab("aip_oldone_wall_item", itemfn, assets, { "aip_oldone_wall", "aip_oldone_wall_item_placer" }),
MakePlacer("aip_oldone_wall_item_placer", "aip_oldone_wall", "aip_oldone_wall", "idle", false, false, true)
