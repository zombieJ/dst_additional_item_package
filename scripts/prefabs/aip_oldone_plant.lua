local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Strange Bulb",
		DESC = "This thing is kinda creepy",
	},
	chinese = {
		NAME = "怪异的球茎",
		DESC = "这东西多少有点渗人",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_OLDONE_PLANT = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_PLANT = LANG.DESC

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_oldone_plant.zip"),
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("aip_oldone_plant")
    inst.AnimState:SetBuild("aip_oldone_plant")
    inst.AnimState:PlayAnimation("small", true)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("aip_oldone_plant", fn, assets)
