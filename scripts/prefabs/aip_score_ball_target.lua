-- 开发模式
local dev_mode = aipGetModConfig("dev_mode") == "enabled"

local assets = {
    Asset("ANIM", "anim/aip_score_ball_target.zip"),
}


local language = aipGetModConfig("language")

local LANG_MAP = {
	english = {
		NAME = "Subject Matter",
	},
	chinese = {
		NAME = "标的物",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

-- 文字描述
STRINGS.NAMES.AIP_SCORE_BALL_TARGET = LANG.NAME

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddPhysics()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	inst.Physics:SetCollisionGroup(COLLISION.CHARACTERS)
	inst.Physics:ClearCollisionMask()

	inst.AnimState:SetBank("aip_score_ball_target")
	inst.AnimState:SetBuild("aip_score_ball_target")
	inst.AnimState:PlayAnimation("idle")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:DoTaskInTime(0.1, function()
		local x, y, z = inst.Transform:GetWorldPosition()
		inst.Physics:Teleport(x, 5, z)
	end)

	return inst
end

return	Prefab("aip_score_ball_target", fn, assets)
