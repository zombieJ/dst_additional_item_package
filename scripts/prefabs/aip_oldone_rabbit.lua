-- 开发模式
local dev_mode = aipGetModConfig("dev_mode") == "enabled"

local brain = require("brains/aip_oldone_rabbit_brain")

local assets = {
	Asset("ANIM", "anim/aip_oldone_rabbit.zip"),
	Asset("SOUND", "sound/spider.fsb"),
}

local language = aipGetModConfig("language")

local LANG_MAP = {
	english = {
		NAME = "Mimic Spider",
		DESC = "It's more like a rabbit",
	},
	chinese = {
		NAME = "拟态蜘蛛",
		DESC = "它看起来更像只兔子",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

-- 文字描述
STRINGS.NAMES.AIP_OLDONE_RABBIT = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_RABBIT = LANG.DESC

----------------------------------- 事件 -----------------------------------
local function SwitchSpeed(inst, fast)
	if fast then
		inst.components.locomotor.walkspeed = TUNING.SPIDER_RUN_SPEED * 1.5
		inst.components.locomotor.runspeed = TUNING.SPIDER_RUN_SPEED * 1.5
	else
		inst.components.locomotor.walkspeed = TUNING.SPIDER_WALK_SPEED
		inst.components.locomotor.runspeed = TUNING.SPIDER_WALK_SPEED
	end
end

-- 让周围所有的蜘蛛都回家
local RABBIT_MUST_TAGS = { "aip_oldone_rabbit" }
local RABBIT_CANT_TAGS = { "INLIMBO" }
local function OnAttacked(inst, data)
	local attacker = data and data.attacker

	local home = inst.components.homeseeker ~= nil and inst.components.homeseeker.home or nil
	if home ~= nil and home.components.combat ~= nil and home.components.combat.onhitfn ~= nil then
		home.components.combat.onhitfn(home, attacker, 0)
	end
end

local function goingHome(inst)
	-- SwitchSpeed(inst, false)
end

local function onWentHome(inst)
end

local function SoundPath(inst, event)
    return "dontstarve/creatures/spider/" .. event
end

----------------------------------- 实体 -----------------------------------
local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	MakeCharacterPhysics(inst, 10, .5)

	inst.Transform:SetTwoFaced()
	inst.Transform:SetScale(0.6, 0.6, 0.6)

    inst:AddTag("animal")
    inst:AddTag("prey")
	inst:AddTag("monster")
    inst:AddTag("smallcreature")
    inst:AddTag("canbetrapped")
    inst:AddTag("cattoy")
    inst:AddTag("catfood")
    inst:AddTag("stunnedbybomb")
	inst:AddTag("aip_oldone")
	inst:AddTag("aip_oldone_rabbit")

	inst.AnimState:SetBank("aip_oldone_rabbit")
	inst.AnimState:SetBuild("aip_oldone_rabbit")
	inst.AnimState:PlayAnimation("idle", true)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
    inst.components.locomotor:SetSlowMultiplier(1)
    inst.components.locomotor:SetTriggersCreep(false)
    inst.components.locomotor.pathcaps = { ignorecreep = true }
	SwitchSpeed(inst)

	inst:AddComponent("drownable")

	inst:SetStateGraph("SGspider")

	inst:AddComponent("lootdropper")
    inst.components.lootdropper:AddRandomLoot("monstermeat", 1)
	inst.components.lootdropper:AddRandomLoot("plantmeat", 1)
    inst.components.lootdropper:AddRandomLoot("silk", .5)
    inst.components.lootdropper.numrandomloot = 1

	---------------------
    MakeMediumBurnableCharacter(inst, "body")
    -- MakeMediumFreezableCharacter(inst, "body")
    inst.components.burnable.flammability = TUNING.SPIDER_FLAMMABILITY
    ---------------------

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(dev_mode and 50 or TUNING.SPIDER_HEALTH)

	inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "body"
	inst:ListenForEvent("attacked", OnAttacked)
	inst:ListenForEvent("goinghome", goingHome)
	inst:ListenForEvent("onwenthome", onWentHome)

	inst:AddComponent("knownlocations")

	inst:AddComponent("inspectable")

	inst.bedazzled = true

	MakeHauntablePanic(inst)

	inst:SetBrain(brain)

	inst.SoundPath = SoundPath

	inst:SetIncineratedSound(SoundPath(inst, "die"))

	return inst
end

return Prefab("aip_oldone_rabbit", fn, assets)
