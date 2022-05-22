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
local BASE_DIST = dev_mode and 5 or 20

local function toggleActive(inst, doer)
    -- TODO
end

local function initMatrix(inst)
    if inst._aipMaster ~= nil then
        return
    end

    inst._aipHands = {}
    inst.AnimState:PlayAnimation("empty")
    local pt = inst:GetPosition()

    for i = 1, 3 do
        local pos = aipGetSecretSpawnPoint(pt, BASE_DIST, BASE_DIST + 20, 3)
        if pos ~= nil then
            local hand = aipSpawnPrefab(nil, "aip_oldone_black", pos.x, pos.y, pos.z)
            table.insert(inst._aipHands, hand)
            hand._aipClose = false
            hand._aipMaster = inst
        end
    end
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

    return inst
end

return Prefab("aip_oldone_black", fn, assets)
