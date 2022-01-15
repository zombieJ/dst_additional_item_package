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

------------------------------------ 无状态方法 ------------------------------------
local function findPoints(current, excluded)
	local linkList = aipFindNearEnts(current, { "aip_glass_orbit_link" }, 15)

	local includedLinks = aipFilterTable(linkList, function(link)
		return	link.components.aipc_orbit_link ~= nil and
				link.components.aipc_orbit_link:Includes(current) and
				not link.components.aipc_orbit_link:Includes(excluded)
	end)

	local orbitPointList = {}

	for i, link in ipairs(includedLinks) do
		local anotherPoint = link.components.aipc_orbit_link:GetAnother(current)
		table.insert(orbitPointList, anotherPoint)
	end

	return orbitPointList
end

----------------------------------- 双端通用组件 -----------------------------------
local Driver = Class(function(self, player)
	self.inst = player
	self.minecar = nil
	self.orbitPoint = nil
	self.nextOrbitPoint = nil
	self.speed = 10
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
	self.inst:AddTag("aip_orbit_driver")

	MakeGhostPhysics(self.inst, 1, .5)

	return true
end

------------------------------- 开车啦 ------------------------------------------------
-- 如果没有在运行，则找下一个可过去的点开过去
function Driver:DriveFromPoint(angle)
	self.nextOrbitPoint = nil
	

	-- 找到附近所有的连接器，对应的端点
	local orbitPointList = findPoints(self.orbitPoint)

	-- 找到角度最匹配的连接点
	local targetPoint = nil
	local minAngle = 90
	local srcOrbitPointPos = self.orbitPoint:GetPosition()

	for i, anotherPoint in ipairs(orbitPointList) do
		local toPointAngle = aipGetAngle(srcOrbitPointPos, anotherPoint:GetPosition())
		local diffAngle = aipDiffAngle(angle, toPointAngle)

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
	self.nextOrbitPoint = targetPoint

	self.inst:StartUpdatingComponent(self)
end

-- 如果是驾驶过程中，则看看是不是顺路，不顺路则返回
function Driver:DriveBack(angle)
	local orbitAngle = aipGetAngle(self.orbitPoint:GetPosition(), self.nextOrbitPoint:GetPosition())

	if aipDiffAngle(angle, orbitAngle) > 90 then
		local tmpOrbitPoint = self.nextOrbitPoint
		self.nextOrbitPoint = self.orbitPoint
		self.orbitPoint = tmpOrbitPoint
	end
end

function Driver:DriveTo(x, z, exit)
	if not self:CanDrive() then
		return
	end

	-- 退出了就不要做什么操作了
	if exit then
		self:AbortDrive()
		return
	end

	local angle = aipGetAngle(Vector3(0, 0, 0), Vector3(x, 0, z))
	
	if self.nextOrbitPoint == nil then
		self:DriveFromPoint(angle)
	else
		self:DriveBack(angle)
	end
end

function Driver:StopDrive()
	self.inst:StopUpdatingComponent(self)
	self.inst.Physics:Stop()
end

function Driver:AbortDrive()
	self:StopDrive()
	self.inst.sg:GoToState("idle")
	self.inst:RemoveTag("aip_orbit_driver")
	MakeCharacterPhysics(self.inst, 75, .5)

	-- 矿车掉落
	local pt = self.inst:GetPosition()
	self.minecar:Show()
	self.inst.Physics:Teleport(pt.x, pt.y, pt.z)
	self.minecar.Physics:Teleport(pt.x, pt.y, pt.z)

	self.minecar:RemoveTag("NOCLICK")
	self.minecar:RemoveTag("fx")

	if self.minecar.components.lootdropper ~= nil then
		self.minecar.components.lootdropper:FlingItem(self.minecar, pt)
	end

	if self.minecar.components.inventoryitem ~= nil then
		self.minecar.components.inventoryitem.canbepickedup = true
	end

	-- 用完即弃
	if self.minecar.components.finiteuses ~= nil then
		self.minecar.components.finiteuses:Use()

		if self.minecar.components.finiteuses:GetUses() <= 0 then
			aipReplacePrefab(self.minecar, "collapse_big")
		end
	end

	-- 清空状态
	self.minecar = nil
	self.orbitPoint = nil
	self.nextOrbitPoint = nil
end

function Driver:OnUpdate(dt)
	-- TODO: 如果运动无效，应该断开移动才对
	if self.orbitPoint == nil or self.nextOrbitPoint == nil then
		self:StopDrive()
		return
	end

	-- 向目标移动
	local targetPos = self.nextOrbitPoint:GetPosition()
	self.inst:ForceFacePoint(targetPos.x, 0, targetPos.z)
	self.inst.Physics:SetMotorVel(self.speed, 0, 0)

	-- 如果到达了就选择下一个目标
	local playerPos = self.inst:GetPosition()
	local dist = aipDist(playerPos, targetPos)
	if dist < .5 then
		-- 矿车位移到玩家位置
		self.minecar.Physics:Teleport(playerPos.x, playerPos.y, playerPos.z)

		local points = findPoints(self.nextOrbitPoint, self.orbitPoint)
		self.orbitPoint = self.nextOrbitPoint
		self.nextOrbitPoint = nil

		if #points == 1 then
			self.nextOrbitPoint = points[1]
		else
			self:StopDrive()
			return
		end
	end
end

return Driver