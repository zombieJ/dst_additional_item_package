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

		if data.assets ~= nil then
			inst.AnimState:SetBank(data.name)
			inst.AnimState:SetBuild(data.name)

			inst.AnimState:PlayAnimation("idle", data.onAnimOver == nil)

			inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
			inst.AnimState:SetLayer(LAYER_WORLD_BACKGROUND)
			inst.AnimState:SetSortOrder(0)
		end

		if data.scale ~= nil then
			inst.Transform:SetScale(data.scale, data.scale, data.scale)
		end

		-- 客户端的特效
		if data.fade ~= false and not TheNet:IsDedicated() then
			inst._fade = 1
			inst._fadeIn = -FADE_DES
			inst.periodTask = inst:DoPeriodicTask(0.1, onFade)
		end

		inst.entity:SetPristine()

		if not TheWorld.ismastersim then
			return inst
		end

		if data.range ~= false then
			local range = data.range or 15
			inst:AddComponent("aipc_aura")
			inst.components.aipc_aura.range = range
			inst.components.aipc_aura.bufferName = data.bufferName
			inst.components.aipc_aura.bufferDuration = data.bufferDuration or 3
			inst.components.aipc_aura.bufferFn = data.bufferFn
			inst.components.aipc_aura.bufferRemoveFn = data.bufferRemoveFn
			inst.components.aipc_aura.mustTags = data.mustTags
			inst.components.aipc_aura.noTags = data.noTags
			inst.components.aipc_aura.interval = data.interval or 1.5
			if data.showFX ~= nil then
				inst.components.aipc_aura.showFX = data.showFX
			end

			-- debug 模式下，周围创建一圈光环指示范围
			if data.debug then
				inst:DoTaskInTime(0, function()
					local pos = inst:GetPosition()
					aipSpawnPrefab(inst, "aip_projectile", pos.x - range, 0, pos.z)
					aipSpawnPrefab(inst, "aip_projectile", pos.x + range, 0, pos.z)
					aipSpawnPrefab(inst, "aip_projectile", pos.x, 0, pos.z - range)
					aipSpawnPrefab(inst, "aip_projectile", pos.x, 0, pos.z + range)
				end)
			end
		end

		if data.onAnimOver ~= nil then
			inst:ListenForEvent("animover", data.onAnimOver)
		end

		if data.postFn ~= nil then
			data.postFn(inst)
		end

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
		mustTags = { "_health" },
		noTags = { "INLIMBO", "NOCLICK", "ghost" },
	},
	{	-- 传送光环：并非真实的光环，动画完毕后会发送一个传送效果
		name = "aip_aura_send",
		assets = { Asset("ANIM", "anim/aip_aura_send.zip") },
		range = false, -- 不安装光环组件
		fade = false,
		scale = 1.7,
		onAnimOver = function(inst)
			inst:Remove()
		end,
	},
	{	-- 预见光环：可以直接看到诡影脚步
		name = "aip_aura_see",
		range = 1,
		bufferName = "seeFootPrint",
		showFX = false,
		mustTags = { "_health" },
		noTags = { "INLIMBO", "NOCLICK", "ghost" },
	},
	{	-- 禁锢光环：并非真实的光环，播放一个吸收动画后消失
		name = "aip_aura_lock",
		assets = { Asset("ANIM", "anim/aip_aura_lock.zip") },
		range = false, -- 不安装光环组件
		fade = false,
		scale = 2.5,
		onAnimOver = function(inst)
			inst:Remove()
		end,
	},
	{	-- 传送光环：并非真实的光环，播放一个循环转圈动画
		name = "aip_aura_transfer",
		assets = { Asset("ANIM", "anim/aip_aura_transfer.zip") },
		range = false, -- 不安装光环组件
		scale = 1.5,
	},
	{	-- 剧毒光环：动画播放完后会暂停，其中的单位都会受到持续伤害。结束后消失
		name = "aip_aura_poison",
		assets = { Asset("ANIM", "anim/aip_aura_poison.zip") },
		bufferName = "oldonePoison",
		mustTags = { "_health" },
		noTags = { "INLIMBO", "NOCLICK", "ghost", "flying" },
		showFX = false,
		fade = false,
		range = 5,
		-- debug = true,
		scale = 2,
		interval = 0.4, -- 中毒检测会更快一些
		bufferFn = function(inst, target)
			if target.components.health ~= nil then
				target.components.health:DoDelta(-10, false, inst)
			end

			-- 中毒会减速
			if target.components.locomotor then
				target.components.locomotor:SetExternalSpeedMultiplier(target, "aip_oldonePoison", 0.5)
			end
		end,
		bufferRemoveFn = function(inst, target)
			if target.components.locomotor then
				target.components.locomotor:RemoveExternalSpeedMultiplier(target, "aip_oldonePoison")
			end
		end,
		onAnimOver = function(inst)
			inst:DoTaskInTime(10, inst.Remove)
		end,
	},
}


------------------------------------ 生成 ------------------------------------
local prefabs = {}

for i, data in ipairs(list) do
	table.insert(prefabs, Prefab(data.name, getFn(data), data.assets, data.prefabs))
end

return unpack(prefabs)