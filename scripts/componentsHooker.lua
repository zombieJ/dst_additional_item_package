local language = GLOBAL.aipGetModConfig("language")

----------------------------------- 通用组件行为 -----------------------------------
local function triggerComponentAction(player, item, target, targetPoint)
	if item.components.aipc_action ~= nil then
		-- trigger action
		if target ~= nil then
			item.components.aipc_action:DoTargetAction(doer, target)
		elseif targetPoint ~= nil then
			item.components.aipc_action:DoPointAction(doer, pos)
		end
	end
end

env.AddModRPCHandler(env.modname, "aipComponentAction", function(player, item, target, targetPoint)
	triggerComponentAction(player, item, target, targetPoint)
end)

-------------------- 组合行为
local LANG_MAP = {
	english = {
		GIVE = "Give",
		CAST = "Cast",
	},
	chinese = {
		GIVE = "给予",
		CAST = "释放",
	},
}
local LANG = LANG_MAP[language] or LANG_MAP.english

-- 注册一个 action
local AIPC_ACTION = env.AddAction("AIPC_ACTION", LANG.GIVE, function(act)
	local doer = act.doer
	local item = act.invobject
	local target = act.target

	if GLOBAL.TheNet:GetIsServer() then
		-- server
		triggerComponentAction(doer, item, target, nil)
	else
		-- client
		SendModRPCToServer(MOD_RPC[env.modname]["aipComponentAction"], doer, item, target, nil)
	end

	return true
end)
AddStategraphActionHandler("wilson", GLOBAL.ActionHandler(AIPC_ACTION, "dolongaction"))
AddStategraphActionHandler("wilson_client", GLOBAL.ActionHandler(AIPC_ACTION, "dolongaction"))

-- 为组件绑定 action
env.AddComponentAction("USEITEM", "aipc_action_client", function(inst, doer, target, actions, right)
	if not inst or not target then
		return
	end

	if inst.components.aipc_action_client:CanActOn(doer, target) then
		table.insert(actions, GLOBAL.ACTIONS.AIPC_ACTION)
	end
end)

-------------------- 施法行为 https://www.zybuluo.com/longfei/note/600841
-- 注册一个 action
local AIPC_POINT_ACTION = env.AddAction("AIPC_POINT_ACTION", LANG.CAST, function(act)
	local doer = act.doer
	local item = act.invobject
	local pos = act.pos

	GLOBAL.aipPrint("DO ACTION!!!")

	if GLOBAL.TheNet:GetIsServer() then
		-- server
		triggerComponentAction(doer, item, nil, pos)
	else
		-- client
		SendModRPCToServer(MOD_RPC[env.modname]["aipComponentAction"], doer, item, nil, pos)
	end

	return true
end)

AddStategraphActionHandler("wilson", GLOBAL.ActionHandler(AIPC_POINT_ACTION, "throw"))
AddStategraphActionHandler("wilson_client", GLOBAL.ActionHandler(AIPC_POINT_ACTION, "throw"))

-- 为组件绑定 action
env.AddComponentAction("POINT", "aipc_action_client", function(inst, doer, pos, actions, right)
	if not inst or not pos or not right then
		return
	end

	if inst.components.aipc_action_client:CanActOnPoint(doer, pos) then
		table.insert(actions, GLOBAL.ACTIONS.AIPC_POINT_ACTION)
	end
end)


------------------------------------- 特殊处理 -------------------------------------
-- 额外触发一个生命值时间出来
AddComponentPostInit("health", function(self)
	local origiDoDelta = self.DoDelta

	function self:DoDelta(amount, ...)
		local data = { amount = amount }
		self.inst:PushEvent("aip_healthdelta", data)

		origiDoDelta(self, data.amount, GLOBAL.unpack(arg))
	end
end)

AddComponentPostInit("playercontroller", function(self)
	local origiOnRightClick = self.OnRightClick

	-- PlayerController:DoAction(buffaction)

	function self:OnRightClick(down)
		GLOBAL.aipPrint("DO RIGHT!!!", down)

		if not self:UsingMouse() then
			return
		elseif not down then
				if self:IsEnabled() then
					GLOBAL.aipPrint("1111")
						self:RemoteStopControl(CONTROL_SECONDARY)
				end
				return
		end

		self.startdragtime = nil

		if self.placer_recipe ~= nil then
			GLOBAL.aipPrint("22222")
				self:CancelPlacement()
				return
		elseif self:IsAOETargeting() then
			GLOBAL.aipPrint("33333")
				self:CancelAOETargeting()
				return
		elseif not self:IsEnabled() or GLOBAL.TheInput:GetHUDEntityUnderMouse() ~= nil then
			GLOBAL.aipPrint("4444")
				return
		end

		local act = self:GetRightMouseAction()
		if act == nil then
			GLOBAL.aipPrint("55555")
				self.inst.replica.inventory:ReturnActiveItem()
				self:TryAOETargeting()
		else
			GLOBAL.aipPrint("66666")
				if self.reticule ~= nil and self.reticule.reticule ~= nil then
					GLOBAL.aipPrint("77777")
						self.reticule:PingReticuleAt(act:GetActionPoint())
				end
				if self.deployplacer ~= nil and act.action == ACTIONS.DEPLOY then
					GLOBAL.aipPrint("7888888")
						act.rotation = self.deployplacer.Transform:GetRotation()
				end
				if not self.ismastersim then
					GLOBAL.aipPrint("999999")
						local position = GLOBAL.TheInput:GetWorldPosition()
						local mouseover = GLOBAL.TheInput:GetWorldEntityUnderMouse()
						local controlmods = self:EncodeControlMods()
						local platform, pos_x, pos_z = self:GetPlatformRelativePosition(position.x, position.z)
						if self.locomotor == nil then
							GLOBAL.aipPrint("1010101")
								self.remote_controls[CONTROL_SECONDARY] = 0
								SendRPCToServer(RPC.RightClick, act.action.code, pos_x, pos_z, mouseover, act.rotation ~= 0 and act.rotation or nil, nil, controlmods, act.action.canforce, act.action.mod_name, platform, platform ~= nil)
						elseif act.action ~= ACTIONS.WALKTO and self:CanLocomote() then
							GLOBAL.aipPrint("aaaaaa")
								act.preview_cb = function()
									GLOBAL.aipPrint("ccccc")
										self.remote_controls[CONTROL_SECONDARY] = 0
										local isreleased = not GLOBAL.TheInput:IsControlPressed(CONTROL_SECONDARY)
										SendRPCToServer(RPC.RightClick, act.action.code, pos_x, pos_z, mouseover, act.rotation ~= 0 and act.rotation or nil, isreleased, controlmods, nil, act.action.mod_name, platform, platform ~= nil)
								end
						end
				end
				self:DoAction(act)
		end
	end
end)