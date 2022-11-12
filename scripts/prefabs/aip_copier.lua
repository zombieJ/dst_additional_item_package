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
-- local function AbleToAcceptTest()
--     aipPrint("able...")
--     return true
-- end

-- local function ShouldAcceptItem(inst, item)
--     aipPrint("accept...")
--     return true
-- end

-- local function OnGetItemFromPlayer(inst, giver, item)
--     local record = item:GetSaveRecord()

--     for i = 1, 2 do
--         local newItem = SpawnSaveRecord(record)
--         aipFlingItem(newItem, inst:GetPosition())
--     end
-- end


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

    -- 容器
	inst:AddComponent("container")
	inst.components.container:WidgetSetup("aip_copier")

    -- 操作
	inst:AddComponent("aipc_action")
	inst.components.aipc_action.onDoAction = onCopy

    return inst
end

return Prefab("aip_copier", fn, assets)
