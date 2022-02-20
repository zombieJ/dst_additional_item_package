-- 客户端特效
-- 开发模式
local dev_mode = aipGetModConfig("dev_mode") == "enabled"

local assets = {
	Asset("ANIM", "anim/aip_oldone_eye.zip"),
}

----------------------------------- 事件 -----------------------------------
local function onNextAnimate(inst)
	if inst.AnimState:IsCurrentAnimation("open") then
		inst.AnimState:PlayAnimation("idle")
	elseif inst.AnimState:IsCurrentAnimation("close") then
		-- 随机确定是否要重复播放
		if math.random() < 0.6 then
			inst.AnimState:PlayAnimation("open")
		else
			inst:Remove()
		end
	else
		inst.AnimState:PlayAnimation("close")
	end
end

----------------------------------- 实体 -----------------------------------
local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()

	inst:AddTag("NOCLICK")
	inst:AddTag("FX")

	inst.AnimState:SetBank("aip_oldone_eye")
	inst.AnimState:SetBuild("aip_oldone_eye")

	inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
	inst.AnimState:SetLayer(LAYER_WORLD_BACKGROUND)
	inst.AnimState:SetSortOrder(0)

	inst.AnimState:PlayAnimation("open", false)

	inst:ListenForEvent("animover", onNextAnimate)

	return inst
end

return Prefab("aip_oldone_eye", fn, assets)
