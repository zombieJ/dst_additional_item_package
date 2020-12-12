------------------------------------ 配置 ------------------------------------
-- 雕塑关闭
local additional_chesspieces = aipGetModConfig("additional_chesspieces")
if additional_chesspieces ~= "open" then
	return nil
end

------------------------------------ 函数 ------------------------------------
local FADE_DES = 0.04

local function onFade(inst)
	inst._fade = inst._fade + inst._fadeIn
	if inst._fade < 0.4 then
		inst._fadeIn = FADE_DES
	elseif inst._fade >= 1 then
		inst._fadeIn = -FADE_DES
	end

	inst.AnimState:SetMultColour(1, 1, 1, inst._fade)
end

local function getFn(data)
	-- 返回函数哦
	local function fn()
		local inst = CreateEntity()

		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddNetwork()

		inst.AnimState:SetBank(data.name)
		inst.AnimState:SetBuild(data.name)

		inst.AnimState:PlayAnimation("idle", true)

		inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
		inst.AnimState:SetLayer(LAYER_WORLD_BACKGROUND)
		inst.AnimState:SetSortOrder(2)

		-- 客户端的特效
		if not TheNet:IsDedicated() then
			inst._fade = 1
			inst._fadeIn = -FADE_DES
			inst.periodTask = inst:DoPeriodicTask(0.1, onFade)
		end

		inst.entity:SetPristine()

		if not TheWorld.ismastersim then
			return inst
		end

		inst:AddComponent("aipc_aura")
		inst.components.aipc_aura.range = data.range or 6
		inst.components.aipc_aura.bufferName = data.bufferName
		inst.components.aipc_aura.bufferDuration = data.bufferDuration or 1
		inst.components.aipc_aura.bufferFn = data.bufferFn

		return inst
	end

	return fn
end

------------------------------------ 列表 ------------------------------------
local list = {
	{	-- 痛苦光环：所有生物伤害都变多，依赖于 health 注入
		name = "aip_aura_cost",
		assets = { Asset("ANIM", "anim/aip_aura_cost.zip") },
		bufferName = "healthCost",
	},
}


------------------------------------ 生成 ------------------------------------
local prefabs = {}

for i, data in ipairs(list) do
	table.insert(prefabs, Prefab(data.name, getFn(data), data.assets, data.prefabs))
end

return unpack(prefabs)