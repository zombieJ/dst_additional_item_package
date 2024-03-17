local _G = GLOBAL
local language = _G.aipGetModConfig("language")

local dev_mode = _G.aipGetModConfig("dev_mode") == "enabled"

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

-- 远动作
local AIPC_REMOTE_ACTION = env.AddAction("AIPC_REMOTE_ACTION", LANG.USE, actionFn)
AIPC_REMOTE_ACTION.priority = 1
AIPC_REMOTE_ACTION.distance = 10

AddStategraphActionHandler("wilson", _G.ActionHandler(AIPC_REMOTE_ACTION, "throw"))
AddStategraphActionHandler("wilson_client", _G.ActionHandler(AIPC_REMOTE_ACTION, "throw"))

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

	local canActOn, remoteAction = inst.components.aipc_action_client:CanActOn(doer, target)
	if canActOn then
		if remoteAction == true then
			table.insert(actions, _G.ACTIONS.AIPC_REMOTE_ACTION)
		else
			table.insert(actions, _G.ACTIONS.AIPC_ACTION)
		end
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
local function AipPostComp(componentName, callback)
	AddComponentPostInit(componentName, callback)

	if dev_mode then
		_G.aipPrint("添加组件钩子：" .. componentName)
	end
end

-- 额外触发一个生命值时间出来
AipPostComp("health", function(self)
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
AipPostComp("writeable", function(self)
	local originEndWriting = self.EndWriting

	function self:EndWriting(...)
		if self.onAipEndWriting ~= nil then
			self.onAipEndWriting()
		end

		originEndWriting(self, ...)
	end
end)

-- 浇水允许回调
AipPostComp("witherable", function(self)
	local originProtect = self.Protect

	function self:Protect(...)
		if self.onAipProtected ~= nil then
			self.onAipProtected(self.inst)
		end

		return originProtect(self, ...)
	end
end)


-- 钓鱼不会断绳
AipPostComp("oceanfishingrod", function(self)
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
AipPostComp("tool", function(self)
	local originGetEffectiveness = self.GetEffectiveness

	function self:GetEffectiveness(action, ...)
		local num = originGetEffectiveness(self, action, ...)

		-- 找一下玩家
		if self.inst.components.inventoryitem ~= nil then
			local owner = self.inst.components.inventoryitem.owner

			if
				(
					action == _G.ACTIONS.CHOP and
					_G.aipBufferExist(
						owner,
						"aip_oldone_smiling_axe"
					)
				) or (
					action == _G.ACTIONS.MINE and
					_G.aipBufferExist(
						owner,
						"aip_oldone_smiling_mine"
					)
				)
			then
				num = num * 3
			end

			-- 宠物主人孤狼 buff
			if
				(action == _G.ACTIONS.CHOP or action == _G.ACTIONS.MINE) and
				owner ~= nil and owner.components.aipc_pet_owner ~= nil
			then
				local players = _G.aipFindNearPlayers(owner, 20)

				-- 只有一个玩家，这一下就特别有效
				if #players <= 1 then
					local skillInfo, skillLv = owner.components.aipc_pet_owner:GetSkillInfo("alone")

					if skillInfo ~= nil then
						local multi = 1 + skillInfo.multi * skillLv
						num = num * multi
					end
				end
			end
		end

		return num
	end
end)

-- 伤害允许翻倍
AipPostComp("combat", function(self)
	-- 受到攻击
	local originGetAttacked = self.GetAttacked

	function self:GetAttacked(attacker, damage, weapon, stimuli, spdamage, ...)
		-- 额外添加一个代理事件
		local data = { damage = damage, spdamage = spdamage or {} }
		self.inst:PushEvent("aipAttacked", data)

		spdamage = data.spdamage
		local dmg = data.damage

		-- Owner 被攻击（被攻击时，是乘法叠加伤害减免）
		if self.inst ~= nil and self.inst.components.aipc_pet_owner ~= nil then
			-- 幸运则免疫 查理 攻击
			local luckyInfo, luckyLv = self.inst.components.aipc_pet_owner:GetSkillInfo("lucky")
			if luckyInfo ~= nil and stimuli == "darkness" then
				dmg = 0
			end

			-- 淋雨声 用潮湿度减少伤害
			if dmg > 0 and self.inst.components.moisture ~= nil then
				local skillInfo, skillLv = self.inst.components.aipc_pet_owner:GetSkillInfo("rainbow")
				local moisture = self.inst.components.moisture:GetMoisture()

				if skillInfo ~= nil and moisture > 0 then
					local minVal = math.min(dmg, moisture)
					dmg = dmg - minVal
					self.inst.components.moisture:DoDelta(-minVal)

					_G.aipSpawnPrefab(self.inst, "waterstreak_burst")
				end
			end

			-- 执念W
			local resonanceInfo, resonanceLv = self.inst.components.aipc_pet_owner:GetSkillInfo("resonance")
			if resonanceInfo ~= nil and self.inst.components.sanity ~= nil and self.inst.components.sanity:IsCrazy() then
				dmg = dmg * (1 - resonanceInfo.def * resonanceLv)
			end
		end

		-- 被 Owner 攻击
		if attacker ~= nil and attacker.components.aipc_pet_owner ~= nil then
			local petDmgMulti = 0

			-- 亵渎 伤害加倍
			local blasphemyInfo = attacker.components.aipc_pet_owner:GetSkillInfo("blasphemy")

			if blasphemyInfo ~= nil then
				petDmgMulti = petDmgMulti + (dev_mode and 999 or 1)
			end

			-- 虾拳
			local shrimpInfo, shrimpLv = attacker.components.aipc_pet_owner:GetSkillInfo("shrimp")

			if shrimpInfo ~= nil then
				local inv = attacker.components.inventory
				if inv == nil or inv:GetEquippedItem(_G.EQUIPSLOTS.HANDS) == nil then
					petDmgMulti = petDmgMulti + shrimpInfo.multi * shrimpLv
				end
			end

			-- 执念W
			local resonanceInfo, resonanceLv = attacker.components.aipc_pet_owner:GetSkillInfo("resonance")
			if resonanceInfo ~= nil and attacker.components.sanity ~= nil and attacker.components.sanity:IsCrazy() then
				petDmgMulti = petDmgMulti + resonanceInfo.atk * resonanceLv
			end

			dmg = dmg * (1 + petDmgMulti)
		end

		return originGetAttacked(self, attacker, dmg, weapon, stimuli, spdamage, ...)
	end

	-- 计算伤害
	local originCalcDamage = self.CalcDamage

	function self:CalcDamage(target, weapon, multiplier, ...)
		local oriDmg, oriSpDmg = originCalcDamage(self, target, weapon, multiplier, ...)
		local dmg = oriDmg
		local spDmg = oriSpDmg

		-- 古神 攻击 buff
		if
			_G.aipBufferExist(
				self.inst,
				"aip_oldone_smiling_attack"
			)
		then
			dmg = dmg * 2
		end

		-- 攻击者有 嬉闹 BUFF，将会减少伤害
		local playBuffInfo = _G.aipBufferInfo(
			self.inst,
			"aip_pet_play"
		)
		if playBuffInfo ~= nil and playBuffInfo.data ~= nil then
			local desc = playBuffInfo.data.desc or 0
			dmg = dmg * (1 - desc)
		end

		-- 杀神 增加伤害
		local johnWickInfo = _G.aipBufferInfo(
			self.inst,
			"aip_pet_johnWick"
		)
		if dmg ~= 0 and johnWickInfo ~= nil and johnWickInfo.data ~= nil then
			local atk = johnWickInfo.data.dmg or 0
			dmg = dmg + atk
		end

		-- 宠物主人攻击 buff
		if self.inst.components.aipc_pet_owner ~= nil then
			local petDmgMulti = 0

			-- 好斗
			local skillInfo, skillLv = self.inst.components.aipc_pet_owner:GetSkillInfo("aggressive")

			if skillInfo ~= nil then
				local multi = skillInfo.multi * skillLv
				petDmgMulti = petDmgMulti + multi
			end

			-- 逐月
			local lunaInfo, lunaLv = self.inst.components.aipc_pet_owner:GetSkillInfo("luna")
			if lunaInfo ~= nil then
				-- 月岛地皮
				local tile = _G.TheWorld.Map:GetTileAtPoint(
					self.inst.Transform:GetWorldPosition()
				)

				if tile == _G.GROUND.METEOR then
					petDmgMulti = petDmgMulti + lunaInfo.land * lunaLv
				end

				-- 满月
				if _G.TheWorld.state.isfullmoon then
					petDmgMulti = petDmgMulti + lunaInfo.full * lunaLv
				end
			end

			-- 米糕 闪避增加伤害
			local migaoInfo, migaoLv, migaoSkill = self.inst.components.aipc_pet_owner:GetSkillInfo("migao")

			if migaoInfo ~= nil then
				local multi = 1 + (migaoSkill._multi or 0) * migaoInfo.multi
				dmg = dmg * multi
			end

			-- 好斗
			local skillInfo, skillLv = self.inst.components.aipc_pet_owner:GetSkillInfo("aggressive")

			if skillInfo ~= nil then
				local multi = skillInfo.multi * skillLv
				petDmgMulti = petDmgMulti + multi
			end

			-- 青尘 增加 100% 伤害
			local balrogInfo, balrogLv = self.inst.components.aipc_pet_owner:GetSkillInfo("balrog")
			if
				balrogInfo ~= nil and
				self.inst.components.health ~= nil and
				self.inst.components.health.takingfiredamage == true
			then
				dmg = dmg + balrogInfo.atk * balrogLv
			end

			dmg = dmg * (1 + petDmgMulti)
		end

		-- 目标如果是宠物主人
		if target ~= nil and target.components.aipc_pet_owner ~= nil then
			-- 伤害减少
			local skillInfo, skillLv = target.components.aipc_pet_owner:GetSkillInfo("conservative")

			if skillInfo ~= nil then
				local multi = 1 - skillInfo.multi * skillLv
				dmg = dmg * multi
			end

			-- 蝶舞有概率免疫
			local dancerInfo, dancerLv = target.components.aipc_pet_owner:GetSkillInfo("dancer")

			if dancerInfo ~= nil then
				if _G.aipChance(dancerInfo.multi * dancerLv, target) then
					dmg = 0

					-- 播放音效
					if target.SoundEmitter ~= nil then
						target.SoundEmitter:PlaySound("dontstarve/common/staff_blink")
					end

					-- 播放特效
					local fx = _G.SpawnPrefab("shadow_shield2")
					fx.entity:SetParent(target.entity)
				end
			end

			-- 米糕 会增加伤害
			local migaoInfo, migaoLv, migaoSkill = target.components.aipc_pet_owner:GetSkillInfo("migao")

			if migaoInfo ~= nil then
				local multi = 1 + migaoInfo.pain
				dmg = dmg * multi

				-- 重置伤害倍数计数
				migaoSkill._multi = 0
			end

			-- 陵卫斗篷
			local graveInfo, graveLv = target.components.aipc_pet_owner:GetSkillInfo("graveCloak")
			if graveInfo ~= nil and target.components.aipc_grave_cloak ~= nil and dmg > 0 then
				local cnt = target.components.aipc_grave_cloak:GetCurrent()
				local multi = 1 - cnt * (graveInfo.def + graveInfo.defMulti * graveLv)
				dmg = dmg * math.max(0, multi)

				-- 破坏一层
				target.components.aipc_grave_cloak:Break()
			end
		end

		-- 如果 dmg 被变为 0，则也避免特殊伤害。如果没有变化则保留
		if dmg == 0 and dmg ~= oriDmg then
			spDmg = nil
		end

		return dmg, spDmg
	end

	-- 为攻击额外添加事件
	local originDoAttack = self.DoAttack

	function self:DoAttack(targ, weapon, projectile, stimuli, instancemult, instrangeoverride, instpos, ...)
		-- 给 miss 的目标也添加一个事件
		if targ ~= nil and (not self:CanHitTarget(targ, weapon) or self.AOEarc) then
			targ:PushEvent("aipMissAttack", { source = self.inst, weapon = weapon })
		end

		return originDoAttack(self, targ, weapon, projectile, stimuli, instancemult, instrangeoverride, instpos, ...)
	end
end)


-- 让玩家使用 AIPC_GIVE_ACTION 时，不会手持物品
AipPostComp("playercontroller", function(self)
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

-- 阻止掉落物品
AipPostComp("drownable", function(self)
	local originOnFallInOcean = self.OnFallInOcean
	local originDropInventory = self.DropInventory
	local originTakeDrowningDamage = self.TakeDrowningDamage

	-- 落水
	function self:OnFallInOcean(...)
		local inv = self.inst.components.inventory

		if inv ~= nil then
			-- 如果有宠物能力，则不掉落
			if self.inst.components.aipc_pet_owner ~= nil then
				local skillInfo = self.inst.components.aipc_pet_owner:GetSkillInfo("winterSwim")

				if skillInfo ~= nil then
					-- 存储原始数据
					local active_item = inv:GetActiveItem()
					local handitem = inv:GetEquippedItem(_G.EQUIPSLOTS.HANDS)

					local active_keepondrown = nil
					local handitem_keepondrown = nil

					-- 强制不能掉落
					if active_item ~= nil then
						active_keepondrown = active_item.components.inventoryitem.keepondrown
						active_item.components.inventoryitem.keepondrown = true
					end

					if handitem ~= nil then
						handitem_keepondrown = handitem.components.inventoryitem.keepondrown
						handitem.components.inventoryitem.keepondrown = true
					end

					-- 调用原生方法
					local ret = originOnFallInOcean(self, ...)

					-- 恢复物品数据
					if active_item ~= nil then
						active_item.components.inventoryitem.keepondrown = active_keepondrown
					end

					if handitem ~= nil then
						handitem.components.inventoryitem.keepondrown = handitem_keepondrown
					end

					return ret
				end
			end
		end

		return originOnFallInOcean(self, ...)
	end

	-- 掉落物品
	function self:DropInventory(...)
		-- 如果有宠物能力，则不掉落
		if self.inst.components.aipc_pet_owner ~= nil then
			local skillInfo = self.inst.components.aipc_pet_owner:GetSkillInfo("winterSwim")

			if skillInfo ~= nil then
				return false
			end
		end

		-- 返回原生的方法
		originDropInventory(self, ...)
	end

	-- 受到伤害
	function self:TakeDrowningDamage(...)
		-- 如果有宠物能力，则不掉血
		if self.inst.components.aipc_pet_owner ~= nil then
			local skillInfo = self.inst.components.aipc_pet_owner:GetSkillInfo("winterSwim")

			if skillInfo ~= nil then
				-- 转为冻结玩家
				if self.inst.components.freezable ~= nil then
					self.inst.components.freezable:Freeze()
				end
				return false
			end
		end

		-- 返回原生的方法
		return originTakeDrowningDamage(self, ...)
	end
end)

-- 治疗支持动态
AipPostComp("healer", function(self)
	local originHeal = self.Heal

	-- 治疗可以改变
	function self:Heal(target, ...)
		local originHealth = self.health

		-- 允许额外的变化
		if self.aipGetHealth ~= nil then
			self.health = self.aipGetHealth(self.inst, target, originHealth) or originHealth
		end

		-- 如果有宠物技能，则增加效果
		if target ~= nil and target.components.aipc_pet_owner ~= nil then
			local skillInfo, skillLv = target.components.aipc_pet_owner:GetSkillInfo("acupuncture")

			if skillInfo ~= nil then
				local multi = 1 + skillInfo.multi * skillLv
				self.health = self.health * multi
			end
		end

		local ret = originHeal(self, target, ...)

		self.health = originHealth
		return ret
	end
end)

-- 食物
AipPostComp("edible", function(self)
	local originGetHealth = self.GetHealth

	-- 食物健康影响
	function self:GetHealth(eater, ...)
		local health = originGetHealth(self, eater, ...)

		-- 如果有宠物技能，则免疫伤害
		if eater ~= nil and eater.components.aipc_pet_owner ~= nil then
			local skillInfo, skillLv = eater.components.aipc_pet_owner:GetSkillInfo("taster")

			if skillInfo ~= nil and health < 0 then
				health = 0
			end
		end

		return health
	end
end)

-- 食客
AipPostComp("eater", function(self)
	local originTestFood = self.TestFood

	-- 玩家点不中的，其他生物也不能吃
	function self:TestFood(food, testvalues, ...)
		if food ~= nil and food:HasTag("NOCLICK") then
			return false
		end

		return originTestFood(self, food, testvalues, ...)
	end
end)

-- 烹饪
AipPostComp("stewer", function(self)
	local originStartCooking = self.StartCooking

	-- 食物健康影响
	function self:StartCooking(doer, ...)
		-- 额外触发一个事件
		if doer ~= nil then
			doer:PushEvent("aipStartCooking",
				{cookpot = self.inst}
			)
		end

		return originStartCooking(self, doer, ...)
	end
end)

-- 植物
AipPostComp("farmplantstress", function(self)
	local originSetStressed = self.SetStressed

	-- 植物压力
	function self:SetStressed(name, stressed, doer, ...)
		-- 额外触发一个事件
		if doer ~= nil then
			doer:PushEvent("aipStressPlant",
				{plant = self.inst}
			)
		end

		return originSetStressed(self, name, stressed, doer, ...)
	end
end)

-- 装备
AipPostComp("equippable", function(self)
	-- 暂时不需要
	-- -- 装备
	-- local originEquip = self.Equip
	-- function self:Equip(owner, from_ground, ...)
	-- 	-- 额外触发一个事件
	-- 	if owner ~= nil then
	-- 		owner:PushEvent("aipEquipItem",
	-- 			{item = self.inst}
	-- 		)
	-- 	end

	-- 	return originEquip(self, owner, from_ground, ...)
	-- end

	-- 卸下
	local originUnequip = self.Unequip
	function self:Unequip(owner, ...)
		-- 额外触发一个事件
		if owner ~= nil then
			owner:PushEvent("aipUnequipItem",
				{item = self.inst}
			)
		end

		return originUnequip(self, owner, ...)
	end
end)

-- 潮湿
AipPostComp("moisture", function(self)
	local oriDoDelta = self.DoDelta

	-- 潮湿变化
	function self:DoDelta(num, no_announce, ...)
		-- 如果有宠物技能，则增加效果
		if num > 0 and self.inst.components.aipc_pet_owner ~= nil then
			local skillInfo, skillLv = self.inst.components.aipc_pet_owner:GetSkillInfo("rainbow")

			if skillInfo ~= nil then
				num = num * (1 + skillInfo.wet * skillLv)
			end
		end
	
		return oriDoDelta(self, num, no_announce, ...)
	end
end)