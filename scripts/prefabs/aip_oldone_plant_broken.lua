local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Broken Plant Skin",
		DESC = "It has a better way to get fully one",
	},
	chinese = {
		NAME = "破碎的粘衣",
		DESC = "都破了，或许有更好的方式来采摘它",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_OLDONE_PLANT_BROKEN = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_PLANT_BROKEN = LANG.DESC

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_oldone_plant_broken.zip"),
	Asset("ATLAS", "images/inventoryimages/aip_oldone_plant_broken.xml"),
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst:AddTag("show_spoilage")

    inst.AnimState:SetBank("aip_oldone_plant_broken")
    inst.AnimState:SetBuild("aip_oldone_plant_broken")
    inst.AnimState:PlayAnimation("idle")

    MakeInventoryFloatable(inst, "med", 0.3, 1)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_oldone_plant_broken.xml"

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(TUNING.PERISH_MED)
    inst.components.perishable:StartPerishing()
    inst.components.perishable.onperishreplacement = "spoiled_food"

    MakeSmallBurnable(inst)
    MakeSmallPropagator(inst)

    MakeHauntableLaunchAndPerish(inst)

    return inst
end

return Prefab("aip_oldone_plant_broken", fn, assets)
