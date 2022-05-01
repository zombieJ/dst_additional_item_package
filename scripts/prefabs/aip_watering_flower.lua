local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Thirsty Flower",
		DESC = "It's safe to water it",
	},
	chinese = {
		NAME = "口渴的花朵",
		DESC = "浇水是一个安全的行为",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_WATERING_FLOWER = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_WATERING_FLOWER = LANG.DESC

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_watering_flower.zip"),
}

------------------------------------ 事件 ------------------------------------
local function onAipProtected(inst)
    inst.AnimState:PlayAnimation("bloom")

    local players = aipFindNearPlayers(inst, 3)
    for i, player in ipairs(players) do
        if player ~= nil and player.components.aipc_oldone ~= nil then
            player.components.aipc_oldone:DoDelta()
        end
    end

    inst:ListenForEvent("animover", function()
        inst:DoTaskInTime(1, function()
            aipReplacePrefab(inst, "aip_shadow_wrapper").DoShow(1)
        end)
    end)
end

------------------------------------ 实体 ------------------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("aip_watering_flower")
    inst.AnimState:SetBuild("aip_watering_flower")
    inst.AnimState:PlayAnimation("withered")

    --witherable (from witherable component) added to pristine state for optimization
    inst:AddTag("witherable")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("witherable")
    inst.components.witherable.onAipProtected = onAipProtected

    inst:DoTaskInTime(0.1, function()
        inst.components.witherable:ForceWither()
    end)

    MakeHauntableLaunch(inst)
    MakeSmallBurnable(inst)
    MakeSmallPropagator(inst)

    inst.persists = false

    return inst
end

return Prefab("aip_watering_flower", fn, assets)
