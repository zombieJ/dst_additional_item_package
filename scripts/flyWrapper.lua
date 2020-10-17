local _G = GLOBAL

---------------------------------- 添加飞行器 ----------------------------------
AddPlayerPostInit(function(inst)
	if not inst.components.aipc_flyer_sc then
		inst:AddComponent("aipc_flyer_sc")
	end
end)

--------------------------------- 添加共享存储 ---------------------------------
local split = "_AIP_FLY_TOTEM_"

AddPrefabPostInit("player_classified", function(inst)
	-- 共享字段
	inst.aip_fly_totem_names = _G.net_string(inst.GUID, "aip_fly_totem_names", "aip_fly_totem_names_dirty")

	-- 字段变化触发对应弹窗变更
	inst:ListenForEvent("aip_fly_totem_names_dirty", function(inst)
		local totemNames = _G.aipSplit(inst.aip_fly_totem_names:value(), split)

		-- 服务端没有玩家
		if _G.ThePlayer and _G.ThePlayer.player_classified == inst and _G.ThePlayer.aipOnTotemFetch then
			-- 去掉第一个，那是时间戳
			_G.ThePlayer.aipOnTotemFetch(_G.aipTableSlice(totemNames, 2, #totemNames))
		end
	end)
end)

env.AddModRPCHandler(env.modname, "aipGetFlyTotemNames", function(player)
	-- 生成姓名表
	local totemNames = { _G.os.time() }

	for i, totem in ipairs(_G.TheWorld.components.world_common_store.flyTotems) do
		local text = totem.components.writeable:GetText()
		table.insert(totemNames, text or _G.STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_FLY_TOTEM_UNNAMED)
	end

	-- 赋值
	local strs = table.concat(totemNames, split)
	player.player_classified.aip_fly_totem_names:set(strs)
end)

----------------------------------- 添加动作 -----------------------------------
-- 服务端组件
local function flyToTotem(player, index)
	if player.components.aipc_flyer_sc then
		local totem = _G.TheWorld.components.world_common_store.flyTotems[index]

		player.components.aipc_flyer_sc:FlyTo(totem)
	end
end

env.AddModRPCHandler(env.modname, "aipFlyToTotem", function(player, index)
	flyToTotem(player, index)
end)

-- 添加飞行动作
local AIPC_FLY_ACTION = env.AddAction("AIPC_FLY_ACTION", _G.STRINGS.ACTIONS.AIP_USE, function(act)
	local doer = act.doer
	local target = act.target

	if target and target.components.aipc_fly_picker_client ~= nil then
		target.components.aipc_fly_picker_client:ShowPicker(doer)
	end

	return true
end)

AddStategraphActionHandler("wilson", _G.ActionHandler(AIPC_FLY_ACTION, "doshortaction"))
AddStategraphActionHandler("wilson_client", _G.ActionHandler(AIPC_FLY_ACTION, "doshortaction"))

-- 未飞行选择器
env.AddComponentAction("SCENE", "aipc_fly_picker_client", function(inst, doer, actions, right)
	if not inst or not right then
		return
	end

	table.insert(actions, _G.ACTIONS.AIPC_FLY_ACTION)
end)

----------------------------------- 添加动作 -----------------------------------
-- -- 监听玩家状态
-- local function AddPlayerSgPostInit(fn)
--     AddStategraphPostInit('wilson', fn)
--     AddStategraphPostInit('wilson_client', fn)
-- end

local function normalize(angle)
    while angle > 360 do
        angle = angle - 360
    end
    while angle < 0 do
        angle = angle + 360
    end
    return angle
end

-- 镜头锁定
AddClassPostConstruct("cameras/followcamera", function(inst)
	local dist = 8

	function inst:SetFlyView(flying)
		if flying then
			-- 锁定距离
			self.mindist = dist
			self.maxdist = dist + 20
			self.pangain = 999999 -- 完全跟随玩家

			self._aipOriginHeadingtarget = self.headingtarget
		else
			self.headingtarget = self._aipOriginHeadingtarget
			self:SetDefault()
		end

		self._aipFlying = flying
	end

	local OriginUpdate = inst.Update
	function inst:Update(dt, ...)
		-- 缓慢变更到目标距离
		if self._aipFlying then
			self.distance = self.distance * 0.75 + dist * 0.25
			self.headingtarget = normalize(180 - _G.ThePlayer:GetRotation())
		end

		return OriginUpdate(self, dt, _G.unpack(arg))
	end
end)
