local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Pig King Train Ticket",
		DESC = "A complete ticket made from three fragments.",
	},
	chinese = {
		NAME = "猪王列车体验券",
		DESC = "由三张碎片合成的正式体验券",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_TRAIN_TICKET = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_TRAIN_TICKET = LANG.DESC

-- 资源
local assets = {
	Asset("ANIM", "anim/aip_train_ticket.zip"),
	Asset("ATLAS", "images/inventoryimages/aip_train_ticket.xml"),
}

-- 创建可以堆叠保存的正式体验券。
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

	inst.AnimState:SetBank("aip_train_ticket")
	inst.AnimState:SetBuild("aip_train_ticket")
	inst.AnimState:PlayAnimation("idle")

    MakeInventoryFloatable(inst, "med", 0.3, 1)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.imagename = "aip_train_ticket"
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_train_ticket.xml"

	inst:AddComponent("stackable")

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("aip_train_ticket", fn, assets)
