-- 开发模式
local dev_mode = aipGetModConfig("dev_mode") == "enabled"

local BaseHealth = dev_mode and 100 or TUNING.WORM_HEALTH

local assets = {
	Asset("ANIM", "anim/aip_rubik_heart.zip"),
	Asset("ANIM", "anim/aip_rubik_ghost.zip"),
}

local language = aipGetModConfig("language")

local LANG_MAP = {
	english = {
		NAME = "Skits Heart",
	},
	chinese = {
		NAME = "诙谐之心",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

-- 文字描述
STRINGS.NAMES.AIP_RUBIK_HEART = LANG.NAME

------------------------------- 掉落 -------------------------------
local loot = {
    "drumstick", -- TODO: 掉落瑕疵的飞行图腾蓝图
}

------------------------------- 事件 -------------------------------

------------------------------- 实体 -------------------------------
local function fn()
	local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
	inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

	inst.DynamicShadow:SetSize(.8, .5)

    MakeFlyingCharacterPhysics(inst, 1, .5)

    inst:AddTag("shadowcreature")
	inst:AddTag("gestaltnoloot")
	inst:AddTag("monster")
	inst:AddTag("hostile")
	inst:AddTag("shadow")
	inst:AddTag("notraptrigger")

	inst.AnimState:SetBank("aip_rubik_ghost")
    inst.AnimState:SetBuild("aip_rubik_ghost")
	inst.AnimState:PlayAnimation("idle_loop", true)

    -- inst.AnimState:SetBank("aip_rubik_heart")
    -- inst.AnimState:SetBuild("aip_rubik_heart")
	-- inst.AnimState:PlayAnimation("idle", true)
	-- inst.AnimState:SetRayTestOnBB(true)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("health")
    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "body"

    inst.components.health:SetMaxHealth(TUNING.TOADSTOOL_HEALTH)
    -- inst.components.combat:SetDefaultDamage(TUNING.PERD_DAMAGE)
    -- inst.components.combat:SetAttackPeriod(TUNING.PERD_ATTACK_PERIOD)

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetLoot(loot)

	inst.persists = false

	return inst
end

return Prefab("aip_rubik_heart", fn, assets)
