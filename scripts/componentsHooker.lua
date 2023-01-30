local _G = GLOBAL
local language = _G.aipGetModConfig("language")

env.AddReplicableComponent("aipc_buffer")

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

	if item ~= nil and target ~= nil and target.components.aipc_action ~= nil then
		target.components.aipc_action:DoGiveAction(player, item)
	end
end

env.AddModRPCHandler(env.modname, "aipComponentAction", function(player, item, target, targetPoint)
	triggerComponentAction(player, item, target, targetPoint)
end)

-------------------- 组合行为
local LANG_MAP = {
	english = {
		GIVE = "Give",
		FUEL = "Fuel",
		USE = "Use",
		CAST = "Cast",
		READ = "Read",
		EAT = "Eat",
		TAKE = "Take",
	},
	chinese = {
		GIVE = "给予",
		FUEL = "充能",
		USE = "使用",
		CAST = "释放",
		READ = "阅读",
		EAT = "吃",
		TAKE = "拿取",
	},
}
local LANG = LANG_MAP[language] or LANG_MAP.english

_G.STRINGS.ACTIONS.AIP_USE = LANG.USE

-------------------- 对目标使用的技能 --------------------
local function actionFn(act)
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
end

-- 长动作
local AIPC_ACTION = env.AddAction("AIPC_ACTION", LANG.GIVE, actionFn)
AIPC_ACTION.priority = 1

AddStategraphActionHandler("wilson", _G.ActionHandler(AIPC_ACTION, "dolongaction"))
AddStategraphActionHandler("wilson_client", _G.ActionHandler(AIPC_ACTION, "dolongaction"))


-- 短动作
local AIPC_GIVE_ACTION = env.AddAction("AIPC_GIVE_ACTION", LANG.GIVE, actionFn)
AIPC_GIVE_ACTION.priority = 1

AddStategraphActionHandler("wilson", _G.ActionHandler(AIPC_GIVE_ACTION, "doshortaction"))
AddStategraphActionHandler("wilson_client", _G.ActionHandler(AIPC_GIVE_ACTION, "doshortaction"))


-- 角色使用 aipc_action_client 对某物使用
env.AddComponentAction("USEITEM", "aipc_action_client", function(inst, doer, target, actions, right)
	if not inst or not target then
		return
	end

	if inst.components.aipc_action_client:CanActOn(doer, target) then
		table.insert(actions, _G.ACTIONS.AIPC_ACTION)
	end
end)


-- 玩家拿着 inventoryitem 对目标 prefab 使用
env.AddComponentAction("USEITEM", "inventoryitem", function(inst, doer, target, actions, right)
	if not inst or not target then
		return
	end

	if
		target.components.aipc_action_client ~= nil and
		target.components.aipc_action_client:CanBeGiveOn(doer, inst)
	then
		table.insert(actions, _G.ACTIONS.AIPC_GIVE_ACTION)
	end
end)

-------------------- 对目标充能的技能 --------------------
local AIPC_FUEL_ACTION = env.AddAction("AIPC_FUEL_ACTION", LANG.FUEL, function(act)
	local doer = act.doer
	local item = act.invobject
	local target = act.target

	if doer ~= nil and item ~= nil and target ~= nil and target.components.aipc_fueled ~= nil then
		return target.components.aipc_fueled:TakeFuel(item, player)
	end

	return false
end)

AddStategraphActionHandler("wilson", _G.ActionHandler(AIPC_FUEL_ACTION, "dolongaction"))
AddStategraphActionHandler("wilson_client", _G.ActionHandler(AIPC_FUEL_ACTION, "dolongaction"))

-- 角色使用 aipc_fuel 对带有 aipc_fueled 某物使用
env.AddComponentAction("USEITEM", "aipc_fuel", function(inst, doer, target, actions, right)
	if not inst or not target then
		return
	end

	if target.components.aipc_fueled ~= nil and target.components.aipc_fueled:CanUse(inst, doer) then
		table.insert(actions, _G.ACTIONS.AIPC_FUEL_ACTION)
	end
end)

