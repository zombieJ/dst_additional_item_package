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
	-- 全局注册一下 Buffer
	if data.bufferName ~= nil then
		aipBufferRegister(data.bufferName, {
			fn = data.bufferFn,
			-- 中毒减速
			startFn = data.bufferStartFn,
			endFn = data.bufferEndFn,
			showFX = data.showFX,
		})
	end

	-- 返回函数哦
	local function fn()
		local inst = CreateEntity()

		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddNetwork()

		if data.assets ~= nil then
			inst.AnimState:SetBank(data.build or data.name)
			inst.AnimState:SetBuild(data.build or data.name)

			inst.AnimState:PlayAnimation(data.anim or "idle", data.onAnimOver == nil)

			inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
			-- inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGroundFixed)
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

		inst:AddTag("NOCLICK")
		inst:AddTag("FX")

		-- 服务端同步
		if data.pristine ~= false then
			inst.entity:SetPristine()
		end

		inst.persists = false

		if not TheWorld.ismastersim then
			return inst
		end

		if data.range ~= false then
			local range = data.range or 15
			inst:AddComponent("aipc_aura")
			inst.components.aipc_aura.range = range
			inst.components.aipc_aura.bufferName = data.bufferName
			inst.components.aipc_aura.bufferDuration = data.bufferDuration or 3
			inst.components.aipc_aura.mustTags = data.mustTags
			inst.components.aipc_aura.noTags = data.noTags
			inst.components.aipc_aura.interval = data.interval or 1.5
			inst.components.aipc_aura:Start()

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
			-- 只会触发一次，延迟一点以防止还需要读一些额外的数据
			inst:DoTaskInTime(0.01, function()
				local function callback()
					inst:RemoveEventCallback("animover", callback)
					data.onAnimOver(inst)
				end

				inst:ListenForEvent("animover", callback)
			end)
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
		noTags = { "INLIMBO", "NOCLICK", "ghost", "flying", "aip_oldone" },
		showFX = false,
		fade = false,
		range = 5,
		-- debug = true,
		scale = 2,
		interval = 0.33, -- 中毒检测会更快一些
		bufferDuration = 0.8,
		bufferFn = function(inst, target, info)
			if target.components.health ~= nil and not target.components.health:IsDead() then
				-- 伤害来源不能是光环，否则会死循环
				target.components.health:DoDelta(-7 * info.interval, false)
			end
		end,
		-- 中毒减速
		bufferStartFn = function(inst, target)
			-- 受到攻击伤害，这样玩家会跳一下
			if target.components.combat ~= nil then
				target.components.combat:GetAttacked(inst, 15)
			end

			if target.components.locomotor then
				target.components.locomotor:SetExternalSpeedMultiplier(target, "aip_oldonePoison", 0.6)
			end
		end,
		bufferEndFn = function(inst, target)
			if target.components.locomotor then
				target.components.locomotor:RemoveExternalSpeedMultiplier(target, "aip_oldonePoison")
			end
		end,
		onAnimOver = function(inst)
			local duration = inst._aipDuration or 12 -- 允许被覆盖

			inst:DoTaskInTime(duration, function()
				ErodeAway(inst, 0.5)
			end)
		end,
	},

	-----------------------------------------------------------------------------------------
	{	-- 古神光环：并非真实的光环，播放一个循环转圈动画
		name = "aip_aura_smiling",
		assets = { Asset("ANIM", "anim/aip_aura_smiling.zip") },
		range = false, -- 不安装光环组件
		scale = 1.25,
	},
	{	-- 古神光环：并非真实的光环，播放一个循环转圈动画
		name = "aip_aura_smiling_axe",
		build = "aip_aura_smiling",
		anim = "axe",
		assets = { Asset("ANIM", "anim/aip_aura_smiling.zip") },
		range = false, -- 不安装光环组件
		scale = 1.25,
	},
	{	-- 古神光环：并非真实的光环，播放一个循环转圈动画
		name = "aip_aura_smiling_attack",
		build = "aip_aura_smiling",
		anim = "attack",
		assets = { Asset("ANIM", "anim/aip_aura_smiling.zip") },
		range = false, -- 不安装光环组件
		scale = 1.25,
	},
	{	-- 古神光环：并非真实的光环，播放一个循环转圈动画
		name = "aip_aura_smiling_mine",
		build = "aip_aura_smiling",
		anim = "mine",
		assets = { Asset("ANIM", "anim/aip_aura_smiling.zip") },
		range = false, -- 不安装光环组件
		scale = 1.25,
	},
	{	-- 纠缠粒子光环 —— 蓝：并非真实的光环，播放一个循环转圈动画
		name = "aip_aura_entangled_blue",
		build = "aip_aura_entangled",
		anim = "blue",
		assets = { Asset("ANIM", "anim/aip_aura_entangled.zip") },
		range = false, -- 不安装光环组件
		scale = .8,
	},
	{	-- 纠缠粒子光环 —— 橙：并非真实的光环，播放一个循环转圈动画
		name = "aip_aura_entangled_orange",
		build = "aip_aura_entangled",
		anim = "orange",
		assets = { Asset("ANIM", "anim/aip_aura_entangled.zip") },
		range = false, -- 不安装光环组件
		scale = .8,
	},
	{	-- 回声粒子光环 —— 并非真实的光环，播放一个循环转圈动画
		name = "aip_aura_entangled_echo",
		build = "aip_aura_entangled",
		anim = "echo",
		assets = { Asset("ANIM", "anim/aip_aura_entangled.zip") },
		range = false, -- 不安装光环组件
		scale = 1,
	},
	{	-- 回旋光环：并非真实的光环，播放一个循环转圈动画（回旋铁球）
		name = "aip_aura_steel",
		assets = { Asset("ANIM", "anim/aip_aura_steel.zip") },
		range = false, -- 不安装光环组件
		scale = 1.25,
	},
	{	-- 触发光环：并非真实的光环，播放一个循环转圈动画（粒子触发的标记）
		name = "aip_aura_trigger",
		assets = { Asset("ANIM", "anim/aip_aura_trigger.zip") },
		range = false, -- 不安装光环组件
		scale = 1.25,
	},
	{	-- 恐惧光环：并非真实的光环，播放一个扩散动画后消失
		name = "aip_aura_scared",
		assets = { Asset("ANIM", "anim/aip_aura_scared.zip") },
		range = false, -- 不安装光环组件
		fade = false,
		scale = 2,
		onAnimOver = function(inst)
			inst:Remove()
		end,
	},
	{	-- BUFF 光环：并非真实的光环，提供一个颜色底，用于动物抓捕的等级识别
		name = "aip_aura_buffer",
		build = "aip_buffer",
		assets = { Asset("ANIM", "anim/aip_buffer.zip") },
		range = false, -- 不安装光环组件
		scale = 1,
		pristine = false, -- 客户端 Only
	},

	{	-- 黑洞光环：并非真实的光环，播放一个循环的动画
		name = "aip_aura_blackhole",
		assets = { Asset("ANIM", "anim/aip_aura_blackhole.zip") },
		range = false, -- 不安装光环组件
		fade = false,
		scale = 2,
		postFn = function(inst)
			inst.AnimState:PlayAnimation("enter")
			inst.AnimState:PushAnimation("idle", true)

			-- 过一会儿自己离开
			inst:DoTaskInTime(6, function()
				inst.AnimState:PlayAnimation("end")
				inst:ListenForEvent("animover", inst.Remove)
			end)
		end,
	},
}

