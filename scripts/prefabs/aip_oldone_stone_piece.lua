local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "water drift",
		DESC = "It's flying",
	},
	chinese = {
		NAME = "水漂",
		DESC = "它正在飞驰",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_OLDONE_STONE_PIECE = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_STONE_PIECE = LANG.DESC

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_oldone_stone_piece.zip"),
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.entity:AddDynamicShadow()
	inst.DynamicShadow:SetSize(1.5, .5)

    MakeTinyFlyingCharacterPhysics(inst, 1, 0)

    inst.AnimState:SetBank("aip_oldone_stone_piece")
    inst.AnimState:SetBuild("aip_oldone_stone_piece")
    inst.AnimState:PlayAnimation("idle", true)

    inst:AddTag("FX")

    MakeInventoryFloatable(inst, "med", 0.3, 1)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("aipc_water_drift")

    inst.persists = false

    return inst
end

return Prefab("aip_oldone_stone_piece", fn, assets)