---------------------- 被使用的技能 ----------------------
local function beAction(act)
	local doer = act.doer
	local item = act.invobject	-- INVENTORY
	local target = act.target	-- SCENE

	local mergedTarget = target or item

	if _G.TheNet:GetIsServer() then
		-- server
		triggerComponentAction(doer, mergedTarget, nil, nil)
	else
		-- client
		_G.aipRPC("aipComponentAction", mergedTarget, nil, nil)
	end

	return true
end

-- 额外的拿取距离
local function ExtraPickupRange(doer, dest)
	if dest ~= nil then
		local target_x, target_y, target_z = dest:GetPoint()

		local is_on_water = _G.TheWorld.Map:IsOceanTileAtPoint(target_x, 0, target_z) and
						not _G.TheWorld.Map:IsPassableAtPoint(target_x, 0, target_z)
		if is_on_water then
			return 0.75
		end
	end
    return 0
end

local AIPC_BE_ACTION = env.AddAction("AIPC_BE_ACTION", LANG.USE, beAction)
local AIPC_BE_TAKE_ACTION = env.AddAction("AIPC_BE_TAKE_ACTION", LANG.TAKE, beAction)
local AIPC_BE_CAST_ACTION = env.AddAction("AIPC_BE_CAST_ACTION", LANG.CAST, beAction)

AIPC_BE_TAKE_ACTION.extra_arrive_dist = ExtraPickupRange

AddStategraphActionHandler("wilson", _G.ActionHandler(AIPC_BE_ACTION, "doshortaction"))
AddStategraphActionHandler("wilson_client", _G.ActionHandler(AIPC_BE_ACTION, "doshortaction"))
AddStategraphActionHandler("wilson", _G.ActionHandler(AIPC_BE_TAKE_ACTION, "doshortaction"))
AddStategraphActionHandler("wilson_client", _G.ActionHandler(AIPC_BE_TAKE_ACTION, "doshortaction"))
AddStategraphActionHandler("wilson", _G.ActionHandler(AIPC_BE_CAST_ACTION, "quicktele"))
AddStategraphActionHandler("wilson_client", _G.ActionHandler(AIPC_BE_CAST_ACTION, "quicktele"))

-- 角色对场景上的某物使用 aipc_action_client
env.AddComponentAction("SCENE", "aipc_action_client", function(inst, doer, actions, right)
	if not inst or not right then
		return
	end

	if inst.components.aipc_action_client:CanBeActOn(doer) then
		table.insert(actions, _G.ACTIONS.AIPC_BE_ACTION)
	end
	
	if inst.components.aipc_action_client:CanBeTakeOn(doer) then
		table.insert(actions, _G.ACTIONS.AIPC_BE_TAKE_ACTION)
	end
end)

