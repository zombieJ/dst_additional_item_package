local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Rift Smiler",
		DESC = "Indescribable!",
	},
	chinese = {
		NAME = "裂隙笑颜",
		DESC = "不可名状！",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_OLDONE_SMILE = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_SMILE = LANG.DESC

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_oldone_smile.zip"),
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    inst.DynamicShadow:SetSize(4, 2)

    MakeFlyingGiantCharacterPhysics(inst, 500, 1.4)

    inst.AnimState:SetBank("aip_oldone_smile")
    inst.AnimState:SetBuild("aip_oldone_smile")
    inst.AnimState:PlayAnimation("idle", true)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    -- 闪烁特效
    inst.AnimState:SetErosionParams(0, -0.125, -1.0)

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("aip_oldone_smile", fn, assets)
