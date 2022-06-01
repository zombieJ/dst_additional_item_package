local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Bamboo Note",
		DESC = "An Adventurer's Notes",
	},
	chinese = {
		NAME = "若行手记",
		DESC = "一位冒险者的笔记",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_STORYBOOK = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_STORYBOOK = LANG.DESC

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_storybook.zip"),
	Asset("ATLAS", "images/inventoryimages/aip_storybook.xml"),
}

------------------------------- 事件 -------------------------------
local function OnReadBook(inst, doer)
	doer:ShowPopUp(POPUPS.AIP_STORY, true)
end

------------------------------- 实例 -------------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("aip_storybook")
    inst.AnimState:SetBuild("aip_storybook")
    inst.AnimState:PlayAnimation("idle")

	inst.Transform:SetScale(1.2, 1.2, 1.2)

    MakeInventoryFloatable(inst, "med", nil, 0.75)

	-- for simplebook component
	inst:AddTag("simplebook")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    -----------------------------------

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_storybook.xml"

	inst:AddComponent("simplebook")
	inst.components.simplebook.onreadfn = OnReadBook

    MakeSmallBurnable(inst, TUNING.MED_BURNTIME)
    MakeSmallPropagator(inst)

    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.MED_FUEL

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("aip_storybook", fn, assets)
