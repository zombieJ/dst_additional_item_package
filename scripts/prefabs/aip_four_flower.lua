local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Olden Flower",
		DESC = "It must be beautiful if all bloom",
	},
	chinese = {
		NAME = "古早花",
		DESC = "当它们全部盛开的时候一定很美",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_FOUR_FLOWER = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_FOUR_FLOWER = LANG.DESC

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_four_flower.zip"),
}

------------------------------ 方法 --------------------------------
local function syncAnim(inst)
    if inst._aipOpen then
        inst.AnimState:PlayAnimation("open")
    else
        inst.AnimState:PlayAnimation("bud")
    end
end

-- 点击激活点
local function toggleActive(inst, doer)
    if inst == nil then
        return
    end

    local cx = inst._aipX
    local cz = inst._aipZ

    if
        inst._aipMaster ~= nil and inst._aipMaster._aipMatrix ~= nil and
        cx ~= nil and cz ~= nil
    then
        local function inverse(x, z)
            local zs = inst._aipMaster._aipMatrix[x]
            if zs ~= nil and zs[z] ~= nil then
                zs[z]._aipOpen = not zs[z]._aipOpen
                zs[z].components.activatable.inactive = true -- 总是重置
                syncAnim(zs[z])
            end
        end

        inverse(cx, cz)
        inverse(cx - 1, cz)
        inverse(cx, cz - 1)
        inverse(cx + 1, cz)
        inverse(cx, cz + 1)

        -- 提交验证结果，如果不存在可能是当前花朵正在初始化
        if inst._aipMaster._aipFlush ~= nil then
            inst._aipMaster:_aipFlush(inst, doer)
        end
    end

	return true
end

-- 计算花朵数量
local function countOpen(inst, open)
    local cnt = 0

    local matrix = inst._aipMatrix
    local size = inst._aipSize

    if matrix ~= nil and size ~= nil then
        for x = 1, size do
            for z = 1, size do
                local flower = matrix[x][z]
                if flower ~= nil and flower._aipOpen == open then
                    cnt = cnt + 1
                end
            end
        end
    end

    return cnt
end

-- 检测免疫结果
local function flushResult(inst, doer)
    if countOpen(inst, false) == 0 then
        -- 增加一点模因因子
        if doer ~= nil and doer.components.aipc_oldone ~= nil then
            doer.components.aipc_oldone:DoDelta(2)
        end

        -- 不再可点击
        local matrix = inst._aipMatrix
        local size = inst._aipSize

        if matrix ~= nil and size ~= nil then
            for x = 1, size do
                for z = 1, size do
                    local flower = matrix[x][z]
                    if flower ~= nil and flower.components.activatable ~= nil then
                        flower.components.activatable.inactive = false
                    end
                end
            end
        end

        inst:DoTaskInTime(1, function()
            aipReplacePrefab(inst, "aip_shadow_wrapper").DoShow(2)
        end)
    end
end

-- 初始化矩阵
local function initMatrix(inst)
    if inst._aipMaster ~= nil then
        syncAnim(inst)
        return
    end

    local px, py, pz = inst.Transform:GetWorldPosition()

    inst:AddTag("NOCLICK")
    inst:AddTag("FX")
    inst.AnimState:OverrideMultColour(0, 0, 0, 0)

    -- 初始化矩阵
    local size = math.random(3, 4)
    local cut = math.random() < 0.6

    local offset = 0.8
    local cx = px - offset * size / 2 - offset -- 遍历从 1 开始，我们多加一位
    local cz = pz - offset * size / 2 - offset

    local matrix = {}
    inst._aipMatrix = matrix
    inst._aipSize = size
    inst._aipCut = cut

    for x = 1, size do
        matrix[x] = {}
        for z = 1, size do
            -- 如果在边缘就不用创建了
            if cut or (
                (x ~= 1 and x ~= size) or
                (z ~= 1 and z ~= size)
            ) then


                -- 创建花朵
                local flower = aipSpawnPrefab(
                    nil, "aip_four_flower",
                    cx + x * offset, py, cz + z * offset
                )
                flower._aipMaster = inst
                flower._aipX = x
                flower._aipZ = z
                matrix[x][z] = flower
            end
        end
    end

    -- 随机关闭花朵，直到数量差不多
    for i = 1, 25 do
        local rx = math.random(1, size)
        local rz = math.random(1, size)

        toggleActive(matrix[rx][rz])
    end

    if countOpen(inst, true) == 0 or countOpen(inst, false) == 0 then
        inst:Remove()
        return
    end

    inst._aipFlush = flushResult
end

local function OnRemoveEntity(inst)
    if inst._aipMatrix ~= nil then
        for x = 1, inst._aipSize do
            for z = 1, inst._aipSize do
                if inst._aipMatrix[x][z] ~= nil then
                    inst._aipMatrix[x][z]:Remove()
                end
            end
        end
    end
end

------------------------------ 实体 --------------------------------
local function fn()
    local scale = 0.6

    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("aip_four_flower")
    inst.AnimState:SetBuild("aip_four_flower")
    inst.AnimState:PlayAnimation("bud")
    inst.Transform:SetScale(scale, scale, scale)

    inst:AddTag("aip_olden_flower")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("activatable")
	inst.components.activatable.OnActivate = toggleActive
    inst.components.activatable.quickaction = true

    MakeHauntableLaunch(inst)

    inst.persists = false

    -- 初始化矩阵
    inst._aipMaster = nil
    inst._aipOpen = true
    inst:DoTaskInTime(0.1, initMatrix)

    inst.OnRemoveEntity = OnRemoveEntity

    return inst
end

return Prefab("aip_four_flower", fn, assets)
