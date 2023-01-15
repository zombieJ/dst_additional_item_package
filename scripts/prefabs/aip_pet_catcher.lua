local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Pet Sweets",
        REC_DESC = "Catch small animals. The higher the quality of the small animals, the harder to catch.",
		DESC = "Catch small animals",
	},
	chinese = {
		NAME = "宠物甜品",
        REC_DESC = "用于捕捉小动物，品质越高的小动物越难捕捉",
		DESC = "用于捕捉小动物",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_PET_CATCHER = LANG.NAME
STRINGS.RECIPE_DESC.AIP_PET_CATCHER = LANG.REC_DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_PET_CATCHER = LANG.DESC

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_pet_catcher.zip"),
	Asset("ATLAS", "images/inventoryimages/aip_pet_catcher.xml"),
}

----------------------------------- 方法 -----------------------------------
local function onHit(inst, attacker, target)
    local aura = aipReplacePrefab(inst, "aip_fx_splode").DoShow(nil, 0.5)

    local ent = aipFindNearEnts(inst, { "rabbit" }, 3)[1]
    if ent ~= nil then
        aipRemove(ent)
    end
end

----------------------------------- 实例 -----------------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("aip_pet_catcher")
    inst.AnimState:SetBuild("aip_pet_catcher")
    inst.AnimState:PlayAnimation("idle")

    MakeInventoryFloatable(inst, "med", 0.3, 1)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("complexprojectile")
    inst.components.complexprojectile:SetHorizontalSpeed(15)
    inst.components.complexprojectile:SetGravity(-25)
    inst.components.complexprojectile:SetLaunchOffset(Vector3(0, 2.5, 0))
    inst.components.complexprojectile:SetOnHit(onHit)

    inst:AddComponent("inspectable")
    
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_pet_catcher.xml"

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("aip_pet_catcher", fn, assets)
