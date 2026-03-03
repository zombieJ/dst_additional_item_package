local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Ginkgo",
        DESC = "Spiritful",
	},
	chinese = {
		NAME = "银杏果",
		DESC = "精神饱满",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_OLDONE_APPLE = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_APPLE = LANG.DESC

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_oldone_apple.zip"),
	Asset("ATLAS", "images/inventoryimages/aip_oldone_apple.xml"),
}

----------------------------------- 方法 -----------------------------------

----------------------------------- 实例 -----------------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("aip_oldone_apple")
    inst.AnimState:SetBuild("aip_oldone_apple")
    inst.AnimState:PlayAnimation("idle")

    MakeInventoryFloatable(inst, "med", 0.3, 1)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("stackable")
	inst.components.stackable.maxsize = TUNING.STACK_SIZE_MEDITEM

    inst:AddComponent("edible")
    inst.components.edible.hungervalue = 0
    inst.components.edible.healthvalue = 0
    inst.components.edible.sanityvalue = 1000
    inst.components.edible.foodtype = FOODTYPE.GOODIES

    inst:AddComponent("inspectable")
    
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_oldone_apple.xml"

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("aip_oldone_apple", fn, assets)
