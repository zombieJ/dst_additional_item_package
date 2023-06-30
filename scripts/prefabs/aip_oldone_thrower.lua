local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Owl",
		DESC = "Test my memory?",
        READY = "Are you ready?",
        MOST = "Which color is the most?",
        LESS = "Which color is the least?",

        PICK_NAME = "Stone Pillar",
        CHOOSE = "Choose this color",
        YES = "Correct! See you tomorrow~",
        NO = "Wrong! See you tomorrow~",
        TOO_LONG = "Too long! See you tomorrow~",
	},
	chinese = {
		NAME = "傅达",
		DESC = "考验记忆力呢？",
        READY = "准备好了吗？",
        MOST = "数数哪个颜色最多？",
        LESS = "数数哪个颜色最少？",

        PICK_NAME = "石柱",
        CHOOSE = "选择这个颜色",
        YES = "答对了！明天见~",
        NO = "答错了！明天见~",
        TOO_LONG = "太久了！明天见~",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_OLDONE_THROWER = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_THROWER = LANG.DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_THROWER_READY = LANG.READY
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_THROWER_MOST = LANG.MOST
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_THROWER_LESS = LANG.LESS
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_THROWER_CHOOSE = LANG.CHOOSE

STRINGS.NAMES.AIP_OLDONE_THROWER_PICK_RED = LANG.PICK_NAME
STRINGS.NAMES.AIP_OLDONE_THROWER_PICK_BLUE = LANG.PICK_NAME
STRINGS.NAMES.AIP_OLDONE_THROWER_PICK_GREEN = LANG.PICK_NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_THROWER_PICK_RED = LANG.CHOOSE
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_THROWER_PICK_BLUE = LANG.CHOOSE
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_THROWER_PICK_GREEN = LANG.CHOOSE
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_THROWER_YES = LANG.YES
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_THROWER_NO = LANG.NO
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_THROWER_TOO_LONG = LANG.TOO_LONG

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_oldone_thrower.zip"),
}

------------------------------------ 方法 ------------------------------------
-- 可以拆毁
local function onhammered(inst, worker)
    local fx = aipReplacePrefab(inst, "collapse_small")
    fx:SetMaterial("stone")
end

-- 每天白天重置一下激活状态
local function OnIsDay(inst, isday)
    if isday then
        inst.components.activatable.inactive = true
    end
end

