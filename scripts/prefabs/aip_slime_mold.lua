-- 开发模式
local dev_mode = aipGetModConfig("dev_mode") == "enabled"

local brain = require("brains/aip_slime_mold_brain")

local assets = {
	Asset("ANIM", "anim/aip_slime_mold.zip"),
}

local language = aipGetModConfig("language")

local LANG_MAP = {
	english = {
		NAME = "Omega Slime Mold",
		DESC = "A miracle of life",
	},
	chinese = {
		NAME = "欧米伽黏菌团",
		DESC = "奇迹般获得生命的神物菌团",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

-- 文字描述
STRINGS.NAMES.AIP_SLIME_MOLD = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_SLIME_MOLD = LANG.DESC

------------------------------- 方法 -------------------------------
local function onDeath(inst, data)
	local killer = data ~= nil and data.afflicter or nil

    -- if killer ~= nil and aipBufferExist(killer, "aip_see_eyes") then
	-- 	aipSpawnPrefab(killer, "aip_aura_blackhole")

	if killer ~= nil and killer:HasTag("player") and not aipBufferExist(killer, "aip_black_immunity") then
		killer.sg:GoToState("aip_sink_space")
	end
end

------------------------------- 实体 -------------------------------
local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	MakeFlyingCharacterPhysics(inst, 1, .5)

	inst.Transform:SetTwoFaced()

	inst:AddTag("animal")
	inst:AddTag("prey")
	inst:AddTag("smallcreature")

	inst.AnimState:SetBank("aip_slime_mold")
	inst.AnimState:SetBuild("aip_slime_mold")
	inst.AnimState:PlayAnimation("idle_loop", true)

	inst:AddComponent("aipc_petable")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("inspectable")

	inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
	inst.components.locomotor.walkspeed = TUNING.SPIDER_WALK_SPEED
	inst.components.locomotor:EnableGroundSpeedMultiplier(false)
    inst.components.locomotor:SetTriggersCreep(false)

	inst:AddComponent("lootdropper")

	inst:SetStateGraph("SGaip_slime_mold")
	inst:SetBrain(brain)

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(1)

	inst:AddComponent("combat")
	inst.components.combat.hiteffectsymbol = "chest"

	inst:ListenForEvent("death", onDeath)

	return inst
end

return Prefab("aip_slime_mold", fn, assets)
