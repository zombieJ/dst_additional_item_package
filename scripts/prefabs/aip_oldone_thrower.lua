local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Owl",
		DESC = "Where is the puzzle?",
        READY = "Are you ready?",
        MOST = "Which color is the most?",
        LESS = "Which color is the least?",
	},
	chinese = {
		NAME = "傅达",
		DESC = "谜团在哪里呢？",
        READY = "准备好了吗？",
        MOST = "数数哪个颜色最多？",
        LESS = "数数哪个颜色最少？",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_OLDONE_THROWER = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_THROWER = LANG.DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_THROWER_READY = LANG.READY
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_THROWER_MOST = LANG.MOST
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_THROWER_LESS = LANG.LESS

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

    -- 召唤小球游戏
    inst.components.talker:Say(
        STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_THROWER_READY
    )

    local isMost = math.random() > 0.5

    inst:DoTaskInTime(2, function()-- 开始！
        inst.components.talker:Say(
            isMost and
            STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_THROWER_MOST or
            STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_THROWER_LESS
        )

        local colors = { "red", "green", "blue" }
        local throwed = {
            red = 0,
            green = 0,
            blue = 0,
        }

        local pt = inst:GetPosition()
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
    local function fn()
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

        inst:DoTaskInTime(3, function()
            aipReplacePrefab(inst, "aip_shadow_wrapper").DoShow(0.6)
        end)

        inst.persists = false

        return inst
    end

    return fn
end


return Prefab("aip_oldone_thrower", fn, assets),
        Prefab("aip_oldone_thrower_stone_red", stoneCommon("red"), assets),
        Prefab("aip_oldone_thrower_stone_blue", stoneCommon("blue"), assets),
        Prefab("aip_oldone_thrower_stone_green", stoneCommon("green"), assets)
