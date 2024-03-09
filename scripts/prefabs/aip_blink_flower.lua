local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
    english = {NAME = "Blink Flower"},
    chinese = {NAME = "靡靡之花"}
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_BLINK_FLOWER = LANG.NAME

-- 资源
local assets = {Asset("ANIM", "anim/aip_blink_flower.zip")}

--------------------------------- 单个 -----------------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.entity:AddLight()
    inst.Light:Enable(true)
    inst.Light:SetRadius(.1)
    inst.Light:SetFalloff(.5)
    inst.Light:SetIntensity(.5)
    inst.Light:SetColour(250 / 255, 220 / 255, 0 / 255)

    inst:AddTag("NOBLOCK")
    inst:AddTag("DECOR")

    inst.AnimState:SetBank("aip_blink_flower")
    inst.AnimState:SetBuild("aip_blink_flower")
    inst.AnimState:PlayAnimation("idle", true)

    local scale = 0.5 -- + math.random() * 0.2
    inst.AnimState:SetScale(scale, scale, scale)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then return inst end

    inst:AddComponent("fader")

    inst.persists = false

    inst:DoTaskInTime(1 + math.random() * 1, function()
        inst.components.fader:Fade(1, 0, 1,
            function(alphaval)
                inst.AnimState:OverrideMultColour(1, 1, 1, alphaval)
                inst.Light:SetIntensity(.5 * alphaval)
            end,
            inst.Remove
        )
    end)

    return inst
end

--------------------------------- 群体 -----------------------------------
local function onFadeOut(inst)
    -- 遍历创建散发的光源

    inst:Remove()

    for i = 1, 16 do
        local blinkFlower = aipSpawnPrefab(inst, "aip_blink_flower")
        aipFlingItem(blinkFlower, nil, {
            ySpeed = 20,
            ySpeedVariance = 5,
            minSpeed = 3,
            maxSpeed = 5,
        })
    end
end

local function grpFn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.entity:AddLight()
    inst.Light:Enable(true)
    inst.Light:SetRadius(.5)
    inst.Light:SetFalloff(.5)
    inst.Light:SetIntensity(.1)
    inst.Light:SetColour(250 / 255, 220 / 255, 0 / 255)

    inst:AddTag("NOBLOCK")
    inst:AddTag("DECOR")

    inst.AnimState:SetBank("aip_blink_flower")
    inst.AnimState:SetBuild("aip_blink_flower")
    inst.AnimState:PlayAnimation("group")

    inst.AnimState:OverrideMultColour(1, 1, 1, 0)

    local scale = 0.7
    inst.AnimState:SetScale(scale, scale, scale)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("fader")

    inst:AddComponent("playerprox")
    inst.components.playerprox:SetDist(2, 5)
    inst.components.playerprox:SetOnPlayerNear(onFadeOut)

    inst.persists = false
    inst._aipList = {}

    inst:WatchWorldState("isnight", function(_, isnight)
		if not isnight then
			inst:Remove()
		end
	end)

    inst:DoTaskInTime(0.1, function()
        inst.components.fader:Fade(0, 1, 0.3,
            function(alphaval)
                inst.AnimState:OverrideMultColour(1, 1, 1, alphaval)
                inst.Light:SetIntensity(.1 + .7 * alphaval)
            end
        )
    end)

    return inst
end

return Prefab("aip_blink_flower", fn, assets),
       Prefab("aip_blink_flower_group", grpFn, assets)
