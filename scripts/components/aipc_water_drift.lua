local DEFAULT_SPEED = 10
local MIN_SPEED = 6
local SLOW_SEC_OCEAN = DEFAULT_SPEED * 0.25		-- 海洋衰减，水里减速的更慢
local SLOW_SEC_LAND = DEFAULT_SPEED * 0.5		-- 地面衰减
local MAX_DAMAGE = 50							-- 最大伤害，随着速度降低而增加

-- 一个只会飞行到目标地点的投掷物
local Drift = Class(function(self, inst)
	self.inst = inst
	self.speed = DEFAULT_SPEED
	self.doer = nil
end)

function Drift:Launch(pos, doer)
	aipRemove(self.inst)

	local piece = aipSpawnPrefab(doer, "aip_oldone_stone_piece", nil, 1)
	if piece.components.aipc_water_drift ~= nil then
		piece.components.aipc_water_drift:Throw(pos, doer)
	end
end

-- 转向目标点
function Drift:RotateToTarget(dest)
	local angle = aipGetAngle(self.inst:GetPosition(), dest)
	self.inst.Transform:SetRotation(angle)
	self.inst:FacePoint(dest)
end

-- 向一个方向扔出
function Drift:Throw(pos, doer)
	self.doer = doer
	self:RotateToTarget(pos)
	local dist = aipDist(doer:GetPosition(), pos)
	local maxDist = 3
	local mergedDist = math.min(dist, maxDist)
	self.speed = Remap(mergedDist,
		0, maxDist,					-- 施法距离为 10，但是我们计算只按照 3 的距离来算
		MIN_SPEED, DEFAULT_SPEED)	-- 均摊一下速度
	self.inst:StartUpdatingComponent(self)
end

function Drift:OnUpdate(dt)
	-- 更新速度
	local pos = self.inst:GetPosition()
	local slowSec = TheWorld.Map:IsOceanAtPoint(pos.x, pos.y, pos.z, false) and SLOW_SEC_OCEAN or SLOW_SEC_LAND

	local slowOffset = dt * slowSec -- 计算当前毫秒下减速
	self.speed = self.speed - slowOffset
	
	self.inst.Physics:SetMotorVel(
		self.speed,
		0,
		0
	)

	-- 判断是否撞击到目标
	local ents = TheSim:FindEntities(
		pos.x, 0, pos.z,
		0.6,
		{ "_combat", "_health" },
		{ "INLIMBO", "NOCLICK", "ghost" }
	)
	ents = aipFilterTable(ents, function(ent)
		return ent ~= self.doer
	end)

	if #ents > 0 then
		local damage = (DEFAULT_SPEED - self.speed) / DEFAULT_SPEED * MAX_DAMAGE

		for i, v in ipairs(ents) do
			if
				v.components.combat ~= nil and
				v.components.health ~= nil and
				not v.components.health:IsDead()
			then
				v.components.combat:GetAttacked(self.doer, damage)
			end
		end
	end

	-- 停止活动
	if self.speed <= 0 or #ents > 0 then
		self.inst:StopUpdatingComponent(self)

		-- 告知附近的荷叶怪圈
		local ents = aipFindNearEnts(self.inst, {"aip_oldone_lotus"}, 20)
		for i, ent in ipairs(ents) do
			if ent._aipCheckDrift ~= nil then
				ent._aipCheckDrift(ent, self.inst, self.doer)
			end
		end

		-- 删除元素
		aipReplacePrefab(self.inst, "collapse_small")
	end
end

return Drift