-- 杀神光环：造成伤害变多
local function genJohnWickAura(name)
	return {
		name = name,
		bufferName = "aip_pet_johnWick",
		-- 杀神等级提供一下
		bufferStartFn = function(source, inst, info)
			if
				source ~= nil and source.parent ~= nil and
				source.parent.components.aipc_pet_owner ~= nil
			then
				local skillInfo, skillLv = source.parent.components.aipc_pet_owner:GetSkillInfo("johnWick")
				if skillInfo ~= nil then
					local dmg = skillInfo.multi * skillLv
					info.data.dmg = math.max(info.data.dmg or 0, dmg)
				end
			end
		end,
		showFX = true,
		mustTags = { "player" },
		noTags = { "INLIMBO", "NOCLICK", "ghost" },
	}
end

local wickAruaSingle = genJohnWickAura("aip_aura_john_wick_single")
wickAruaSingle.range = 0.1
table.insert(list, wickAruaSingle)

local wickArua = genJohnWickAura("aip_aura_john_wick")
wickArua.assets = { Asset("ANIM", "anim/aip_aura_john_wick.zip") }
table.insert(list, wickArua)

------------------------------------ 生成 ------------------------------------
local prefabs = {}

for i, data in ipairs(list) do
	table.insert(prefabs, Prefab(data.name, getFn(data), data.assets, data.prefabs))
end

return unpack(prefabs)