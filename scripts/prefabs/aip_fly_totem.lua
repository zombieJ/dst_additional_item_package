local dev_mode = aipGetModConfig("dev_mode") == "enabled"

-- 配置
local language = aipGetModConfig("language")

local LANG_MAP = {
	english = {
		NAME = "Fly Totem",
		RECDESC = "Unicom's flight site",
        DESC = "To Infinity... and Beyond",

        FAKE_NAME = "Inferior Fly Totem",
		FAKE_RECDESC = "Not an outstanding counterfeit ",
        FAKE_DESC = "Things that need to be recharged to activate",
        FAKE_NO_POWER = "Need recharge on the source",

        UNNAMED = "[UNNAMED]",
        CURRENT = "I'm already here!",
        INVLIDATE = "Target seems disappeared",
        IN_DANGER = "It's not safe time to travel!",
        CRAZY = "It's too crazy...",
	},
	chinese = {
		NAME = "飞行图腾",
		RECDESC = "联通的飞行站点",
        DESC = "飞向宇宙，浩瀚无垠！",

        FAKE_NAME = "劣质的飞行图腾",
		FAKE_RECDESC = "并不杰出的仿冒品",
        FAKE_DESC = "需要充能才能启动的玩意儿",
        FAKE_NO_POWER = "它的魔力来源已经消耗殆尽了",

        UNNAMED = "[未命名]",
        CURRENT = "我就在这里！",
        INVLIDATE = "目的地不见了",
        IN_DANGER = "这不是一个安全旅行的时机",
        CRAZY = "你觉得我还不够疯狂吗？",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

-- 文字描述
STRINGS.NAMES.AIP_FLY_TOTEM = LANG.NAME
STRINGS.RECIPE_DESC.AIP_FLY_TOTEM = LANG.RECDESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_FLY_TOTEM = LANG.DESC

STRINGS.NAMES.AIP_FAKE_FLY_TOTEM = LANG.FAKE_NAME
STRINGS.RECIPE_DESC.AIP_FAKE_FLY_TOTEM = LANG.FAKE_RECDESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_FAKE_FLY_TOTEM = LANG.FAKE_DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_FAKE_FLY_TOTEM_NO_POWER = LANG.FAKE_NO_POWER

STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_FLY_TOTEM_UNNAMED = LANG.UNNAMED
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_FLY_TOTEM_CURRENT = LANG.CURRENT
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_FLY_TOTEM_INVLIDATE = LANG.INVLIDATE
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_FLY_TOTEM_IN_DANGER = LANG.IN_DANGER
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_FLY_TOTEM_CRAZY = LANG.CRAZY

---------------------------------- 资源 ----------------------------------
require "prefabutil"

local assets = {
	Asset("ANIM", "anim/aip_fly_totem.zip"),
    Asset("ANIM", "anim/aip_fake_fly_totem.zip"),
	Asset("ATLAS", "images/inventoryimages/aip_fly_totem.xml"),
    Asset("ATLAS", "images/inventoryimages/aip_fake_fly_totem.xml"),
    Asset("ATLAS", "minimap/aip_fly_totem.xml"),
	Asset("IMAGE", "minimap/aip_fly_totem.tex"),
}

local prefabs = {
    "aip_shadow_wrapper",
    "aip_mini_doujiang",
}

---------------------------------- 事件 ----------------------------------
local function onhammered(inst, worker)
	if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
		inst.components.burnable:Extinguish()
	end
	inst.components.lootdropper:DropLoot()
	local fx = SpawnPrefab("collapse_small")
	fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
	fx:SetMaterial("wood")
	inst:Remove()
end

local function onhit(inst, worker)
	if not inst:HasTag("burnt") then
		inst.AnimState:PlayAnimation("hit")
		inst.AnimState:PushAnimation("idle", false)
	end
end

local function onbuilt(inst)
    inst.SoundEmitter:PlaySound("dontstarve/common/sign_craft")
end

local function onRemove(inst)
    aipTableRemove(aipCommonStore().flyTotems, inst)
end

local function canBeActOn(inst, doer)
	return not inst:HasTag("writeable")
end

-- 检查是否有燃料可以飞行
local function canFly()
    -- 测试模式下总是可以飞行
    if dev_mode then
        return true
    end

    local douTotem = aipCommonStore():FindDouTotem()

    -- 没有的话就不让飞行了
    if
        not douTotem or
        not douTotem.components.fueled or
        douTotem.components.fueled:IsEmpty()
    then
        return false
    end

    return true
end

local function onOpenPicker(inst, doer)
    -- 如果是假图腾就检查是否豆酱图腾由能量
    if inst.aipFake == true and aipCommonStore() then
        -- 没有的话就不让飞行了
        if not canFly() then
            if doer.components.talker then
                doer.components.talker:Say(
                    STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_FAKE_FLY_TOTEM_NO_POWER
                )
            end
            return
        end
    end

    -- 加一个切割前缀强制服务器触发
    doer.player_classified.aip_fly_picker:set(tostring(os.time()).."|"..inst.aipId)
end

--[[
markType 是用于豆酱图腾的标记，
表示为有图腾柱创造的实体
]]
local function onSave(inst, data)
	data.markType = inst.markType
    data.aipId = inst.aipId
end

local function onLoad(inst, data)
	if data ~= nil then
		inst.markType = data.markType
        inst.aipId = data.aipId
	end
end

---------------------------------- 燃料 ----------------------------------
local function ontakefuel(inst)
    if aipCommonStore() then
        local douTotem = aipCommonStore():FindDouTotem()

        -- 给链接图腾补充燃料
        if douTotem and douTotem.components.fueled then
            douTotem.components.fueled:DoDelta(5)
        end
    end
end

---------------------------------- 方法 ----------------------------------
-- 玩家靠近时创建一个小豆酱
local function onnear(inst, player)
    if inst.markType == "BALLOON" and inst._aipMiniDou == nil then
        local pos = aipGetSpawnPoint(inst:GetPosition(), 1)

        if pos ~= nil then
            inst._aipMiniDou = SpawnPrefab("aip_mini_doujiang")
            inst._aipMiniDou.Transform:SetPosition(pos.x, pos.y, pos.z)

            aipSpawnPrefab(inst, "aip_shadow_wrapper").DoShow()

            inst._aipMiniDou._aipTotem = inst
        end
    end
end

-- 传输范围玩家
local function startTranslate(inst, targetTotem)
    local pt = inst:GetPosition()
    local dist = 3
    local count = 20
    local scale = 0.2

    for i = 1, count do
        local angle = 2 * PI / count * i

        local effect = SpawnPrefab("aip_shadow_wrapper")
        effect.Transform:SetScale(scale, scale, scale)
        effect.DoShow()

        effect.Transform:SetPosition(
            pt.x + math.cos(angle) * dist, 0,
            pt.z + math.sin(angle) * dist
        )
    end

    -- 传送玩家
    local players = aipFindNearPlayers(inst, 3)

    for i, player in ipairs(players) do
        if player.components.aipc_flyer_sc ~= nil then
            player.components.aipc_flyer_sc:FlyTo(targetTotem)
        end
    end
end

-- 启动光环施法
local function startSpell(inst, targetTotem)
    inst:DoTaskInTime(.5, function()
        inst.SoundEmitter:PlaySound("dontstarve/forest/treeGrowFromWilt")
    end)

    local aura = aipSpawnPrefab(inst, "aip_aura_send")
    aura.OnRemoveEntity = function()
        startTranslate(inst, targetTotem)

        -- 如果是劣质图腾则消耗一下使用寿命
        if inst.aipFake == true and aipCommonStore() then
            local douTotem = aipCommonStore():FindDouTotem()

            if douTotem then -- 如果玩家 T 出来的，图腾其实不存在
                douTotem.components.fueled:DoDelta(-1, inst)
            end
        end
    end
end

-- 被粒子激活
local function onParticlesTrigger(inst)
    -- 没有燃料了，不能飞
    if inst.aipFake == true and not canFly() then
        return
    end

    local store = aipCommonStore()

    if store:MarkTotem() == nil then
        store:MarkTotem(inst)

    else -- 飞行吧
        if store:MarkTotem() ~= inst then
            startSpell(inst, store:MarkTotem())
            startSpell(store:MarkTotem(), inst)
        end

        -- 清理
        store:MarkTotem(false)
    end
end

---------------------------------- 实体 ----------------------------------
local function genTotem(buildName, fake)
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddMiniMapEntity()
        inst.MiniMapEntity:SetIcon("aip_fly_totem.tex")
        inst.MiniMapEntity:SetPriority(10)
        inst.entity:AddNetwork()

        MakeObstaclePhysics(inst, .2)

        inst.AnimState:SetBank(buildName)
        inst.AnimState:SetBuild(buildName)
        inst.AnimState:PlayAnimation("idle")

        MakeSnowCoveredPristine(inst)

        inst:AddTag("structure")
        inst:AddTag("aip_fly_totem")

        -- 添加粒子标记，使其可以被攻击
        inst:AddTag("aip_particles")

        --Sneak these into pristine state for optimization
        inst:AddTag("_writeable")

        -- 添加飞行图腾
        inst:AddComponent("aipc_action_client")
        inst.components.aipc_action_client.canBeActOn = canBeActOn

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        --Remove these tags so that they can be added properly when replicating components below
        inst:RemoveTag("_writeable")

        inst:AddComponent("aipc_action")
        inst.components.aipc_action.onDoAction = onOpenPicker

        inst:AddComponent("inspectable")
        inst:AddComponent("writeable")
        inst:AddComponent("lootdropper")

        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
        inst.components.workable:SetWorkLeft(4)
        inst.components.workable:SetOnFinishCallback(onhammered)
        inst.components.workable:SetOnWorkCallback(onhit)

        -- 可以被粒子触发
        inst._aip_particles_trigger = onParticlesTrigger

        -- 玩家靠近
        inst:AddComponent("playerprox")
        inst.components.playerprox:SetDist(10, 13)
        inst.components.playerprox:SetOnPlayerNear(onnear)

        -- 如果伪劣产品，我们可以充能
        if fake then
            inst:AddComponent("fueled")
            inst.components.fueled.accepting = true
            inst.components.fueled.fueltype = FUELTYPE.NIGHTMARE
            inst.components.fueled:SetTakeFuelFn(ontakefuel)
        end

        MakeSnowCovered(inst)

        MakeSmallBurnable(inst, TUNING.LARGE_BURNTIME)
        MakeSmallPropagator(inst)

        inst.aipId = tostring(os.time())..tostring(math.random())

        inst.aipStartSpell = startSpell
        inst.aipFake = fake

        inst.OnSave = onSave
        inst.OnLoad = onLoad

        MakeHauntableWork(inst)
        inst:ListenForEvent("onbuilt", onbuilt)

        -- 全局注册飞行图腾
        table.insert(aipCommonStore().flyTotems, inst)
        inst:ListenForEvent("onremove", onRemove)

        return inst
    end

    return fn
end

-------------------------------- 起飞特效 --------------------------------
local function effectFn()
    local inst = CreateEntity()
    local opacity = .5

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("lavaarena_attack_buff_effect")
    inst.AnimState:SetBuild("lavaarena_attack_buff_effect")
    inst.AnimState:PlayAnimation("in")
    inst.AnimState:SetMultColour(0, 0, 0, opacity)

    inst:AddTag("NOCLICK")
    inst:AddTag("FX")

    inst.entity:SetPristine()

    inst:DoPeriodicTask(0.1, function()
        opacity = math.max(opacity - 0.05, 0)
        inst.AnimState:SetMultColour(0, 0, 0, opacity)
    end)

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    inst:DoTaskInTime(.1, function()
        inst.SoundEmitter:PlaySound("dontstarve/maxwell/appear_adventure")
    end)

    inst:DoTaskInTime(1, inst.Remove)

    return inst
end

-------------------------------- 飞行特效 --------------------------------
local function flyEffectFn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeTinyFlyingCharacterPhysics(inst, 0, 0.2)

    inst.AnimState:SetBank("aip_fly_totem_effect")
    inst.AnimState:SetBuild("aip_fly_totem_effect")
    inst.AnimState:PlayAnimation("disappear")

    inst:AddTag("NOCLICK")
    inst:AddTag("FX")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    inst:ListenForEvent("animover", inst.Remove)

    return inst
end


return Prefab("aip_fly_totem", genTotem("aip_fly_totem"), assets, prefabs),
        MakePlacer("aip_fly_totem_placer", "aip_fly_totem", "aip_fly_totem", "idle"),
        Prefab("aip_fake_fly_totem", genTotem("aip_fake_fly_totem", true), assets, prefabs),
        MakePlacer("aip_fake_fly_totem_placer", "aip_fake_fly_totem", "aip_fake_fly_totem", "idle"),
        Prefab("aip_eagle_effect", effectFn, { Asset("ANIM", "anim/lavaarena_attack_buff_effect.zip") }),
        Prefab("aip_fly_totem_effect", flyEffectFn, { Asset("ANIM", "anim/aip_fly_totem_effect.zip") })
