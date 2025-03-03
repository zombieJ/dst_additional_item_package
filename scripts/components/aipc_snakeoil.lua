local dev_mode = aipGetModConfig("dev_mode") == "enabled"

-- 服务端
--[[
痛击：额外的 10 点伤害 pain
吸血：攻击每次都恢复生命值 vampire
虚弱：打湿对方 week

流血：攻击造成伤害后，每秒持续造成伤害 blood
复苏：每天恢复 10% 耐久度 repair
游侠：携带时会提升移动速度
击退：将敌人打飞 back
断筋：每次攻击都会降低对方的速度 slow
]]

local abilities = { -- 概率
	pain = 20,
	vampire = 10,
	week = 10,
	blood = 10,
	repair = 10,
	free = 10,
	back = 10,
	slow = 10,
}

----------------------------------------------------------------
-- 复苏：每天恢复一次
local function OnIsDay(inst, isday)
	if
		isday and
		inst.components.aipc_snakeoil ~= nil and
		inst.components.aipc_snakeoil.ability == "repair"
	then
		if inst.components.finiteuses ~= nil then
			-- 修复 finituses
			local ptg = inst.components.finiteuses:GetPercent()
			inst.components.finiteuses:SetPercent(
				math.min(1, ptg + 0.05)
			)
		elseif inst.components.perishable ~= nil then
			-- 修复 perishable
			local ptg = inst.components.perishable:GetPercent()
			inst.components.perishable:SetPercent(
				math.min(1, ptg + 0.05)
			)
		end
	end
end

local function OnEquipped(inst, data)
	-- 游侠：携带时会提升移动速度
	if
		data and data.owner and
		data.owner.components.locomotor and
		inst.components.aipc_snakeoil ~= nil and
		inst.components.aipc_snakeoil.ability == "free"
	then
		local multi = dev_mode and 3 or 1.25
		data.owner.components.locomotor:SetExternalSpeedMultiplier(inst, "aipc_snakeoil_free", multi)
	end
end

local function OnUnequipped(inst, data)
	-- 清除 游侠，无所谓原本有没有加上
	if data and data.owner and data.owner.components.locomotor then
		data.owner.components.locomotor:RemoveExternalSpeedMultiplier(inst, "aipc_snakeoil_free")
	end
end

----------------------------------------------------------------
local SnakeOil = Class(function(self, inst)
	self.inst = inst
	self.owner = nil
	self.lock = 0

	self.ability = "pain"

	self.inst:WatchWorldState("isday", OnIsDay)
	self.inst:ListenForEvent("equipped", OnEquipped)
	self.inst:ListenForEvent("unequipped", OnUnequipped)

	self.inst:AddTag("aip_snakeoil_target")
end)

-- 随机能力
function SnakeOil:RandomAbility()
	self.ability = aipRandomLoot(abilities)

	if dev_mode then
		self.ability = "slow"
	end

	-- 告知 Replica
	if self.inst.replica.aipc_snakeoil then
		self.inst.replica.aipc_snakeoil:Sync(self.ability)
	end

	return self.ability
end

------------------------------- BUFF -------------------------------
-- 虚弱
aipBufferRegister("aip_snakeoil_week", {
	name = "week", -- 不用写 locale，因为玩家看不到
	showFX = true,

	startFn = function(source, inst, info)
		if inst.components.combat ~= nil then -- 伤害降低 50%
			inst.components.combat:aipMultiDamages("aip_snakeoil_week", -0.5)
		end
	end,

	endFn = function(source, inst)
		if inst.components.combat ~= nil then
			inst.components.combat:aipMultiDamages("aip_snakeoil_week", nil)
		end
	end
})

-- 流血
aipBufferRegister("aip_snakeoil_blood", {
	name = "blood", -- 不用写 locale，因为玩家看不到
	showFX = false,

	fn = function(source, inst, info) -- 每隔 2 秒造成 5 点伤害
		if inst.components.health ~= nil and info.tickTime % 2 == 0 then
			inst.components.health:DoDelta(-5)
		end
	end,
})

-- 断筋
aipBufferRegister("aip_snakeoil_slow", {
	name = "slow", -- 不用写 locale，因为玩家看不到
	showFX = true,

	startFn = function(source, inst, info)
		if inst.components.locomotor ~= nil then -- 速度降低 50%
			inst.components.locomotor:SetExternalSpeedMultiplier(inst, "aip_snakeoil_slow", 0.5)
		end
	end,

	endFn = function(source, inst)
		if inst.components.locomotor ~= nil then
			inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, "aip_snakeoil_slow")
		end
	end
})

------------------------------- 激活 -------------------------------
function SnakeOil:OnWeaponAttack(attacker, target, projectile)
	local now = GetTime()

	if now - self.lock < 0.1 then
		return
	end

	-- 记录时间，每隔 0.1 秒最多触发一次
	self.lock = now

	if self.ability == "pain" then -- 痛击
		target.components.combat:GetAttacked(attacker, 10)

	elseif self.ability == "vampire" then -- 吸血
		if attacker.components.health then
			attacker.components.health:DoDelta(5)
		end

	elseif self.ability == "week" then -- 虚弱
		aipBufferPatch(attacker, target, "aip_snakeoil_week", 10)

	elseif self.ability == "blood" then -- 流血
		aipBufferPatch(attacker, target, "aip_snakeoil_blood", 11)

	elseif self.ability == "back" and target.Physics then -- 击退
		local attackerPT = attacker:GetPosition()
		local angle = aipGetAngle(attackerPT, target:GetPosition())
		local tgtPT = aipAngleDist(attackerPT, angle, 3)

		-- 移动到 tgtPT
		target.Physics:Stop()
		target.Physics:Teleport(tgtPT:Get())

	elseif self.ability == "slow" then -- 断筋
		aipBufferPatch(attacker, target, "aip_snakeoil_slow", 5)
	end
end

------------------------------- 存取 -------------------------------
function SnakeOil:OnSave()
	return {
		ability = self.ability,
	}
end

function SnakeOil:OnLoad(data)
	if data.ability then
		self.ability = data.ability
	end
end

return SnakeOil