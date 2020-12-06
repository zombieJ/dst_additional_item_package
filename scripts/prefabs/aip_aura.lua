------------------------------------ 配置 ------------------------------------
-- 雕塑关闭
local additional_chesspieces = aipGetModConfig("additional_chesspieces")
if additional_chesspieces ~= "open" then
	return nil
end

------------------------------------ 函数 ------------------------------------

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

		inst.entity:SetPristine()

		if not TheWorld.ismastersim then
			return inst
		end

		return inst
	end

	return fn
end

------------------------------------ 列表 ------------------------------------
local list = {
	{	-- 痛苦光环
		name = "aip_aura_cost",
		assets = { Asset("ANIM", "anim/aip_aura_cost.zip") },
	},
}


------------------------------------ 生成 ------------------------------------
local prefabs = {}

for i, data in ipairs(list) do
	table.insert(prefabs, Prefab(data.name, getFn(data), data.assets, data.prefabs))
end

return unpack(prefabs)