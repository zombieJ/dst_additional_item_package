local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Oldone's Meat",
        DESC = "Great gift!",
	},
	chinese = {
		NAME = "律动的肉块",
		DESC = "伟大的礼物！",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_OLDONE_MEAT = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_MEAT = LANG.DESC

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_oldone_meat.zip"),
	Asset("ATLAS", "images/inventoryimages/aip_oldone_meat.xml"),
}

----------------------------------- 方法 -----------------------------------
local function onEaten(inst, eater) -- 吃下后获得 60 秒的模因状态
    aipBufferPatch(inst, eater, "aip_see_eyes", 60)
end

----------------------------------- 实例 -----------------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("aip_oldone_meat")
    inst.AnimState:SetBuild("aip_oldone_meat")
    inst.AnimState:PlayAnimation("idle", true)

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
    inst.components.edible.sanityvalue = -50
    inst.components.edible.foodtype = FOODTYPE.GOODIES
    inst.components.edible:SetOnEatenFn(onEaten)

    inst:AddComponent("inspectable")
    
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_oldone_meat.xml"

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("aip_oldone_meat", fn, assets)
