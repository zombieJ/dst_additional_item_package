local dev_mode = aipGetModConfig("dev_mode") == "enabled"

local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Wispy",
		DESC = "Can I catch you?",
	},
	chinese = {
		NAME = "鬼火",
		DESC = "我能抓到你吗？",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_GRAVEYARD_WISP = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_GRAVEYARD_WISP = LANG.DESC

-- 资源
local assets = {}

------------------------------------- 方法 -------------------------------------
local function onworked(inst, worker)
    if worker.components.inventory ~= nil then
        worker.components.inventory:GiveItem(aipReplacePrefab(inst, "nightmarefuel"))
        worker.SoundEmitter:PlaySound("dontstarve/common/butterfly_trap")
    end
end

local function randomNextPos(inst)
    if inst._home == nil or not inst._home:IsValid() then
        -- 开发模式则找一个玩家来环绕
        if dev_mode then
            local players = aipFindNearPlayers(inst, 20)
            inst._home = players[1]
            inst:DoTaskInTime(1, randomNextPos)
        end

        return
    end

    -- 对墓碑进行随机移动
    local oriPT = inst._home:GetPosition()
    local distance = 5
    local angle = math.random() * 360

    local tgtPT = aipAngleDist(oriPT, angle, distance)

    inst.components.aipc_float:MoveToPoint(tgtPT)

    -- 下一个随机时间点
    local nextTime = math.random() * 3 + 3
    inst:DoTaskInTime(nextTime, randomNextPos)
end

------------------------------------- 实例 -------------------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    MakeProjectilePhysics(inst, 1, .25)

    inst.AnimState:SetBank("coldfire_fire")
    inst.AnimState:SetBuild("coldfire_fire")
    inst.AnimState:PlayAnimation("level1", true)
    inst.AnimState:OverrideMultColour(1, .6, 1, 1)

    inst.Light:SetColour(111/255, 111/255, 227/255)
    inst.Light:SetIntensity(0.75)
    inst.Light:SetFalloff(0.5)
    inst.Light:SetRadius(2)
    inst.Light:Enable(true)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("knownlocations")

    inst:AddComponent("aipc_float")
    inst.components.aipc_float.speed = 0.5

    -- inst:AddComponent("inventoryitem")
    -- inst.components.inventoryitem.canbepickedup = false

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.NET)
    inst.components.workable:SetWorkLeft(1)
    inst.components.workable:SetOnFinishCallback(onworked)

    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(TUNING.SEG_TIME * 3)
    inst.components.perishable:StartPerishing()
    inst.components.perishable:SetOnPerishFn(inst.Remove)

    randomNextPos(inst)

    inst.persists = false

    -- 白天消失
    inst:WatchWorldState("isnight", function(_, isnight)
        if not isnight then
            inst:Remove()
        end
    end)

    return inst
end

return Prefab("aip_graveyard_wisp", fn, assets)
