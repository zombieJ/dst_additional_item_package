local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Coal",
		DESC = "A renewable resource",
	},
	chinese = {
		NAME = "煤炭",
		DESC = "是可再生资源",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_COAL = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_COAL = LANG.DESC

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_coal.zip"),
	Asset("ATLAS", "images/inventoryimages/aip_coal.xml"),
}

local function OnExplosion(inst, data)
    local miner = data and data.explosive or nil
    if miner then
        local loot_data = TUNING.ROCK_FRUIT_LOOT

        -- TODO: Loot this
        local gem = SpawnPrefab("purplegem")
        LaunchAt(gem, inst, miner, loot_data.SPEED, loot_data.HEIGHT, nil, loot_data.ANGLE)
        aipRemove(inst)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("aip_coal")
    inst.AnimState:SetBuild("aip_coal")
    inst.AnimState:PlayAnimation("idle")

    MakeInventoryFloatable(inst, "med", 0.3, 1)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
    MakeSmallPropagator(inst)
    
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_coal.xml"

    inst:AddComponent("stackable")

	inst:AddComponent("tradable")
	inst.components.tradable.goldvalue = 1

    MakeHauntableLaunch(inst)

    inst:ListenForEvent("explosion", OnExplosion)

    return inst
end

return Prefab("aip_coal", fn, assets)
