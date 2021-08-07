local _G = GLOBAL
local language = _G.aipGetModConfig("language")

----------------------------------- 通用组件行为 -----------------------------------
-- 服务端组件
local function triggerComponentAction(player, item, target, targetPoint)
	if item.components.aipc_action ~= nil then
		-- trigger action
		if target ~= nil then
			item.components.aipc_action:DoTargetAction(player, target)
		elseif targetPoint ~= nil then
			item.components.aipc_action:DoPointAction(player, targetPoint)
		else
			item.components.aipc_action:DoAction(player)
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
		USE = "Use",
		CAST = "Cast",
	},
	chinese = {
		GIVE = "给予",
		USE = "使用",
		CAST = "释放",
	},
}
local LANG = LANG_MAP[language] or LANG_MAP.english

_G.STRINGS.ACTIONS.AIP_USE = LANG.USE

-------------------- 对目标使用的技能 --------------------
local AIPC_ACTION = env.AddAction("AIPC_ACTION", LANG.GIVE, function(act)
	local doer = act.doer
	local item = act.invobject
	local target = act.target

	if _G.TheNet:GetIsServer() then
		-- server
		triggerComponentAction(doer, item, target, nil)
	else
		-- client
		_G.aipRPC("aipComponentAction", item, target, nil)
	end

	return true
end)
AddStategraphActionHandler("wilson", _G.ActionHandler(AIPC_ACTION, "dolongaction"))
AddStategraphActionHandler("wilson_client", _G.ActionHandler(AIPC_ACTION, "dolongaction"))

-- 角色使用 aipc_action_client 对某物使用
env.AddComponentAction("USEITEM", "aipc_action_client", function(inst, doer, target, actions, right)
	if not inst or not target then
		return
	end

	if inst.components.aipc_action_client:CanActOn(doer, target) then
		table.insert(actions, _G.ACTIONS.AIPC_ACTION)
	end
end)

---------------------- 被使用的技能 ----------------------
local AIPC_BE_ACTION = env.AddAction("AIPC_BE_ACTION", LANG.USE, function(act)
	local doer = act.doer
	local target = act.target

	if _G.TheNet:GetIsServer() then
		-- server
		triggerComponentAction(doer, target, nil, nil)
	else
		-- client
		_G.aipRPC("aipComponentAction", target, nil, nil)
	end

	return true
end)
AddStategraphActionHandler("wilson", _G.ActionHandler(AIPC_BE_ACTION, "doshortaction"))
AddStategraphActionHandler("wilson_client", _G.ActionHandler(AIPC_BE_ACTION, "doshortaction"))

-- 角色对某物使用 aipc_action_client
env.AddComponentAction("SCENE", "aipc_action_client", function(inst, doer, actions, right)
	if not inst or not right then
		return
	end

	if inst.components.aipc_action_client:CanBeActOn(doer) then
		table.insert(actions, _G.ACTIONS.AIPC_BE_ACTION)
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

-------------> 标准的施法动作
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
		_G.aipRPC("aipComponentAction", item, target, pos)
	end

	return true
end)
AIPC_CASTER_ACTION.distance = 10

AddStategraphActionHandler("wilson", _G.ActionHandler(AIPC_CASTER_ACTION, "quicktele"))
AddStategraphActionHandler("wilson_client", _G.ActionHandler(AIPC_CASTER_ACTION, "quicktele"))

-------------> 带网格的施法动作：种地相关代码
local AIPC_GRID_CASTER_ACTION = env.AddAction("AIPC_GRID_CASTER_ACTION", LANG.CAST, function(act)
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
AIPC_GRID_CASTER_ACTION.tile_placer = "gridplacer"
AIPC_GRID_CASTER_ACTION.theme_music = "farming"
AIPC_GRID_CASTER_ACTION.customarrivecheck = function(doer, dest) -- 是否可以点到这个地点
	local doer_pos = doer:GetPosition()
	local target_pos = _G.Vector3(dest:GetPoint())

	local tile_x, tile_y, tile_z = _G.TheWorld.Map:GetTileCenterPoint(target_pos.x, 0, target_pos.z)
	local dist = _G.TILE_SCALE * 0.5
	if math.abs(tile_x - doer_pos.x) <= dist and math.abs(tile_z - doer_pos.z) <= dist then
		return true
	end
end

AddStategraphActionHandler("wilson", _G.ActionHandler(AIPC_GRID_CASTER_ACTION, "quicktele"))
AddStategraphActionHandler("wilson_client", _G.ActionHandler(AIPC_GRID_CASTER_ACTION, "quicktele"))

-- aipc_action_client 对 点 操作
env.AddComponentAction("POINT", "aipc_action_client", function(inst, doer, pos, actions, right)
	if not inst or not pos or not right then
		return
	end

	if inst.components.aipc_action_client:CanActOnPoint(doer, pos) then
		if inst.components.aipc_action_client.gridplacer then -- 是否展示网格纹理
			table.insert(actions, _G.ACTIONS.AIPC_GRID_CASTER_ACTION)
		else
			table.insert(actions, _G.ACTIONS.AIPC_CASTER_ACTION)
		end
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
	local originDoDelta = self.DoDelta

	function self:DoDelta(amount, ...)
		-- healthCost buffer 的对象会受到更多伤害
		if _G.hasBuffer(self.inst, "healthCost") and amount < 0 then
			amount = amount * 2
		end

		local data = { amount = amount }
		self.inst:PushEvent("aip_healthdelta", data)

		originDoDelta(self, data.amount, _G.unpack(arg))
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
	-- 是否可以添加燃料
	local originCanAcceptFuelItem = self.CanAcceptFuelItem

	function self:CanAcceptFuelItem(item)
		if self.canAcceptFuelFn ~= nil then
			return self.canAcceptFuelFn(self.inst, item)
		end
		return originCanAcceptFuelItem(self, item)
	end
end)

-- writeable 完成时额外触发一个事件
AddComponentPostInit("writeable", function(self)
	local originEndWriting = self.EndWriting

	function self:EndWriting(...)
		if self.onAipEndWriting ~= nil then
			self.onAipEndWriting()
		end

		originEndWriting(self, _G.unpack(arg))
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
