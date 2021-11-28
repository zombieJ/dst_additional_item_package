local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Enlightenment'C Sculpture ",
		DESC = "A squid holding a treasure chest",
	},
	chinese = {
		NAME = "启迪时克雕塑",
		DESC = "一只鱿鱼生物抱着宝箱",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_EYE_BOX = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_EYE_BOX = LANG.DESC

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_eye_box.zip"),
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, .5)

    inst.AnimState:SetBank("aip_eye_box")
    inst.AnimState:SetBuild("aip_eye_box")
    inst.AnimState:PlayAnimation("idle")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("aip_eye_box", fn, assets)