---------------------- 吃食物的技能 ----------------------
local AIPC_EAT_ACTION = env.AddAction("AIPC_EAT_ACTION", LANG.EAT, function(act)
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

AddStategraphActionHandler("wilson", _G.ActionHandler(AIPC_EAT_ACTION, "eat"))
AddStategraphActionHandler("wilson_client", _G.ActionHandler(AIPC_EAT_ACTION, "eat"))

---------------------- 类读书的技能 ----------------------
local AIPC_READ_ACTION = env.AddAction("AIPC_READ_ACTION", LANG.READ, function(act)
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

AddStategraphActionHandler("wilson", _G.ActionHandler(AIPC_READ_ACTION, "book"))
AddStategraphActionHandler("wilson_client", _G.ActionHandler(AIPC_READ_ACTION, "book"))

-- 判断使用 和 阅读 和 吃，因为重复注册会被覆盖
env.AddComponentAction("INVENTORY", "aipc_action_client", function(inst, doer, actions, right)
	if inst.components.aipc_action_client:CanBeActOn(doer) then
		table.insert(actions, _G.ACTIONS.AIPC_BE_ACTION)
	end

	if inst.components.aipc_action_client:CanBeCastOn(doer) then
		table.insert(actions, _G.ACTIONS.AIPC_BE_CAST_ACTION)
	end

	if inst.components.aipc_action_client:CanBeRead(doer) then
		table.insert(actions, _G.ACTIONS.AIPC_READ_ACTION)
	end

	if inst.components.aipc_action_client:CanBeEat(doer) then
		table.insert(actions, _G.ACTIONS.AIPC_EAT_ACTION)
	end
end)

-------------------- 施法行为 https://www.zybuluo.com/longfei/note/600841
-------------> 标准的施法动作
local function doCastAction(act)
	local doer = act.doer
	-- local item = act.invobject
	local pos = act.pos
	local target = act.target
	local item = _G.aipGetActionableItem(doer) or act.invobject -- 非装备的物品就会拿在鼠标上

	if _G.TheNet:GetIsServer() then
		-- server
		triggerComponentAction(doer, item, target, pos ~= nil and act:GetActionPoint())
	else
		-- client
		_G.aipRPC("aipComponentAction", item, target, pos)
	end

	return true
end

-- Cast
local AIPC_CASTER_ACTION = env.AddAction("AIPC_CASTER_ACTION", LANG.CAST, doCastAction)
AIPC_CASTER_ACTION.distance = 10

AddStategraphActionHandler("wilson", _G.ActionHandler(AIPC_CASTER_ACTION, "quicktele"))
AddStategraphActionHandler("wilson_client", _G.ActionHandler(AIPC_CASTER_ACTION, "quicktele"))

-------------> 带网格的施法动作：种地相关代码
local AIPC_GRID_CASTER_ACTION = env.AddAction("AIPC_GRID_CASTER_ACTION", LANG.CAST, function(act)
	local doer = act.doer
	-- local item = act.invobject
	local pos = act.pos
	local target = act.target
	local item = _G.aipGetActionableItem(doer)

	if _G.TheNet:GetIsServer() then
		-- server
		triggerComponentAction(doer, item, target, pos ~= nil and act:GetActionPoint())
	else
		-- client
		SendModRPCToServer(MOD_RPC[env.modname]["aipComponentAction"], doer, item, target, pos)
	end

	return true
end)
AIPC_GRID_CASTER_ACTION.tile_placer = "aip_xinyue_gridplacer"
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

	local item = _G.aipGetActionableItem(doer)

	if item ~= nil and item.components.aipc_action_client:CanActOn(doer, inst) then
		table.insert(actions, _G.ACTIONS.AIPC_CASTER_ACTION)
	end
end)

------------------------------------- 特殊处理 -------------------------------------
local ORIGIN_MINE_FN = _G.ACTIONS.MINE.fn
local ORIGIN_MINE_VALID_FN = _G.ACTIONS.MINE.validfn

-- 重写 MINE 的 fn 和 validfn
_G.ACTIONS.MINE.validfn = function(act)
	return ORIGIN_MINE_VALID_FN(act) or act.target:HasTag("aip_showcase")
end

_G.ACTIONS.MINE.fn = function(act)
	return (
		act.target._aipMineFn ~= nil and
		act.target._aipMineFn(act.target)
	) or ORIGIN_MINE_FN(act)
end

------------------------------------- 特殊处理 -------------------------------------
-- 额外触发一个生命值时间出来
AddComponentPostInit("health", function(self)
	-- 生命变化钩子
	local originDoDelta = self.DoDelta

	function self:DoDelta(amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb, ...)
		-- healthCost buffer 的对象会受到更多伤害
		if _G.aipBufferExist(self.inst, "healthCost") and amount < 0 then
			amount = amount * 2
		end

		local data = { amount = amount, afflicter = afflicter }
		self.inst:PushEvent("aip_healthdelta", data)

		return originDoDelta(
			self, data.amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb, ...
		)
	end

	-- 锁定无敌，锁定后无法再更改无敌状态
	function self:LockInvincible(val)
		self.aipLockInvincible = val
	end

	-- 设置无敌
	local originSetInvincible = self.SetInvincible
	function self:SetInvincible(val, ...)
		if self.aipLockInvincible ~= true then
			return originSetInvincible(self, val, ...)
		end
	end

end)

-- writeable 完成时额外触发一个事件
AddComponentPostInit("writeable", function(self)
	local originEndWriting = self.EndWriting

	function self:EndWriting(...)
		if self.onAipEndWriting ~= nil then
			self.onAipEndWriting()
		end

		originEndWriting(self, ...)
	end
end)

-- 浇水允许回调
AddComponentPostInit("witherable", function(self)
	local originProtect = self.Protect

	function self:Protect(...)
		if self.onAipProtected ~= nil then
			self.onAipProtected(self.inst)
		end

		return originProtect(self, ...)
	end
end)


-- 钓鱼不会断绳
AddComponentPostInit("oceanfishingrod", function(self)
	local originReel = self.Reel

	function self:Reel(...)
		local originTension = TUNING.OCEAN_FISHING.REELING_SNAP_TENSION
		if self.fisher:HasTag("aip_oldone_good_fisher") then
			-- 临时增加线的最大承受力，让它永远不会断
			TUNING.OCEAN_FISHING.REELING_SNAP_TENSION = 999999
		end

		local ret = originReel(self, ...)

		TUNING.OCEAN_FISHING.REELING_SNAP_TENSION = originTension
		return ret
	end
end)

-- 干活允许翻倍
AddComponentPostInit("tool", function(self)
	local originGetEffectiveness = self.GetEffectiveness

	function self:GetEffectiveness(action, ...)
		local num = originGetEffectiveness(self, action, ...)

		if
			self.inst.components.inventoryitem ~= nil and
			(
				action == _G.ACTIONS.CHOP and
				_G.aipBufferExist(
					self.inst.components.inventoryitem.owner,
					"aip_oldone_smiling_axe"
				)
			) or (
				action == _G.ACTIONS.MINE and
				_G.aipBufferExist(
					self.inst.components.inventoryitem.owner,
					"aip_oldone_smiling_mine"
				)
			)
		then
			num = num * 3
		end

		return num
	end
end)

-- 伤害允许翻倍
AddComponentPostInit("combat", function(self)
	local originCalcDamage = self.CalcDamage

	function self:CalcDamage(target, weapon, multiplier, ...)
		local dmg = originCalcDamage(self, target, weapon, multiplier, ...)

		-- 古神 攻击 buff
		if
			_G.aipBufferExist(
				self.inst,
				"aip_oldone_smiling_attack"
			)
		then
			dmg = dmg * 2
		end

		-- 宠物主人攻击 buff
		if self.inst.components.aipc_pet_owner ~= nil then
			local skillInfo, skillLv = self.inst.components.aipc_pet_owner:GetSkillInfo("aggressive")

			if skillInfo ~= nil then
				local multi = 1 + skillInfo.multi * skillLv
				dmg = dmg * multi
			end
		end

		-- 目标如果是宠物主人，那伤害要减少
		if target ~= nil and target.components.aipc_pet_owner ~= nil then
			local skillInfo, skillLv = target.components.aipc_pet_owner:GetSkillInfo("conservative")

			if skillInfo ~= nil then
				local multi = 1 - skillInfo.multi * skillLv
				dmg = dmg * multi
			end
		end

		return dmg
	end
end)


-- 让玩家使用 AIPC_GIVE_ACTION 时，不会手持物品
AddComponentPostInit("playercontroller", function(self)
	local originDoActionAutoEquip = self.DoActionAutoEquip

	function self:DoActionAutoEquip(buffaction, ...)
		-- 跳过
		if
			buffaction.action == AIPC_GIVE_ACTION or
			buffaction.action == _G.ACTIONS.SHAVE
		then
			return
		end

		return originDoActionAutoEquip(self, buffaction, ...)
	end
end)
