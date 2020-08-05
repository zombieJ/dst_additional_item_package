local language = GLOBAL.aipGetModConfig("language")

----------------------------------- 通用组件行为 -----------------------------------
local function triggerComponentAction(player, item, target, targetPoint)
	if item.components.aipc_action ~= nil then
		-- trigger action
		if target ~= nil then
			item.components.aipc_action:DoTargetAction(player, target)
		elseif targetPoint ~= nil then
			item.components.aipc_action:DoPointAction(player, pos)
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

	if GLOBAL.TheNet:GetIsServer() then
		-- server
		triggerComponentAction(doer, item, nil, pos)
	else
		-- client
		SendModRPCToServer(MOD_RPC[env.modname]["aipComponentAction"], doer, item, nil, pos)
	end

	return true
end)

AIPC_POINT_ACTION.distance = 8

AddStategraphActionHandler("wilson", GLOBAL.ActionHandler(AIPC_POINT_ACTION, "quicktele"))
AddStategraphActionHandler("wilson_client", GLOBAL.ActionHandler(AIPC_POINT_ACTION, "quicktele"))

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

AddComponentPostInit("locomotor", function(self)
	function self:PushAction(bufferedaction, run, try_instant)
		GLOBAL.aipPrint(111)
		if bufferedaction == nil then
				return
		end

		GLOBAL.aipPrint(222)
		self.throttle = 1
		local success, reason = bufferedaction:TestForStart()
		if not success then
			GLOBAL.aipPrint(333)
				self.inst:PushEvent("actionfailed", { action = bufferedaction, reason = reason })
				return
		end

		GLOBAL.aipPrint(4444)
		self:Clear()
		local action_pos = bufferedaction:GetActionPoint()
		if bufferedaction.action == GLOBAL.ACTIONS.WALKTO then
				if bufferedaction.target ~= nil then
						self:GoToEntity(bufferedaction.target, bufferedaction, run)
				elseif action_pos then
						self:GoToPoint(nil, bufferedaction, run)
				else
						return
				end
		elseif bufferedaction.action == GLOBAL.ACTIONS.LOOKAT and
				self.inst.components.playercontroller ~= nil then
				local pos = self.inst.components.playercontroller:GetRemotePredictPosition()
				if pos ~= nil and not self.inst.components.playercontroller.directwalking then
						self:GoToPoint(pos, bufferedaction, run)
				else
						self.inst:PushBufferedAction(bufferedaction)
				end
		elseif bufferedaction.forced then
				GLOBAL.aipPrint(555)
				if bufferedaction.action.rangecheckfn ~= nil and
						not bufferedaction.action.rangecheckfn(bufferedaction.doer, bufferedaction.target) then
							GLOBAL.aipPrint(666)
						bufferedaction.target = nil
						bufferedaction.initialtargetowner = nil
				end
				if action_pos ~= nil then
					GLOBAL.aipPrint(777)
						self:GoToPoint(nil, bufferedaction, run, bufferedaction.overridedest)
				end
		elseif bufferedaction.action.instant or bufferedaction.action.do_not_locomote then
			GLOBAL.aipPrint(888)
				self.inst:PushBufferedAction(bufferedaction)
		elseif bufferedaction.target ~= nil then
			GLOBAL.aipPrint(999)
				if bufferedaction.distance ~= nil and bufferedaction.distance >= math.huge then
						--essentially instant
						self.inst:FacePoint(bufferedaction.target.Transform:GetWorldPosition())
						self.inst:PushBufferedAction(bufferedaction)
				else
						self:GoToEntity(bufferedaction.target, bufferedaction, run)
				end
		elseif action_pos == nil then
			GLOBAL.aipPrint("aaa")
				self.inst:PushBufferedAction(bufferedaction)
		elseif bufferedaction.action == GLOBAL.ACTIONS.CASTAOE then
			GLOBAL.aipPrint("bbb")
				if self.inst:GetDistanceSqToPoint(action_pos) <= bufferedaction.distance * bufferedaction.distance then
						self.inst:FacePoint(action_pos:Get())
						self.inst:PushBufferedAction(bufferedaction)
				else
						self:GoToPoint(nil, bufferedaction, run)
						if self.bufferedaction == bufferedaction then
								self.inst:PushEvent("bufferedcastaoe", bufferedaction)
						end
				end
		elseif bufferedaction.distance ~= nil and bufferedaction.distance >= math.huge then
			GLOBAL.aipPrint("ccc")
				--essentially instant
				self.inst:FacePoint(action_pos:Get())
				self.inst:PushBufferedAction(bufferedaction)
		else
			GLOBAL.aipPrint("ddd")
				self:GoToPoint(nil, bufferedaction, run)
		end

		if self.inst.components.playercontroller ~= nil then
			GLOBAL.aipPrint("zzz")
				self.inst.components.playercontroller:OnRemoteBufferedAction()
		end
	end
end)
