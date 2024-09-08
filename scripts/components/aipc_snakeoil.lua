local dev_mode = aipGetModConfig("dev_mode") == "enabled"

-- 服务端
--[[
痛击：额外的 10 点伤害 pain
吸血：攻击每次都恢复生命值 vampire
虚弱：打湿对方 week

流血：攻击造成伤害后，每秒持续造成伤害 blood
复苏：每天恢复 5% 耐久度 repair
游侠：每次攻击都会短暂提升移动速度 free
击退：将敌人打飞 back
压制：每次攻击都会降低对方的速度 slow
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
local SnakeOil = Class(function(self, inst)
	self.inst = inst
	self.owner = nil
	self.lock = 0

	self.ability = "pain"

end)

-- 随机能力
function SnakeOil:RandomAbility()
	self.ability = aipRandomLoot(abilities)

	if dev_mode then
		self.ability = "week"
	end

	-- 告知 Replica
	if self.inst.replica.aipc_snakeoil then
		self.inst.replica.aipc_snakeoil:Sync(self.ability)
	end

	return self.ability
end

------------------------------- BUFF -------------------------------
-- TODO: 实现这个
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

------------------------------- 激活 -------------------------------
function SnakeOil:OnWeaponAttack(attacker, target, projectile)
	local now = GetTime()

	if now - self.lock < 0.1 then
		return
	end

	-- 记录时间，每隔 0.1 秒最多触发一次
	self.lock = now


	aipPrint("Attack >>>", self.ability)

	
	if self.ability == "pain" then -- 痛击
		target.components.combat:GetAttacked(attacker, 10)

	elseif self.ability == "vampire" then -- 吸血
		if attacker.components.health then
			attacker.components.health:DoDelta(5)
		end

	elseif self.ability == "week" then -- 虚弱
		aipBufferPatch(attacker, target, "aip_snakeoil_week", 10)
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