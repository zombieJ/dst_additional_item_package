local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "'Fully' Bulb",
		DESC = "Filled with spider silk neurons",
	},
	chinese = {
		NAME = "“完整”的球茎",
		DESC = "其中充满蜘蛛丝状神经元",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_OLDONE_PLANT_FULL = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_PLANT_FULL = LANG.DESC

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_oldone_plant_full.zip"),
	Asset("ATLAS", "images/inventoryimages/aip_oldone_plant_full.xml"),
}

----------------------------------- 事件 -----------------------------------

----------------------------------- 实体 -----------------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    --projectile (from complexprojectile component) added to pristine state for optimization
    inst:AddTag("projectile")

    inst.AnimState:SetBank("aip_oldone_plant_full")
    inst.AnimState:SetBuild("aip_oldone_plant_full")
    inst.AnimState:PlayAnimation("idle")

    MakeInventoryFloatable(inst, "med", 0.3, 1)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("complexprojectile")

    inst:AddComponent("inspectable")
    
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_oldone_plant_full.xml"

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_LARGEITEM

    MakeSmallBurnable(inst)
    MakeSmallPropagator(inst)

    MakeHauntableLaunchAndPerish(inst)

    return inst
end

return Prefab("aip_oldone_plant_full", fn, assets)
