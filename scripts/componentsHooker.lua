local _G = GLOBAL
local language = _G.aipGetModConfig("language")

----------------------------------- 通用组件行为 -----------------------------------
local function triggerComponentAction(player, item, target, targetPoint)
	if item.components.aipc_action ~= nil then
		-- trigger action
		if target ~= nil then
			item.components.aipc_action:DoTargetAction(player, target)
		elseif targetPoint ~= nil then
			item.components.aipc_action:DoPointAction(player, targetPoint)
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

	if _G.TheNet:GetIsServer() then
		-- server
		triggerComponentAction(doer, item, target, nil)
	else
		-- client
		SendModRPCToServer(MOD_RPC[env.modname]["aipComponentAction"], doer, item, target, nil)
	end

	return true
end)
AddStategraphActionHandler("wilson", _G.ActionHandler(AIPC_ACTION, "dolongaction"))
AddStategraphActionHandler("wilson_client", _G.ActionHandler(AIPC_ACTION, "dolongaction"))

-- 为组件绑定 action
env.AddComponentAction("USEITEM", "aipc_action_client", function(inst, doer, target, actions, right)
	if not inst or not target then
		return
	end

	if inst.components.aipc_action_client:CanActOn(doer, target) then
		table.insert(actions, _G.ACTIONS.AIPC_ACTION)
	end
end)

-------------------- 施法行为 https://www.zybuluo.com/longfei/note/600841
local function getActionableItem(doer)
	local inventory = doer.replica.inventory
	if inventory ~= nil then
		local item = inventory:GetEquippedItem(_G.EQUIPSLOTS.HANDS)
		if item ~= nil and item.components.aipc_action_client ~= nil then
			return item
		end
	end
	return nil
end

-- 注册一个 action
local AIPC_CASTER_ACTION = env.AddAction("AIPC_CASTER_ACTION", LANG.CAST, function(act)
	local doer = act.doer
	-- local item = act.invobject
	local pos = act.pos
	local target = act.target
	local item = getActionableItem(doer)

	if _G.TheNet:GetIsServer() then
		-- server
		triggerComponentAction(doer, item, target, pos ~= nil and act:GetActionPoint())
	else
		-- client
		SendModRPCToServer(MOD_RPC[env.modname]["aipComponentAction"], doer, item, target, pos)
	end

	return true
end)

AIPC_CASTER_ACTION.distance = 10

AddStategraphActionHandler("wilson", _G.ActionHandler(AIPC_CASTER_ACTION, "quicktele"))
AddStategraphActionHandler("wilson_client", _G.ActionHandler(AIPC_CASTER_ACTION, "quicktele"))

-- aipc_action_client 对 点 操作
env.AddComponentAction("POINT", "aipc_action_client", function(inst, doer, pos, actions, right)
	if not inst or not pos or not right then
		return
	end

	if inst.components.aipc_action_client:CanActOnPoint(doer, pos) then
		table.insert(actions, _G.ACTIONS.AIPC_CASTER_ACTION)
	end
end)

-- 角色拥有 aipc_action_client 对 combat 对象 操作
env.AddComponentAction("SCENE", "combat", function(inst, doer, actions, right)
	if not inst or not right then
		return
	end

	local item = getActionableItem(doer)

	if item ~= nil and item.components.aipc_action_client:CanActOn(doer, inst) then
		table.insert(actions, _G.ACTIONS.AIPC_CASTER_ACTION)
	end
end)


------------------------------------- 特殊处理 -------------------------------------
-- 额外触发一个生命值时间出来
AddComponentPostInit("health", function(self)
	-- 生命变化钩子
	local origiDoDelta = self.DoDelta

	function self:DoDelta(amount, ...)
		-- healthCost buffer 的对象会受到更多伤害
		if _G.hasBuffer(self.inst, "healthCost") and amount < 0 then
			amount = -999999999
		end

		local data = { amount = amount }
		self.inst:PushEvent("aip_healthdelta", data)

		origiDoDelta(self, data.amount, _G.unpack(arg))
	end

	-- 锁定无敌，锁定后无法再更改无敌状态
	function self:LockInvincible(val)
		self.aipLockInvincible = val
	end

	-- 设置无敌
	local originSetInvincible = self.SetInvincible
	function self:SetInvincible(val, ...)
		if self.aipLockInvincible ~= true then
			return originSetInvincible(self, val, _G.unpack(arg))
		end
	end

end)

-- 燃料允许自定义接受测试
AddComponentPostInit("fueled", function(self)
	local originCanAcceptFuelItem = self.CanAcceptFuelItem

	function self:CanAcceptFuelItem(item)
		if self.canAcceptFuelFn ~= nil then
			return self.canAcceptFuelFn(self.inst, item)
		end
		return originCanAcceptFuelItem(self, item)
	end
end)

-- 治疗允许回调
AddComponentPostInit("healer", function(self)
	local originHeal = self.Heal

	function self:Heal(target, ...)
		if self.onHealTarget ~= nil then
			self.onHealTarget(self.inst, target)
		end

		return originHeal(self, target, _G.unpack(arg))
	end
end)
