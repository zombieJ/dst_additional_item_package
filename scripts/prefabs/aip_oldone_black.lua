local language = aipGetModConfig("language")
local dev_mode = aipGetModConfig("dev_mode") == "enabled"

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Behind the scenes",
		DESC = "Find them all",
	},
	chinese = {
		NAME = "幕后黑手",
		DESC = "把他们都找出来",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_OLDONE_BLACK = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_BLACK = LANG.DESC

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_oldone_black.zip"),
}

----------------------------- 事件 --------------------------------
local MIN_DIST = dev_mode and 5 or 30
local MAX_DIST = dev_mode and 10 or 50

local function OnRemoveEntity(inst)
    if inst._aipHands then
        for k, v in pairs(inst._aipHands) do
            aipReplacePrefab(v, "aip_shadow_wrapper").DoShow(0.8)
        end
    end
end

local function checkResult(inst, doer)
    local allClosed = true

    if inst._aipHands then
        for k, v in pairs(inst._aipHands) do
            if v.components.activatable.inactive then
                allClosed = false
                break
            end
        end
    else
        allClosed = false
    end

    if allClosed then
        -- 增加一点模因因子
        if doer ~= nil and doer.components.aipc_oldone ~= nil then
            doer.components.aipc_oldone:DoDelta(1)
        end

        -- 消失
        aipRemove(inst)
    end
end

local function toggleActive(inst, doer)
    inst.AnimState:PlayAnimation("close")

    -- 动画结束才判断
    inst:ListenForEvent("animover", function()
        if inst._aipMaster ~= nil then
            checkResult(inst._aipMaster, doer)
        end
    end)
end

local function initMatrix(inst)
    if inst._aipMaster ~= nil then
        return
    end

    inst._aipHands = {}
    inst.AnimState:PlayAnimation("empty")
    local pt = inst:GetPosition()

    for i = 1, 3 do
        local pos = aipGetSecretSpawnPoint(pt, MIN_DIST, MAX_DIST, 3)
        if pos ~= nil then
            local hand = aipSpawnPrefab(nil, "aip_oldone_black", pos.x, pos.y, pos.z)
            table.insert(inst._aipHands, hand)
            hand._aipClose = false
            hand._aipMaster = inst
        end
    end

    inst.components.activatable.inactive = false
end

----------------------------- 实例 --------------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("aip_oldone_black")
    inst.AnimState:SetBuild("aip_oldone_black")
    inst.AnimState:PlayAnimation("idle")

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

    inst:DoTaskInTime(0.1, initMatrix)

    inst.OnRemoveEntity = OnRemoveEntity

    return inst
end

return Prefab("aip_oldone_black", fn, assets)
