-- 开发模式
local dev_mode = aipGetModConfig("dev_mode") == "enabled"

local brain = require("brains/aip_mud_crab_brain")

local assets = {
	Asset("ANIM", "anim/aip_mud_crab.zip"),
}

local language = aipGetModConfig("language")

local LANG_MAP = {
	english = {
		NAME = "Mud Crab",
		DESC = "So weak...",
	},
	chinese = {
		NAME = "泥蟹",
		DESC = "脆弱的小东西",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

-- 文字描述
STRINGS.NAMES.AIP_MUD_CRAB = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_MUD_CRAB = LANG.DESC

------------------------------- 方法 -------------------------------
local function onNear(inst, player)
	if inst.sg:HasStateTag("poop") then
		inst.sg:RemoveStateTag("busy")
		inst.sg:GoToState("wake")
	end
end

local function onFar(inst, player)
	if not inst.sg:HasStateTag("death") then
		inst.sg:GoToState("hide")
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

	inst.AnimState:SetBank("aip_mud_crab")
	inst.AnimState:SetBuild("aip_mud_crab")
	inst.AnimState:PlayAnimation("poop")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("playerprox")
	inst.components.playerprox:SetDist(10, 12)
	inst.components.playerprox:SetOnPlayerNear(onNear)
    inst.components.playerprox:SetOnPlayerFar(onFar)

	inst:AddComponent("inspectable")

	inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
	inst.components.locomotor.walkspeed = TUNING.SPIDER_RUN_SPEED
	inst.components.locomotor:SetTriggersCreep(false)

	inst:SetStateGraph("SGaip_mud_crab")
	inst:SetBrain(brain)

	inst:AddComponent("sleeper")

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(1)

	inst:AddComponent("combat")
	inst.components.combat.hiteffectsymbol = "chest"

	return inst
end

return Prefab("aip_mud_crab", fn, assets)
