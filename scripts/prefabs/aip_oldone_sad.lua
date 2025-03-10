-- 开发模式
local dev_mode = aipGetModConfig("dev_mode") == "enabled"

local brain = require("brains/aip_oldone_sad_brain")

local assets = {
	Asset("ANIM", "anim/aip_oldone_sad.zip"),
}

local language = aipGetModConfig("language")

local LANG_MAP = {
	english = {
		NAME = "Familiar Ghost",
	},
	chinese = {
		NAME = "眷属幽魂",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

-- 文字描述
STRINGS.NAMES.AIP_OLDONE_SAD = LANG.NAME

local SCALE = 0.6

-- 杀死后恢复生命值
local function onDeath(inst, data)
	local afflicter = aipGet(data, "afflicter")
	if
		afflicter ~= nil and
		afflicter:IsValid() and
		afflicter.components.health ~= nil and
		not afflicter.components.health:IsDead() and
		afflicter.components.sanity ~= nil
	then
		afflicter.components.sanity:DoDelta(inst._aip_sanity or 0)
	end
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	MakeFlyingCharacterPhysics(inst, 1, .5)

	inst.Transform:SetTwoFaced()
	inst.Transform:SetScale(SCALE,SCALE,SCALE)

	inst:AddTag("monster")
	inst:AddTag("hostile")
	inst:AddTag("notraptrigger")
	inst:AddTag("aip_oldone_sad")

	inst.AnimState:SetBank("aip_oldone_sad")
	inst.AnimState:SetBuild("aip_oldone_sad")
	inst.AnimState:PlayAnimation("idle_loop", true)
	-- inst.AnimState:SetMultColour(1, 1, 1, .7)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("homeseeker")

	inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
	inst.components.locomotor.walkspeed = TUNING.CRAWLINGHORROR_SPEED / 3
	inst.components.locomotor:SetTriggersCreep(false)
	inst.components.locomotor.pathcaps = { ignorecreep = true }

	inst:SetStateGraph("SGaip_oldone_sad")
	inst:SetBrain(brain)

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(dev_mode and 1 or 66)

	inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "body"

	inst:ListenForEvent("death", onDeath)

	inst.persists = false

	return inst
end

return Prefab("aip_oldone_sad", fn, assets)