-- 点击激活点
local function toggleActive(inst, doer)
    if inst == nil then
        return
    end

    local isMost = math.random() > 0.5
    local colors = { "red", "green", "blue" }
    local throwed = {
        red = 0,
        green = 0,
        blue = 0,
    }
    local pickList = {}

    local pt = inst:GetPosition()

    -- 召唤小球游戏
    inst.components.talker:Say(
        STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_THROWER_READY
    )

    inst:DoTaskInTime(2, function()-- 开始！
        inst.components.talker:Say(
            isMost and
            STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_THROWER_MOST or
            STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_THROWER_LESS
        )

        local total = 10
        local dist = 3.5

        for i = 1, total do
            local rndColor = aipRandomEnt(colors)
            throwed[rndColor] = throwed[rndColor] + 1

            inst:DoTaskInTime(i * 0.3, function()
                local angle = (i / 10) * _G.PI * 2
                local tgtX = pt.x + math.cos(angle) * dist
                local tgtZ = pt.z + math.sin(angle) * dist

                local stone = aipSpawnPrefab(inst, "aip_oldone_thrower_stone_"..rndColor,
                    tgtX, pt.y, tgtZ
                )

                aipSpawnPrefab(stone, "aip_shadow_wrapper").DoShow(0.6)
            end, 0)
        end
    end)

    inst:DoTaskInTime(8, function()-- 出现选择器
        local dist = 3

        for i = 1, #colors do
            local color = colors[i]
            local angle = (i / #colors) * _G.PI * 2
            local tgtX = pt.x + math.cos(angle) * dist
            local tgtZ = pt.z + math.sin(angle) * dist

            local pick = aipSpawnPrefab(inst, "aip_oldone_thrower_pick_"..color,
                tgtX, pt.y, tgtZ
            )
            aipSpawnPrefab(pick, "aip_shadow_wrapper").DoShow()

            -- 选择
            table.insert(pickList, pick)

            pick.components.activatable.OnActivate = function()
                -- 计算是否是最多/最少的
                local max = -1
                local min = 999

                local dropList = {}

                for color, count in pairs(throwed) do
                    if count > max then
                        max = count
                    end

                    if count < min then
                        min = count
                    end
                end

                -- 对话啦
                if
                    (isMost and throwed[color] == max) or
                    (not isMost and throwed[color] == min)
                then
                    -- 答对了
                    inst.components.talker:Say(
                        STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_THROWER_YES
                    )

                    dropList = {
                        goldnugget = 99,        -- 金块
                        redgem = 1,             -- 红宝石
                        bluegem = 1,            -- 蓝宝石
                    }
                else
                    -- 答错了
                    inst.components.talker:Say(
                        STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_THROWER_NO
                    )

                    dropList = {
                        aip_leaf_note = 2,      -- 树叶笔记
                        foliage = 1,            -- 蕨叶
                        cutgrass = 1,           -- 草
                        kelp = 1,               -- 海带
                    }
                end

                -- 移除选择器
                for i, pick in ipairs(pickList) do
                    local prefab = aipRandomLoot(dropList)
                    aipSpawnPrefab(pick, prefab)
                    aipReplacePrefab(pick, "aip_shadow_wrapper").DoShow()
                end
                pickList = {}
            end
        end

        -- 超过 5 秒就告别
        inst:DoTaskInTime(5, function()
            for i, pick in ipairs(pickList) do
                aipReplacePrefab(pick, "aip_shadow_wrapper").DoShow()
            end
            pickList = {}

            inst.components.talker:Say(
                STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_THROWER_TOO_LONG
            )
        end)
    end)
end

------------------------------------ 实例 ------------------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, .2)

    inst.AnimState:SetBank("aip_oldone_thrower")
    inst.AnimState:SetBuild("aip_oldone_thrower")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("structure")
    inst:AddTag("aip_world_drop")

    inst.entity:SetPristine()

    inst:AddComponent("talker")
    inst.components.talker.fontsize = 30
    inst.components.talker.font = TALKINGFONT
    inst.components.talker.colour = Vector3(.9, 1, .9)
    inst.components.talker.offset = Vector3(0, -400, 0)

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("activatable")
	inst.components.activatable.OnActivate = toggleActive
    inst.components.activatable.quickaction = true

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnFinishCallback(onhammered)

    inst:AddComponent("inspectable")

    inst:WatchWorldState("isday", OnIsDay)

    MakeHauntableLaunch(inst)

    return inst
end

------------------------------------ 石头 ------------------------------------
local function stoneCommon(name)
    local function stoneFn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)

        inst.AnimState:SetBank("aip_oldone_thrower")
        inst.AnimState:SetBuild("aip_oldone_thrower")
        inst.AnimState:PlayAnimation(name)

        inst:AddTag("NOCLICK")
        inst:AddTag("fx")

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:DoTaskInTime(2.5, function()
            aipReplacePrefab(inst, "aip_shadow_wrapper").DoShow(0.6)
        end)

        inst.persists = false

        return inst
    end

    return stoneFn
end

----------------------------------- 选择器 -----------------------------------
local function pickCommon(name)
    local function fnPick()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)

        inst.AnimState:SetBank("aip_oldone_thrower")
        inst.AnimState:SetBuild("aip_oldone_thrower")
        inst.AnimState:PlayAnimation("pick_"..name)

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("activatable")
        inst.components.activatable.quickaction = true

        inst.persists = false

        return inst
    end

    return fnPick
end


return Prefab("aip_oldone_thrower", fn, assets),

        Prefab("aip_oldone_thrower_stone_red", stoneCommon("red"), assets),
        Prefab("aip_oldone_thrower_stone_blue", stoneCommon("blue"), assets),
        Prefab("aip_oldone_thrower_stone_green", stoneCommon("green"), assets),

        Prefab("aip_oldone_thrower_pick_red", pickCommon("red"), assets),
        Prefab("aip_oldone_thrower_pick_blue", pickCommon("blue"), assets),
        Prefab("aip_oldone_thrower_pick_green", pickCommon("green"), assets)
