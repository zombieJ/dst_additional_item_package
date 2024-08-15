local dev_mode = aipGetModConfig("dev_mode") == "enabled"

-- 服务端
--[[
吸血：攻击每次都恢复生命值 vampire
流血：攻击造成伤害后，每秒持续造成伤害 blood
潮湿：打湿对方 wet
复苏：每天恢复 5% 耐久度 repair
游侠：每次攻击都会短暂提升移动速度 free
击退：将敌人打飞 back
压制：每次攻击都会降低对方的速度 slow
痛击：额外的 10 点伤害 pain
]]

local abilities = { -- 概率
	vampire = 10,
	blood = 10,
	wet = 10,
	repair = 10,
	free = 10,
	back = 10,
	slow = 10,
	pain = 20,
}

----------------------------------------------------------------
local SnakeOil = Class(function(self, inst)
	self.inst = inst
	self.owner = nil
	self.lock = false

	self.ability = "pain"

end)

-- 随机能力
function SnakeOil:RandomAbility()
	self.ability = aipRandomLoot(abilities)

	if dev_mode then
		self.ability = "pain"
	end

	-- 告知 Replica
	if self.inst.replica.aipc_snakeoil then
		self.inst.replica.aipc_snakeoil:Sync(self.ability)
	end

	return self.ability
end

------------------------------- 激活 -------------------------------
function SnakeOil:OnWeaponAttack(attacker, target, projectile)
	if self.lock then
		return
	end

	-- 暂时锁定，防止死循环
	self.lock = true

	aipPrint("Attack >>>", self.ability)

	
	if self.ability == "pain" then -- 痛击
		target.components.combat:GetAttacked(attacker, 10)
	end

	self.lock = false
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