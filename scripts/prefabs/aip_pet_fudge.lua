local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Animal Fudge",
		DESC = "Helps animals grow up",
        REC_DESC = "Raise a random skill of the animal by 1 level, up to 3 times",
        NAME_FISH = "Animal Fish Scent Fudge",
        REC_DESC_FISH = "Raise the lowest skill of the animal by 2 levels, up to 1 time",

        NAME_BUG = "Animal BUG Fudge",
        REC_DESC_FISH = "Don't feed the animal!",
	},
	chinese = {
		NAME = "小动物软糖",
		DESC = "能够提升小动物能力的糖果",
        REC_DESC = "给小动物吃后提升其随机一个技能品质 1 级",
        NAME_FISH = "小动物鱼香味软糖",
        REC_DESC_FISH = "给小动物吃后提升其最低技能的品质 2 级",

        NAME_BUG = "小动物 BUG 软糖",
        REC_DESC_FISH = "不要喂给小动物吃！",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_PET_FUDGE = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_PET_FUDGE = LANG.DESC
STRINGS.RECIPE_DESC.AIP_PET_FUDGE = LANG.REC_DESC

STRINGS.NAMES.AIP_PET_FUDGE_FISH = LANG.NAME_FISH
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_PET_FUDGE_FISH = LANG.DESC
STRINGS.RECIPE_DESC.AIP_PET_FUDGE_FISH = LANG.REC_DESC_FISH

STRINGS.NAMES.AIP_PET_FUDGE_BUG = LANG.NAME_BUG
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_PET_FUDGE_BUG = LANG.DESC

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_pet_fudge.zip"),
	Asset("ATLAS", "images/inventoryimages/aip_pet_fudge.xml"),
    Asset("ATLAS", "images/inventoryimages/aip_pet_fudge_fish.xml"),
    Asset("ATLAS", "images/inventoryimages/aip_pet_fudge_bug.xml"),
}

local function common_fn(anim, altas)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("aip_pet_fudge")
    inst.AnimState:SetBuild("aip_pet_fudge")
    inst.AnimState:PlayAnimation(anim)

    inst:AddTag("aip_pet_fudge")

    MakeInventoryFloatable(inst, "med", 0.3, 1)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/"..altas..".xml"

    inst:AddComponent("tradable")
    inst.components.tradable.goldvalue = 0

    inst:AddComponent("stackable")
	inst.components.stackable.maxsize = TUNING.STACK_SIZE_MEDITEM

    MakeHauntableLaunch(inst)

    return inst
end

local function fn()
    local inst = common_fn("idle", "aip_pet_fudge")
    return inst
end

local function fishFn()
    local inst = common_fn("fish", "aip_pet_fudge_fish")
    return inst
end

local function bugFn()
    local inst = common_fn("bug", "aip_pet_fudge_bug")
    return inst
end

return Prefab("aip_pet_fudge", fn, assets),
    Prefab("aip_pet_fudge_fish", fishFn, assets),
    Prefab("aip_pet_fudge_bug", bugFn, assets)
