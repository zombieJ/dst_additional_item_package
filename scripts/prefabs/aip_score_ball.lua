-- 开发模式
local dev_mode = aipGetModConfig("dev_mode") == "enabled"

local assets = {
    Asset("ANIM", "anim/aip_score_ball.zip"),
	Asset("ATLAS", "images/inventoryimages/aip_score_ball.xml"),
}


local language = aipGetModConfig("language")

local LANG_MAP = {
	english = {
		NAME = "D'all",
	},
	chinese = {
		NAME = "豆豆球",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

-- 文字描述
STRINGS.NAMES.AIP_SCORE_BALL = LANG.NAME

---------------------------------- 事件 ----------------------------------
local function onDeath(inst)
	local fx = aipReplacePrefab(inst, "collapse_small")
	fx:SetMaterial("straw")
end

---------------------------------- 实体 ----------------------------------
-- 球体
function ballFn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	-- MakeFlyingCharacterPhysics(inst, 1, .5)
	-- MakeInventoryPhysics(inst)
	MakeInventoryPhysics(inst, 1, .5)
	RemovePhysicsColliders(inst)

	inst:AddTag("FX")
	inst:AddTag("NOCLICK")

	inst.entity:SetCanSleep(false)
	inst.persists = false

	inst.AnimState:SetBank("aip_score_ball")
	inst.AnimState:SetBuild("aip_score_ball")
	inst.AnimState:PlayAnimation("idle")

	return inst
end

local function onHit(inst, attacker)
	if inst.components.aipc_score_ball ~= nil then
		inst.components.aipc_score_ball:Kick(
			attacker,
			3 + math.random(),
			13 + math.random() * 2
		)
	end
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	-- MakeFlyingCharacterPhysics(inst, 1, .5)
	-- MakeInventoryPhysics(inst, 1, .5)
	MakeInventoryPhysics(inst, 1, 0)
	RemovePhysicsColliders(inst)
	inst.Physics:CollidesWith(COLLISION.WORLD)

	inst.entity:AddDynamicShadow()
	inst.DynamicShadow:SetSize(1.5, .5)

	inst:AddTag("aip_score_ball")
	inst:AddTag("hostile") -- 加一个敌对标签，让玩家可以默认攻击

	inst.AnimState:SetBank("aip_score_ball")
	inst.AnimState:SetBuild("aip_score_ball")
	inst.AnimState:PlayAnimation("circle")

	inst.entity:SetPristine()

	-- 客户端同步球体
	inst:AddComponent("aipc_score_ball_effect")

	if not TheNet:IsDedicated() then
		-- 球体马甲
		local ball = SpawnPrefab("aip_score_ball_ball")
		inst:AddChild(ball)
		inst.components.aipc_score_ball_effect.ball = ball
	end

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("health")
	inst.components.health:SetMaxHealth(500)
	inst.components.health.canmurder = false

	inst:AddComponent("combat")
	inst.components.combat.hiteffectsymbol = "ball"
	inst.components.combat:SetOnHit(onHit)

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_score_ball.xml"
	inst.components.inventoryitem.imagename = "aip_score_ball"

	inst:AddComponent("aipc_score_ball")

	inst:ListenForEvent("death", onDeath)

	return inst
end

return	Prefab("aip_score_ball", fn, assets),
		Prefab("aip_score_ball_ball", ballFn, assets)
