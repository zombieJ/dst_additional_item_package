local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Legion Stone",
		DESC = "Last piece of Magic Rubik",
	},
	chinese = {
		NAME = "棱镜石",
		DESC = "魔力方阵的最后一片",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_LEGION = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_LEGION = LANG.DESC

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_legion.zip"),
	Asset("ATLAS", "images/inventoryimages/aip_legion.xml"),
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("aip_legion")
    inst.AnimState:SetBuild("aip_legion")
    inst.AnimState:PlayAnimation("idle")

    MakeInventoryFloatable(inst, "med", nil, 0.68)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_legion.xml"

	inst:AddComponent("tradable")
	inst.components.tradable.goldvalue = 3

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("aip_legion", fn, assets)
