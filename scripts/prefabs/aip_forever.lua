local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Forewell",
		DESC = "Vibrant things",
	},
	chinese = {
		NAME = "永恒之井",
		DESC = "生机勃勃之物",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_FOREVER = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_FOREVER = LANG.DESC

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_forever.zip"),
}

------------------------------------ 方法 ------------------------------------
-- 只允许 花瓣 和 恶魔花瓣
local function canBeGiveOn(inst, doer, item)
    return aipInTable({"petals", "petals_evil"}, item.prefab)
end

-- 生成花朵
local function genFlower(inst, prefab)
    local x, y, z = inst.Transform:GetWorldPosition()
    prefab = prefab or aipRandomEnt({"planted_flower","flower_evil"})

    -- 随机层级找一个点
    local d = math.random(1, 3)
    local dist = d * 2 + 1
    local count = 4 + d * 3
    local startI = math.random(1, count)

    for i = 1, count do
        local angle = (i + startI) / count * 2 * PI + PI / 4 * d
        local tgtX = x + math.cos(angle) * dist
        local tgtZ = z + math.sin(angle) * dist

        -- 海里不会生长
        if TheWorld.Map:IsAboveGroundAtPoint(tgtX, 0, tgtZ) then
            local ents = TheSim:FindEntities(tgtX, 0, tgtZ, 0.5)

            if #ents == 0 then
                local flower = aipSpawnPrefab(nil, prefab, tgtX, 0, tgtZ)
                aipSpawnPrefab(flower, "aip_shadow_wrapper").DoShow()
                return flower
            end
        end
    end
end

local function tryGenFlower(inst, prefab)
    -- 循环 5 次找到可以种花的地点
    for i = 1, 5 do
        if genFlower(inst, prefab) then
            return
        end
    end

    aipSpawnPrefab(
        aipSpawnPrefab(inst, "butterfly"), "aip_shadow_wrapper"
    ).DoShow()
end

-- 获得花瓣
local function onDoGiveAction(inst, doer, item)
    tryGenFlower(inst, item.prefab == "petals_evil" and "flower_evil" or "planted_flower")
    aipRemove(item)
end

local function onhammered(inst, worker)
    local fx = aipReplacePrefab(inst, "collapse_small")
    fx:SetMaterial("wood")
end

------------------------------------ 实例 ------------------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, .2)

    inst.AnimState:SetBank("aip_forever")
    inst.AnimState:SetBuild("aip_forever")
    inst.AnimState:PlayAnimation("idle", true)

    inst:AddTag("structure")
    inst:AddTag("aip_world_drop")

    inst.entity:SetPristine()

    inst:AddComponent("aipc_action_client")
    inst.components.aipc_action_client.canBeGiveOn = canBeGiveOn

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("aipc_action")
    inst.components.aipc_action.onDoGiveAction = onDoGiveAction

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnFinishCallback(onhammered)

    inst:AddComponent("inspectable")

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("aip_forever", fn, assets)
