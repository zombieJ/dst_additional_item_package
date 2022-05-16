local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "lantern berry",
		DESC = "Terror but eatable",
	},
	chinese = {
		NAME = "菇茑",
		DESC = "恐怖却可以食用",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_OLDONE_DEER_EYE = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_DEER_EYE = LANG.DESC

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_oldone_deer_eye.zip"),
	-- Asset("ATLAS", "images/inventoryimages/aip_22_fish.xml"),
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("aip_oldone_deer_eye")
    inst.AnimState:SetBuild("aip_oldone_deer_eye")
    inst.AnimState:PlayAnimation("idle", true)

    -- MakeInventoryFloatable(inst, "med", 0.3, 1)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

	-- inst:AddComponent("inventoryitem")
	-- inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_22_fish.xml"

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("aip_oldone_deer_eye", fn, assets)
