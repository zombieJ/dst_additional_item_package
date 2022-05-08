local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Ocean Lotus Leaf",
		DESC = "Try to flint in it",
	},
	chinese = {
		NAME = "海荷叶",
		DESC = "试试打水漂打进去吧",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_OLDONE_LOTUS_LEAF = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_LOTUS_LEAF = LANG.DESC

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_oldone_lotus_leaf.zip"),
}

------------------------------ 事件 --------------------------------
local DIST = 2

-- 初始化矩阵
local function initMatrix(inst)
    if inst._aipMaster ~= nil then
        return
    end

    local pt = inst:GetPosition()

    -- 强行移动到海里
    local oceanPT = aipFindNearbyOcean(pt, 10)
    if oceanPT ~= nil then
        -- 转一圈，找到最远的点

        inst.Transform:SetPosition(oceanPT:Get())
        pt = oceanPT
    end

    -- 初始化一圈矩阵
    inst._aipStones = {}

    local min = 6
    local max = 8
    local count = math.random(min, max)

    for i = 1, count do
        local angle = PI * 2 * i / count

        local stone = aipSpawnPrefab(
            nil, "aip_oldone_lotus_leaf",
            pt.x + math.cos(angle) * DIST,
            pt.y,
            pt.z + math.sin(angle) * DIST
        )

        stone._aipMaster = inst

        table.insert(inst._aipStones, stone)
    end
end

local function OnRemoveEntity(inst)
    if inst._aipStones ~= nil then
        for i, stone in ipairs(inst._aipStones) do
            aipReplacePrefab(stone, "aip_shadow_wrapper").DoShow(0.6)
        end
    end
end

local function checkDrift(inst, drift, doer)
    if inst == nil or drift == nil then
        return
    end

    -- 如果在范围内，给予谜团因子
    local dist = aipDist(inst:GetPosition(), drift:GetPosition())
    if dist <= DIST then
        if doer ~= nil and doer.components.aipc_oldone ~= nil then
            doer.components.aipc_oldone:DoDelta()
        end

        aipRemove(inst)
    end
end

------------------------------ 马甲 --------------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    MakeInventoryFloatable(inst, "small", 0.2, 0.80)

    inst:AddTag("aip_olden_flower")
    inst:AddTag("ignorewalkableplatforms")
    inst:AddTag("NOBLOCK")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:DoTaskInTime(0.1, initMatrix)

    inst._aipCheckDrift = checkDrift

    inst.persists = false

    inst.OnRemoveEntity = OnRemoveEntity

    return inst
end

------------------------------ 叶片 --------------------------------
local function postLeaf(inst)
    local color = .7 + math.random() * .3
    inst.AnimState:SetMultColour(color, color, color, 1)

    local angle = 360 * math.random()
    inst.Transform:SetRotation(angle)

    inst.AnimState:SetTime(math.random() * inst.AnimState:GetCurrentAnimationLength())
end

local function entFn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("aip_oldone_lotus_leaf")
    inst.AnimState:SetBuild("aip_oldone_lotus_leaf")
    inst.AnimState:PlayAnimation("idle", true)

    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(ANIM_SORT_ORDER.OCEAN_WAVES)

    inst:AddTag("aip_olden_flower")
    inst:AddTag("ignorewalkableplatforms")
    inst:AddTag("NOBLOCK")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.canbepickedup = false
    inst.components.inventoryitem.canbepickedupalive = false

    inst.persists = false

    inst:DoTaskInTime(0.001, postLeaf)

    return inst
end

return Prefab("aip_oldone_lotus", fn, assets), Prefab("aip_oldone_lotus_leaf", entFn, assets)
