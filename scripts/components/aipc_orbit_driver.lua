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
local Driver = Class(function(self, player)
	self.inst = player
	self.minecar = nil
	self.orbitPoint = nil
end)

-- 是否可以开车状态
function Driver:IsInvalidDriver()
	if
		(self.inst.components.health ~= nil and self.inst.components.health:IsDead())
		or not self.inst:IsValid()
		or self.inst:IsInLimbo()
	then
		return true
	end

	return false
end

function Driver:CanDrive()
	return self:IsInvalidDriver() == false and self.minecar ~= nil
end

function Driver:UseMineCar(minecar, orbitPoint)
	if self:IsInvalidDriver() or minecar == nil then
		return false
	end

	self.minecar = minecar
	self.orbitPoint = orbitPoint

	-- 玩家提示
	if self.inst.components.talker ~= nil then
		self.inst.components.talker:Say(
			STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_MINECAR_EXIT
		)
	end

	-- 司机上车了
	local pt = orbitPoint:GetPosition()
	self.minecar:Hide()

	self.inst.Physics:Teleport(pt.x, pt.y, pt.z)
	self.inst.sg:GoToState("aip_drive")

	return true
end

function Driver:DriveTo(x, z, exit)
	if not self:CanDrive() then
		return
	end

	local angle = aipGetAngle(Vector3(0, 0, 0), Vector3(x, 0, z))
	aipPrint("Driver Angle:", angle)

	-- 找到附近所有的连接器
	local linkList = aipFindNearEnts(self.orbitPoint, { "aip_glass_orbit_link" }, 15)

	-- 找到连接器的另一个端点
	local orbitPointList = {}
	for i, link in ipairs(linkList) do
		if
			link.components.aipc_orbit_link ~= nil and
			link.components.aipc_orbit_link:Includes(self.orbitPoint)
		then
			local anotherPoint = link.components.aipc_orbit_link:GetAnother(self.orbitPoint)
			table.insert(orbitPointList, anotherPoint)
		end
	end

	-- 找到角度最匹配的连接点
	local targetPoint = nil
	local minAngle = 90
	local srcOrbitPointPos = self.orbitPoint:GetPosition()

	for i, anotherPoint in ipairs(orbitPointList) do
		local toPointAngle = aipGetAngle(srcOrbitPointPos, anotherPoint:GetPosition())
		local diffAngle = math.abs(angle - toPointAngle)

		if diffAngle < minAngle then
			minAngle = diffAngle
			targetPoint = anotherPoint
		end
	end

	-- 没找到就算了
	if targetPoint == nil then
		return
	end

	-- 开过去吧
	local targetPos = targetPoint:GetPosition()
	self.inst.Physics:Teleport(targetPos.x, 0, targetPos.z)
end

return Driver