local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Cold Skin",
		DESC = "Crystal clear and thin 'food'",
	},
	chinese = {
		NAME = "薄树皮",
		DESC = "一片“空白”，似乎可以做食物",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_COLD_SKIN = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_COLD_SKIN = LANG.DESC

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_cold_skin.zip"),
	Asset("ATLAS", "images/inventoryimages/aip_cold_skin.xml"),
}

local function perishfn(inst)
	inst:Remove()
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("aip_cold_skin")
    inst.AnimState:SetBuild("aip_cold_skin")
    inst.AnimState:PlayAnimation("idle")

    MakeInventoryFloatable(inst, "med", 0.3, 1)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_cold_skin.xml"

    inst:AddComponent("edible")
    inst.components.edible.hungervalue = 5
    inst.components.edible.healthvalue = -1
    inst.components.edible.sanityvalue = -1
    inst.components.edible.foodtype = FOODTYPE.GOODIES

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_MEDITEM

    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(TUNING.PERISH_SLOW)
    inst.components.perishable:StartPerishing()
    inst.components.perishable.perishfn = perishfn

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("aip_cold_skin", fn, assets)
