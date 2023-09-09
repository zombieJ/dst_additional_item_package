local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Sessho Seki",
		DESC = "Must protect it",
	},
	chinese = {
		NAME = "杀生石",
		DESC = "必须守护它",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_SESSHO_SEKI = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_SESSHO_SEKI = LANG.DESC

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_sessho_seki.zip"),
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 0.3)

    inst.AnimState:SetBank("aip_sessho_seki")
    inst.AnimState:SetBuild("aip_sessho_seki")
    inst.AnimState:PlayAnimation("idle")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(10)

    inst:AddComponent("aipc_blackhole_gamer")

    MakeHauntableLaunch(inst)

    inst.persists = false

    return inst
end

return Prefab("aip_sessho_seki", fn, assets)
