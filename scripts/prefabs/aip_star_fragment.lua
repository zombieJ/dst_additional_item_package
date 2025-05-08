local dev_mode = aipGetModConfig("dev_mode") == "enabled"

local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Star Fragment",
		DESC = "Wish on a shooting star?",
	},
	chinese = {
		NAME = "星星碎片",
		DESC = "对流星许愿了吗",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_STAR_FRAGMENT = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_STAR_FRAGMENT = LANG.DESC

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_star_fragment.zip"),
    Asset("ATLAS", "images/inventoryimages/aip_star_fragment.xml"),
}

------------------------------------- 方法 -------------------------------------
local function SyncColor(inst)
    inst:DoTaskInTime(0.1, function()
        inst.AnimState:OverrideMultColour(inst._aipR, inst._aipG, inst._aipB, 1)
        inst.Light:SetColour(
            0.5 + inst._aipR / 2,
            0.5 + inst._aipG / 2,
            0.5 + inst._aipB / 2
        )

        if inst._aipY ~= nil then
            local tgtPT = inst:GetPosition()
            tgtPT.y = inst._aipY

            aipTypePrint("->", tgtPT, inst._aipY)
            inst.components.aipc_float:MoveToPoint(tgtPT)
        end

        inst.AnimState:PlayAnimation("idle", true)
        inst.AnimState:SetTime(math.random() * 2)
    end)
end

local function RandomColor(inst, skipY)
    local ori = { inst._aipR, inst._aipG, inst._aipB }

    local idx = 1

    for i = 1, 10 do
        local nextIdx = math.random(1, 3)

        if ori[idx] ~= 1 then
            idx = nextIdx
            break
        end
    end

    local nextColors = {
        math.random() / 2 + 0.5,
        math.random() / 2 + 0.5,
        math.random() / 2 + 0.5,
    }
    nextColors[idx] = 1

    inst._aipR = nextColors[1]  -- R
    inst._aipG = nextColors[2]  -- G
    inst._aipB = nextColors[3]  -- B

    if skipY ~= false then
        inst._aipY = math.random() * 2 + 1
    end

    SyncColor(inst)
end

local function OnSave(inst, data)
    data.r = inst._aipR
    data.g = inst._aipG
    data.b = inst._aipB
    data.y = inst._aipY
end

local function OnLoad(inst, data)
    if data ~= nil then
        inst._aipR = data.r or 1
        inst._aipG = data.g or 1
        inst._aipB = data.b or 1
        inst._aipY = data.y

        aipTypePrint("load", inst._aipY)

        SyncColor(inst)
    end
end

local function onPickUp(inst)
    inst.persists = true
    inst.components.aipc_float:Stop()
end

local function onNight(inst, isNight)
    if not isNight and inst.persists == false then
        inst.components.despawnfader:FadeOut()
    end
end

------------------------------------- 实例 -------------------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    MakeProjectilePhysics(inst, 1, .1)

    inst.AnimState:SetBank("aip_star_fragment")
    inst.AnimState:SetBuild("aip_star_fragment")
    inst.AnimState:PlayAnimation("idle", true)

    inst.Light:SetColour(111/255, 111/255, 227/255)
    inst.Light:SetIntensity(0.75)
    inst.Light:SetFalloff(1)
    inst.Light:SetRadius(0.5)
    inst.Light:Enable(true)

    inst.entity:SetPristine()

    inst:AddComponent("despawnfader")

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("aipc_float")
    inst.components.aipc_float.speed = 0.5

    inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_star_fragment.xml"

    inst:AddComponent("tradable")
	inst.components.tradable.goldvalue = 3

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    inst.RandomColor = RandomColor

    inst:ListenForEvent("onpickup", onPickUp)

    inst:WatchWorldState("isnight", onNight)

    return inst
end

return Prefab("aip_star_fragment", fn, assets)
