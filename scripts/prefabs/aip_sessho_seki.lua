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

------------------------------------ 配置 ------------------------------------
local MAX_HEALTH = 10
local STATE_COUNT = 6

------------------------------------ 方法 ------------------------------------
local function refreshState(inst)
    local health = 1 - inst.components.health:GetPercent()
    local stateIdx = math.floor(health * STATE_COUNT) + 1

    inst.AnimState:PlayAnimation("idle"..stateIdx)
end

------------------------------------ 实例 ------------------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 0.1)

    inst.AnimState:SetBank("aip_sessho_seki")
    inst.AnimState:SetBuild("aip_sessho_seki")
    inst.AnimState:PlayAnimation("idle1")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(MAX_HEALTH)
    inst.components.health:SetInvincible(true)

    inst:AddComponent("aipc_blackhole_gamer")

    MakeHauntableLaunch(inst)

    refreshState(inst)

    inst:ListenForEvent("healthdelta", refreshState)

    inst.persists = false

    return inst
end

return Prefab("aip_sessho_seki", fn, assets)
