local _G = GLOBAL

---------------------------------- 添加飞行器 ----------------------------------
AddPlayerPostInit(function(inst)
	if not inst.components.aipc_flyer_sc then
		inst:AddComponent("aipc_flyer_sc")
	end
end)

---------------------------------- 添加通知器 ----------------------------------
-- player_classified 在服务端每个玩家都有，而在客机只有当前玩家有
AddPrefabPostInit("player_classified", function(inst)
	inst.aip_fly_picker = _G.net_string(inst.GUID, "aip_fly_picker", "aip_fly_picker_dirty")

	-- 根据事件打开窗口
	inst:ListenForEvent("aip_fly_picker_dirty", function()
		local flyTotemId = _G.aipSplit(inst.aip_fly_picker:value(), "|")[2]

		if _G.ThePlayer ~= nil and inst == _G.ThePlayer.player_classified and flyTotemId ~= "" then
			_G.ThePlayer.HUD:OpenAIPDestination(inst, flyTotemId)
		end
	end)
end)

--------------------------------- 添加共享存储 ---------------------------------
local split = "_AIP_FLY_TOTEM_"

-- 向服务器申请列表
env.AddModRPCHandler(env.modname, "aipGetFlyTotemNames", function(player)
	-- 生成姓名表
	local totemNames = { _G.os.time() }

	for i, totem in ipairs(_G.TheWorld.components.world_common_store.flyTotems) do
		local text = totem.components.writeable:GetText()

		-- 插入 名字 + ID
		table.insert(totemNames, text or _G.STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_FLY_TOTEM_UNNAMED)
		table.insert(totemNames, totem.aipId)
	end

	-- 赋值
	local strs = table.concat(totemNames, split)
	player.player_classified.aip_fly_totem_names:set(strs)
end)

-- 获得申请，更新列表
AddPrefabPostInit("player_classified", function(inst)
	-- 共享字段
	inst.aip_fly_totem_names = _G.net_string(inst.GUID, "aip_fly_totem_names", "aip_fly_totem_names_dirty")

	-- 字段变化触发对应弹窗变更
	inst:ListenForEvent("aip_fly_totem_names_dirty", function(inst)
		local totemNames = _G.aipSplit(inst.aip_fly_totem_names:value(), split)

		-- 服务端没有玩家
		if _G.ThePlayer and _G.ThePlayer.player_classified == inst and _G.ThePlayer.aipOnTotemFetch then
			-- 去掉第一个，那是时间戳
			local nameAndIds = _G.aipTableSlice(totemNames, 2, #totemNames)
			local names = {}
			local ids = {}

			-- 填充数据
			for i, str in ipairs(nameAndIds) do
				if math.mod(i, 2) == 1 then
					table.insert(names, str)
				else
					table.insert(ids, str)
				end
			end

			_G.ThePlayer.aipOnTotemFetch(names, ids)
		end
	end)
end)

----------------------------------- 添加动作 -----------------------------------
-- 服务端组件
local function flyToTotem(player, totemId)
	if player.components.aipc_flyer_sc then
		local totems = _G.aipFilterTable(_G.TheWorld.components.world_common_store.flyTotems, function(t)
			return t.aipId == totemId
		end)

		local totem = totems[1]
		if totem ~= nil then
			player.components.aipc_flyer_sc:FlyTo(totem)
		end
	end
end

env.AddModRPCHandler(env.modname, "aipFlyToTotem", function(player, index)
	flyToTotem(player, index)
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
	local dist = 32 -- 16 -- 8

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
