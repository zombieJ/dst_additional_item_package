local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Eye Stone",
		DESC = "Everything, Everywhere, All at Once",
	},
	chinese = {
		NAME = "石头",
		DESC = "瞬息全宇宙",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_OLDONE_ONCE = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_ONCE = LANG.DESC

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_oldone_once.zip"),
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("aip_oldone_once")
    inst.AnimState:SetBuild("aip_oldone_once")
    inst.AnimState:PlayAnimation("idle")

    MakeInventoryFloatable(inst, "med", 0.3, 1)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("aip_oldone_once", fn, assets)
