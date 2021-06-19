-- 开发模式
local dev_mode = aipGetModConfig("dev_mode") == "enabled"

local assets = {
    Asset("ANIM", "anim/aip_score_ball.zip"),
}


local language = aipGetModConfig("language")

local LANG_MAP = {
	english = {
		NAME = "'D'all",
	},
	chinese = {
		NAME = "豆豆球",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

-- 文字描述
STRINGS.NAMES.AIP_SCORE_BALL = LANG.NAME

local function onthrown(inst)
    -- inst:AddTag("NOCLICK")
    -- inst.persists = false

    -- inst.AnimState:PlayAnimation("spin_loop", true)

    -- inst.Physics:SetMass(1)
    -- inst.Physics:SetCapsule(0.2, 0.2)
    -- inst.Physics:SetFriction(0)
    -- inst.Physics:SetDamping(0)
    -- inst.Physics:SetCollisionGroup(COLLISION.CHARACTERS)
    -- inst.Physics:ClearCollisionMask()
    -- inst.Physics:CollidesWith(COLLISION.GROUND)
    -- inst.Physics:CollidesWith(COLLISION.OBSTACLES)
    -- inst.Physics:CollidesWith(COLLISION.ITEMS)
end

local function onHit(inst, attacker)
	if inst.components.complexprojectile == nil then
		inst:AddComponent("complexprojectile")
		inst.components.complexprojectile:SetHorizontalSpeed(15)
		inst.components.complexprojectile:SetGravity(-35)
		-- inst.components.complexprojectile:SetLaunchOffset(Vector3(.25, 1, 0))
		-- inst.components.complexprojectile:SetOnLaunch(onthrown)
		-- inst.components.complexprojectile:SetOnHit(OnHitWater)
	end

	-- 计算下一个目标地址
	local srcPos = inst:GetPosition()
	local angle = aipGetAngle(attacker:GetPosition(), srcPos)
	local radius = angle / 180 * PI
	local tgtPos = Vector3(srcPos.x + math.cos(radius), srcPos.y, srcPos.z + math.sin(radius))

	inst.components.complexprojectile:Launch(tgtPos, attacker)
end


local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	-- MakeProjectilePhysics(inst)
	MakeInventoryPhysics(inst)
	inst.Physics:SetMass(1)
	inst.Physics:SetCapsule(0.2, 0.2)
	inst.Physics:SetFriction(0)
	inst.Physics:SetDamping(0)
	inst.Physics:SetCollisionGroup(COLLISION.CHARACTERS)
	inst.Physics:ClearCollisionMask()
	inst.Physics:CollidesWith(COLLISION.GROUND)
	inst.Physics:CollidesWith(COLLISION.OBSTACLES)
	inst.Physics:CollidesWith(COLLISION.ITEMS)

	-- 遇到非人类攻击需要被打破

	inst.AnimState:SetBank("aip_score_ball")
	inst.AnimState:SetBuild("aip_score_ball")
	inst.AnimState:PlayAnimation("idle")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	-- inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
	-- inst.components.locomotor:EnableGroundSpeedMultiplier(false)
	-- inst.components.locomotor:SetTriggersCreep(false)
	-- inst.components.locomotor.pathcaps = { ignorewalls = true, ignorecreep = true, allowocean = true }
	-- inst.components.locomotor.walkspeed = TUNING.CRAWLINGHORROR_SPEED

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(9999999)

	inst:AddComponent("combat")
	inst.components.combat.hiteffectsymbol = "ball"
	inst.components.combat:SetOnHit(onHit)

	return inst
end

return Prefab("aip_score_ball", fn, assets)
