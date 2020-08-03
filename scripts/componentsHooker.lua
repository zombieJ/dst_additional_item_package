local language = GLOBAL.aipGetModConfig("language")

----------------------------------- 通用组件行为 -----------------------------------
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

	if item.components.aipc_action ~= nil then
		item.components.aipc_action:DoTargetAction(doer, target)
		return true
	end

	return false, "INUSE"
end)
AddStategraphActionHandler("wilson", GLOBAL.ActionHandler(AIPC_ACTION, "dolongaction"))
AddStategraphActionHandler("wilson_client", GLOBAL.ActionHandler(AIPC_ACTION, "dolongaction"))

-- 为组件绑定 action
env.AddComponentAction("USEITEM", "aipc_action", function(inst, doer, target, actions, right)
	if not inst or not target then
		return
	end

	if inst.components.aipc_action:CanActOn(target, doer) then
		table.insert(actions, GLOBAL.ACTIONS.AIPC_ACTION)
	end
end)

-------------------- 施法行为 https://www.zybuluo.com/longfei/note/600841
-- 注册一个 action
local AIPC_POINT_ACTION = env.AddAction("AIPC_POINT_ACTION", LANG.CAST, function(act)
	local doer = act.doer
	local item = act.invobject
	local pos = act.pos

	if item.components.aipc_action ~= nil then
		item.components.aipc_action:DoPointAction(doer, pos)
		return true
	end

	return false, "INUSE"
end)

-- 右键
AIPC_POINT_ACTION.rmb = true

AddStategraphActionHandler("wilson", GLOBAL.ActionHandler(AIPC_POINT_ACTION, "throw"))
AddStategraphActionHandler("wilson_client", GLOBAL.ActionHandler(AIPC_POINT_ACTION, "throw"))

-- 为组件绑定 action
env.AddComponentAction("POINT", "aipc_action", function(inst, doer, pos, actions, right)
	if not inst or not target then
		return
	end

	if inst.components.aipc_action:CanActOnPoint(doer, pos) then
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
