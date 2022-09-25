local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Lazy Pumpkin",
		DESC = "It will throw things when anger",
	},
	chinese = {
		NAME = "怠惰的南瓜",
		DESC = "惹它生气可会乱丢东西",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_TRICKY_THROWER = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_TRICKY_THROWER = LANG.DESC

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_tricky_thrower.zip"),
}

------------------------------------ 方法 ------------------------------------
local function onHit(inst, attacker)
    
end

------------------------------------ 实例 ------------------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("aip_tricky_thrower")
    inst.AnimState:SetBuild("aip_tricky_thrower")
    inst.AnimState:PlayAnimation("idle")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("aip_tricky_thrower")
    -- inst.components.container.onopenfn = onopen
    -- inst.components.container.onclosefn = onclose
    -- inst.components.container.skipclosesnd = true
    -- inst.components.container.skipopensnd = true

    inst:AddComponent("combat")
    inst.components.combat.onhitfn = onHit

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(100)
    inst.components.health.nofadeout = true
    inst.components.health:StartRegen(1, 10)

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("aip_tricky_thrower", fn, assets)
