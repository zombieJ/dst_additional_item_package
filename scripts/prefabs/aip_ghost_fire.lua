local dev_mode = aipGetModConfig("dev_mode") == "enabled"

local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Decorative Ghost Fire",
		DESC = "A ghost fire that can be pinched",
	},
	chinese = {
		NAME = "装饰鬼火",
		DESC = "可以随意拿捏的鬼火",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_GHOST_FIRE = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_GHOST_FIRE = LANG.DESC

-- 资源
local assets = {
    Asset("ATLAS", "images/inventoryimages/aip_ghost_fire.xml"),
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
    end)
end

local function RandomColor(inst)
    local ori = { inst._aipR, inst._aipG, inst._aipB }

    local idx = 1

    for i = 1, 10 do
        local nextIdx = math.random(1, 3)

        if ori[idx] ~= 1 then
            idx = nextIdx
            break
        end
    end

    local nextColors = { math.random(), math.random(), math.random() }
    nextColors[idx] = 1

    inst._aipR = nextColors[1]  -- R
    inst._aipG = nextColors[2]  -- G
    inst._aipB = nextColors[3]  -- B

    SyncColor(inst)
end

-- 造出来后就随机颜色
local function OnPreBuilt(inst, builder, materials, recipe)
    RandomColor(inst)
end

local function OnSave(inst, data)
    data.r = inst._aipR
    data.g = inst._aipG
    data.b = inst._aipB
end

local function OnLoad(inst, data)
    if data ~= nil then
        inst._aipR = data.r or 1
        inst._aipG = data.g or 1
        inst._aipB = data.b or 1
        SyncColor(inst)
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

    MakeProjectilePhysics(inst, 1, .25)

    inst.AnimState:SetBank("coldfire_fire")
    inst.AnimState:SetBuild("coldfire_fire")
    inst.AnimState:PlayAnimation("level1", true)

    inst.Light:SetColour(111/255, 111/255, 227/255)
    inst.Light:SetIntensity(0.75)
    inst.Light:SetFalloff(1)
    inst.Light:SetRadius(1)
    inst.Light:Enable(true)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.AnimState:SetTime(math.random() * 2)

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_ghost_fire.xml"

    inst:AddComponent("inventoryitem")

    inst.onPreBuilt = OnPreBuilt

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    inst.RandomColor = RandomColor

    return inst
end

return Prefab("aip_ghost_fire", fn, assets)
