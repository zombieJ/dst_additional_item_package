local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Fish Bubble",
		DESC = "It's soft",
	},
	chinese = {
		NAME = "鱼泡",
		DESC = "糯糯的，小动物很喜欢吃",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_FISHMAN_MUCUS = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_FISHMAN_MUCUS = LANG.DESC

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_fishman_mucus.zip"),
	Asset("ATLAS", "images/inventoryimages/aip_fishman_mucus.xml"),
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("aip_fishman_mucus")
    inst.AnimState:SetBuild("aip_fishman_mucus")
    inst.AnimState:PlayAnimation("idle")

    MakeInventoryFloatable(inst, "med", 0.3, 1)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_fishman_mucus.xml"

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("aip_fishman_mucus", fn, assets)
