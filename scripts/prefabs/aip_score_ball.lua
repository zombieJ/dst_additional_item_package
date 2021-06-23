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

-- 阴影
function shadowFn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	inst:AddTag("FX")

	inst.entity:SetCanSleep(false)
	inst.persists = false

	inst.AnimState:SetBank("aip_score_ball")
	inst.AnimState:SetBuild("aip_score_ball")
	inst.AnimState:PlayAnimation("shadow")

	inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
	inst.AnimState:SetLayer(LAYER_WORLD_BACKGROUND)

	return inst
end

-- 球体
function ballFn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	inst:AddTag("FX")

	inst.entity:SetCanSleep(false)
	inst.persists = false

	inst.AnimState:SetBank("aip_score_ball")
	inst.AnimState:SetBuild("aip_score_ball")
	inst.AnimState:PlayAnimation("idle")

	return inst
end

local function onHit(inst, attacker)
	if inst.components.aipc_score_ball ~= nil then
		inst.components.aipc_score_ball:Launch(attacker)
	end
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	-- MakeFlyingCharacterPhysics(inst, 1, .5)
	MakeInventoryPhysics(inst, 1, .5)
	RemovePhysicsColliders(inst)
	inst.Physics:CollidesWith(COLLISION.WORLD)

	-- 遇到非人类攻击需要被打破

	inst.AnimState:SetBank("aip_score_ball")
	inst.AnimState:SetBuild("aip_score_ball")
	inst.AnimState:PlayAnimation("circle")

	-- inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
	-- inst.AnimState:SetLayer(LAYER_WORLD_BACKGROUND)
	-- inst.AnimState:SetSortOrder(2)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("aipc_score_ball")

	inst:AddComponent("health")
	inst.components.health:SetMaxHealth(9999999)

	inst:AddComponent("combat")
	inst.components.combat.hiteffectsymbol = "ball"
	inst.components.combat:SetOnHit(onHit)

	-- 阴影马甲
	local shadow = SpawnPrefab("aip_score_ball_shadow")
	inst:AddChild(shadow)
	inst._aip_shadow = shadow

	-- 球体马甲
	local ball = SpawnPrefab("aip_score_ball_ball")
	inst:AddChild(ball)
	inst._aip_ball = ball

	return inst
end

return	Prefab("aip_score_ball", fn, assets),
		Prefab("aip_score_ball_shadow", shadowFn, assets),
		Prefab("aip_score_ball_ball", ballFn, assets)
