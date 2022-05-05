local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Deciduous Heap",
		DESC = "Be careful. It's flammable",
	},
	chinese = {
		NAME = "落叶堆",
		DESC = "小心，枯叶易燃",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_OLDONE_LEAVES = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_LEAVES = LANG.DESC

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_oldone_leaves.zip"),
}

------------------------------ 事件 ------------------------------
local function OnBurnt(inst)
    -- 奖励附近的玩家
    local players = aipFindNearPlayers(inst, 8)
    for i, player in ipairs(players) do
        if player ~= nil and player.components.aipc_oldone ~= nil then
            player.components.aipc_oldone:DoDelta()
        end
    end

    aipReplacePrefab(inst, "ash")
end

local function onWorldState(inst, season)
    if season ~= "autumn" then
        aipReplacePrefab(inst, "aip_shadow_wrapper").DoShow(1.5)
    end
end

------------------------------ 实例 ------------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("aip_oldone_leaves")
    inst.AnimState:SetBuild("aip_oldone_leaves")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("aip_olden_flower")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    -- 可燃烧
    inst:AddComponent("burnable")
    inst.components.burnable:SetFXLevel(5)
    inst.components.burnable:SetBurnTime(15)
    inst.components.burnable:AddBurnFX("fire", Vector3(0, 0.2, 0), nil, nil, 0.8)
    inst.components.burnable:SetOnBurntFn(OnBurnt)

    MakeMediumPropagator(inst)

    inst:WatchWorldState("season", onWorldState)

    inst.persists = false

    return inst
end

return Prefab("aip_oldone_leaves", fn, assets)
