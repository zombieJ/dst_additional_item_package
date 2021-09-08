local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "22 pound catfish",
		DESC = "It's heavy",
	},
	chinese = {
		NAME = "22 磅重的鲶鱼",
		DESC = "“鱼别丢”",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_22_FISH = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_22_FISH = LANG.DESC

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_22_fish.zip"),
	Asset("ATLAS", "images/inventoryimages/aip_22_fish.xml"),
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("aip_22_fish")
    inst.AnimState:SetBuild("aip_22_fish")
    inst.AnimState:PlayAnimation("idle")

    MakeInventoryFloatable(inst, "med", 0.3, 1)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_22_fish.xml"

	inst:AddComponent("tradable")
	inst.components.tradable.goldvalue = 12

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("aip_22_fish", fn, assets)
