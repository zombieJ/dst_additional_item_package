local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		EXIT = "Arrow key to move. Press X to exit",
	},
	chinese = {
		EXIT = "方向键控制，X 键退出",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_MINECAR_EXIT = LANG.EXIT

----------------------------------- 双端通用组件 -----------------------------------
local MineCar = Class(function(self, inst)
	self.inst = inst
	self.orbitPoint = nil -- 记录当前所在的轨道点
	self.doer = nil
end)

function MineCar:BindPoint(point)
	self.orbitPoint = point

	if self.inst.components.inventoryitem ~= nil then
		self.inst.components.inventoryitem:RemoveFromOwner(true)
		self.inst.components.inventoryitem.canbepickedup = false
	end

	self.inst:AddTag("NOCLICK")
	self.inst:AddTag("fx")
	self.inst.persists = false
end

-- 在满足条件时，放弃控制
function MineCar:TryBreak()
	if
		not self.doer or
		not self.doer.sg or
		(self.doer.components.health ~= nil and self.doer.components.health:IsDead()) or
		not self.doer:IsValid() or
		self.doer:IsInLimbo()
	then
		-- TODO: 做更多解锁的事情
		self.doer = nil
		return true
	end

	return false
end

function MineCar:TakeBy(doer)
	if self.doer ~= nil then -- 有人就不能坐了
		return
	end

	self.doer = doer

	if self:TryBreak() then -- 如果是不能控制的状态就算了
		return
	end

	-- 玩家提示
	if doer.components.talker ~= nil then
		doer.components.talker:Say(
			STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_MINECAR_EXIT
		)
	end

	local pt = self.inst:GetPosition()
	self.inst:Hide()

	self.doer.Physics:Teleport(pt.x, pt.y, pt.z)
	self.doer.sg:GoToState("aip_drive")

	-- 玩家绑定矿车
	self.doer:AddTag("aip_orbit_driver")
	self.doer._aip_oribit_minecar = self.inst

	return true
end

return MineCar