local dev_mode = aipGetModConfig("dev_mode") == "enabled"

local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "D2022 Test Machine",
		DESC = "Only work in dev mod",
	},
	chinese = {
		NAME = "D2022 测试试做型",
		DESC = "只有在开发环境才能生效",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_COPIER = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_COPIER = LANG.DESC

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_copier.zip"),
}

------------------------------ 事件 ------------------------------
-- 复制物品
local function onCopy(inst, doer)
    if not dev_mode then
        return
    end

	-- 价值分析
	for k, item in pairs(inst.components.container.slots) do
        if item ~= nil and item:IsValid() then
            aipFlingItem(aipCopy(item), inst:GetPosition())
        end
	end
end

-- 检查时打印统计信息
local function onSelect()
    local function toList(tbl)
        local clone = {}
        for k, v in pairs(tbl) do
            table.insert(clone, { k = k, v = v })
        end
        table.sort(clone, function(a, b) return a.v > b.v end)
        return clone
    end

    if TheWorld._aipDevUpdateListTotal ~= nil then
        aipPrint("========== 世界更新统计（总量） ==========")
        local list = toList(TheWorld._aipDevUpdateListTotal)
        for _, data in ipairs(list) do
            aipPrint(data.k..": "..data.v.."("..TheWorld._aipDevUpdateTimesListTotal[data.k]..")")
        end
    end

    if TheWorld._aipDevUpdateList ~= nil then
        aipPrint("========== 世界更新统计（当前）==========")
        local list = toList(TheWorld._aipDevUpdateList)
        for _, data in ipairs(list) do
            aipPrint(data.k..": "..data.v.."("..TheWorld._aipDevUpdateTimesList[data.k]..")")
        end
    end

    if TheWorld._aipDevWalkingList ~= nil then
        aipPrint("========== 世界更新统计（运行）==========")
        local map = {}
        for cmpName, cmpKVs in pairs(TheWorld._aipDevWalkingList) do
            map[cmpName] = 0
            for k, v in pairs(cmpKVs) do
                if v == true then
                    map[cmpName] = map[cmpName] + 1
                end
            end
        end

        local list = toList(map)
        for _, data in ipairs(list) do
            aipPrint(data.k..": "..data.v)
        end
    end
end

------------------------------ 实例 ------------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 0.5)

    inst.AnimState:SetBank("aip_copier")
    inst.AnimState:SetBuild("aip_copier")
    inst.AnimState:PlayAnimation("idle")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst.components.inspectable.descriptionfn = onSelect

    -- 容器
	inst:AddComponent("container")
	inst.components.container:WidgetSetup("aip_copier")

    -- 操作
	inst:AddComponent("aipc_action")
	inst.components.aipc_action.onDoAction = onCopy

    return inst
end

return Prefab("aip_copier", fn, assets)
