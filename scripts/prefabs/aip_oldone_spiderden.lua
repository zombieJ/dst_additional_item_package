local dev_mode = aipGetModConfig("dev_mode") == "enabled"
local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Parasitic Spider Den",
		DESC = "Seems a big difference inside",
	},
	chinese = {
		NAME = "寄生蜘蛛巢",
		DESC = "内部结果似乎已经大不一样了",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_OLDONE_SPIDERDEN = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_SPIDERDEN = LANG.DESC

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_oldone_spiderden.zip"),
}


----------------------------------- 事件 -----------------------------------
local function updateCreep(inst)
    if inst:GetCurrentPlatform() == nil then
        inst.GroundCreepEntity:SetRadius(5)
    end
end

local function OnHit(inst)
    inst.AnimState:PlayAnimation("hit")
end

local function OnKilled(inst)
    inst.AnimState:PlayAnimation("dead")
    if inst.components.childspawner ~= nil then
        inst.components.childspawner:ReleaseAllChildren()
    end
    RemovePhysicsColliders(inst)

    inst.SoundEmitter:PlaySound("dontstarve/creatures/spider/spiderLair_destroy")
    inst.components.lootdropper:DropLoot(inst:GetPosition())
end

-- 扔毒药给攻击者，需要按照队列延迟才行
local function onGoHome(inst, child)
    local attacker = child._aipAttacker
    if attacker ~= nil and attacker:IsValid() then
        local ball = aipSpawnPrefab(inst, "aip_oldone_plant_full")
        ball.components.complexprojectile:Launch(attacker:GetPosition(), inst)
    end
end

----------------------------------- 实体 -----------------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:AddSoundEmitter()
    inst.entity:AddGroundCreepEntity()

    inst:AddTag("hostile")
    inst:AddTag("aip_oldone")

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("aip_oldone_spiderden")
    inst.AnimState:SetBuild("aip_oldone_spiderden")
    inst.AnimState:PlayAnimation("idle", true)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("childspawner")
    inst.components.childspawner.childname = "aip_oldone_rabbit"
    inst.components.childspawner:SetRegenPeriod(dev_mode and 1 or TUNING.SPIDERDEN_REGEN_TIME)
    inst.components.childspawner:SetSpawnPeriod(dev_mode and 1 or TUNING.SPIDERDEN_RELEASE_TIME)
    inst.components.childspawner:SetMaxChildren(3)
    inst.components.childspawner.allowboats = true
    inst.components.childspawner.childreninside = 3
    inst.components.childspawner:StartSpawning()
    inst.components.childspawner:StartRegen()
    inst.components.childspawner:SetGoHomeFn(onGoHome)

    inst:AddComponent("inspectable")

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:AddChanceLoot("plantmeat", 1)
    inst.components.lootdropper:AddChanceLoot("monstermeat", 1)

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(dev_mode and 66 or 666)

    inst:AddComponent("combat")
    inst.components.combat:SetOnHit(OnHit)
    inst:ListenForEvent("death", OnKilled)

    MakeHauntableLaunch(inst)
    MakeMediumPropagator(inst)

    inst:DoTaskInTime(0, updateCreep)

    -- 测试模式直接释放蜘蛛
    if dev_mode then
        inst:DoTaskInTime(0, function()
            inst.components.childspawner:ReleaseAllChildren()
        end)
    end

    return inst
end

return Prefab("aip_oldone_spiderden", fn, assets)
