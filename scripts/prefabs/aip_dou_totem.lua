-- 配置
local language = aipGetModConfig("language")

local LANG_MAP = {
	english = {
        BROEKN_NAME = "Wreckage",
        BROEKN_DESC = "Maybe we can fix this",
        POWERLESS_NAME = "Powerless Totem",
        POWERLESS_DESC = "Just one last dance!",
		NAME = "Dou Jiang Totem",
		DESC = "Seems magic somewhere",
        TALK_WELCOME = "Are you ready?",
        TALK_FIRST = "Your first challenge",
	},
	chinese = {
        BROEKN_NAME = "一片残骸",
        BROEKN_DESC = "看起来可以修复它",
        POWERLESS_NAME = "失能的图腾",
        POWERLESS_DESC = "还差最后一步！",
		NAME = "豆酱图腾",
        DESC = "有一丝魔法气息",
        TALK_WELCOME = "想得到我的秘密，你做好准备了吗？",
        TALK_FIRST = "第一个挑战！",
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

CONSTRUCTION_PLANS["aip_dou_totem_powerless"] = {
    Ingredient("boneshard", 1),
    Ingredient("monstermeat", 1),
    Ingredient("aip_blood_package", 1, "images/inventoryimages/aip_blood_package.xml"),
}

---------------------------------- 事件 ----------------------------------


---------------------------------- 实体 ----------------------------------
local function makeTotemFn(name, animation, nextPrefab)
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
        -- inst.entity:AddMiniMapEntity()
        inst.entity:AddNetwork()

        MakeObstaclePhysics(inst, .2)

        -- inst.MiniMapEntity:SetIcon("sign.png")

        inst.AnimState:SetBank("aip_dou_totem")
        inst.AnimState:SetBuild("aip_dou_totem")
        inst.AnimState:PlayAnimation(animation, true)

        inst:AddTag("structure")

        -- 最后一个级别会添加对话能力
        if nextPrefab == nil then
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
        end

        MakeSnowCovered(inst)

        MakeHauntableWork(inst)

        return inst
    end

    return Prefab(name, fn, assets, prefabs)
end

return makeTotemFn("aip_dou_totem_broken", "broken", "aip_dou_totem_powerless"),
    makeTotemFn("aip_dou_totem_powerless", "powerless", "aip_dou_totem"),
    makeTotemFn("aip_dou_totem", "idle")

--[[




c_give"aip_dou_totem_broken"



c_give("moonrocknugget", 10)
c_give("phlegm", 1)
c_give("moonglass", 5)



c_give"aip_dou_totem_powerless"


c_give("boneshard", 1)
c_give("monstermeat", 1)
c_give("aip_blood_package", 1)


]]