-- 配置
local language = aipGetModConfig("language")

local additional_survival = aipGetModConfig("additional_survival") == "open"

local LANG_MAP = {
	english = {
        BROEKN_NAME = "Wreckage",
        BROEKN_DESC = "Maybe we can fix this",
        POWERLESS_NAME = "Powerless Totem",
        POWERLESS_DESC = "Just one last dance!",
		NAME = "IOT Totem",
		DESC = "Seems magic somewhere",
        TALK_WELCOME = "Are you ready?",
        TALK_FIRST = "Start your challenge",
        TOTEM_POS = "First Place",
        TOTEM_BALLOON = "Ruo Guang",
        TOTEM_SNAKE = "", -- 抓捕玩具蛇
	},
	chinese = {
        BROEKN_NAME = "一片残骸",
        BROEKN_DESC = "看起来可以修复它",
        POWERLESS_NAME = "失能的图腾",
        POWERLESS_DESC = "还差最后一步！",
		NAME = "联结图腾",
        DESC = "有一丝魔法气息",
        TALK_WELCOME = "想得到我的秘密，你做好准备了吗？",
        TALK_FIRST = "开始你的挑战！",
        TOTEM_POS = "伊始之地",
        TOTEM_BALLOON = "若光小驻",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

-- 文字描述
STRINGS.NAMES.AIP_DOU_TOTEM_BROKEN = LANG.BROEKN_NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_DOU_TOTEM_BROKEN = LANG.BROEKN_DESC
STRINGS.NAMES.AIP_DOU_TOTEM_POWERLESS = LANG.POWERLESS_NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_DOU_TOTEM_POWERLESS = LANG.POWERLESS_DESC
STRINGS.NAMES.AIP_DOU_TOTEM = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_DOU_TOTEM = LANG.DESC
STRINGS.AIP_DOU_TOTEM_TALK_WELCOME = LANG.TALK_WELCOME
STRINGS.AIP_DOU_TOTEM_TALK_FIRST = LANG.TALK_FIRST

---------------------------------- 资源 ----------------------------------
local assets = {
	Asset("ANIM", "anim/aip_dou_totem.zip"),
    Asset("ATLAS", "minimap/aip_dou_totem.xml"),
	Asset("IMAGE", "minimap/aip_dou_totem.tex"),
}

local prefabs = {
    "aip_dou_tooth",
}

---------------------------------- 配方 ----------------------------------
CONSTRUCTION_PLANS["aip_dou_totem_broken"] = {
    Ingredient("moonrocknugget", 10),
    Ingredient("phlegm", 1),
    Ingredient("moonglass", 5),
}

-- 没有开启额外生命物品时不启用血包配方
local aip_dou_totem_powerless_plans = {
    Ingredient("boneshard", 1),
    Ingredient("monstermeat", 1),
}

if additional_survival then
    table.insert(
        aip_dou_totem_powerless_plans,
        Ingredient("aip_blood_package", 1, "images/inventoryimages/aip_blood_package.xml")
    )
end

CONSTRUCTION_PLANS["aip_dou_totem_powerless"] = aip_dou_totem_powerless_plans

---------------------------------- 事件 ----------------------------------
local function createFlyTotem(pt, name, markType)
    local flyTotem = aipSpawnPrefab(nil, "aip_fly_totem", pt.x, pt.y, pt.z)
    aipSpawnPrefab(flyTotem, "collapse_small")
    flyTotem.components.writeable:SetText(name)
    flyTotem.markType = markType
end

local function createFlyTotems(inst)
    local startTotem = false
    local balloonTotem = false

    for i, totem in ipairs(TheWorld.components.world_common_store.flyTotems) do
        if totem.markType == "START" then
            startTotem = true
        elseif totem.markType == "BALLOON" then
            balloonTotem = true
        end
    end

    -- 创建起点
    if startTotem == false then
        createFlyTotem(
            aipGetSecretSpawnPoint(inst:GetPosition(), 2, 5, 5),
            LANG.TOTEM_POS,
            "START"
        )
    end

    -- 创造猪王附近的图腾
    if balloonTotem == false then
        local pigking = aipFindEnt("pigking")
        if pigking then
            createFlyTotem(
                aipGetSecretSpawnPoint(pigking:GetPosition(), 50, 100, 5),
                LANG.TOTEM_BALLOON,
                "BALLOON"
            )
        end
    end
end

-- 创建挑战点
local function createChallenge()
    aipGetTopologyPoint("lunacyarea", "moon_fissure")
end

---------------------------------- 实体 ----------------------------------
local function makeTotemFn(name, animation, nextPrefab, nextPrefabAnimation)
    -- 建筑到下一个级别
    local function OnConstructed(inst, doer)
        local concluded = true
        for i, v in ipairs(CONSTRUCTION_PLANS[inst.prefab] or {}) do
            if inst.components.constructionsite:GetMaterialCount(v.type) < v.amount then
                concluded = false
                break
            end
        end
    
        if concluded then -- 满足建造条件
            aipSpawnPrefab(inst, "collapse_big")
            local next = ReplacePrefab(inst, nextPrefab)

            -- 如果设定了动画，说明有 _pre 动画，播放之
            if nextPrefabAnimation ~= nil then
                next.AnimState:PlayAnimation(nextPrefabAnimation.."_pre")
                next.AnimState:PushAnimation(nextPrefabAnimation, true)
            end

            -- 最后一节阶段会开始说话
            if next.components.talker ~= nil then
                -- 第一句话
                next:DoTaskInTime(0.5, function()
                    next.components.talker:Say(STRINGS.AIP_DOU_TOTEM_TALK_WELCOME)
                end)

                -- 第二句话
                next:DoTaskInTime(5, function()
                    next.components.talker:Say(STRINGS.AIP_DOU_TOTEM_TALK_FIRST)
                end)
            end
        end
    end

    -- 触发函数
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddMiniMapEntity()
        inst.entity:AddNetwork()

        MakeObstaclePhysics(inst, .2)

        inst.MiniMapEntity:SetIcon("aip_dou_totem.tex")
        inst.MiniMapEntity:SetPriority(10)

        inst.AnimState:SetBank("aip_dou_totem")
        inst.AnimState:SetBuild("aip_dou_totem")
        inst.AnimState:PlayAnimation(animation, true)

        inst:AddTag("structure")

        -- 最后一个级别做额外事情
        if nextPrefab == nil then
            -- 会添加对话能力
            inst:AddComponent("talker")
            inst.components.talker.fontsize = 30
            inst.components.talker.font = TALKINGFONT
            inst.components.talker.colour = Vector3(.9, 1, .9)
            inst.components.talker.offset = Vector3(0, -500, 0)
        end

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("inspectable")

        if nextPrefab ~= nil then
            inst:AddComponent("constructionsite")
            inst.components.constructionsite:SetConstructionPrefab("construction_container")
            inst.components.constructionsite:SetOnConstructedFn(OnConstructed)
        else
            -- 5s 后会检查附近有没有图腾，并且创造一个
            inst:DoTaskInTime(3, createFlyTotems)
        end

        MakeSnowCovered(inst)

        MakeHauntableWork(inst)

        return inst
    end

    return Prefab(name, fn, assets, prefabs)
end

return makeTotemFn("aip_dou_totem_broken", "broken", "aip_dou_totem_powerless"),
    makeTotemFn("aip_dou_totem_powerless", "powerless", "aip_dou_totem", "idle"),
    makeTotemFn("aip_dou_totem", "idle")
