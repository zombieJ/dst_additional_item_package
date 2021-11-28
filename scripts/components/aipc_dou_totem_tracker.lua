local createProjectile = require("utils/aip_vest_util").createProjectile

-- 寻找符合名字的物品
local function findGroundItem(pos, name)
    local ents = aipFindNearEnts(pos, {name}, 3)
    ents = aipFilterTable(ents, function(inst)
        return inst.components.inventoryitem ~= nil and
                inst.components.inventoryitem:GetGrandOwner() == nil
    end)
    return ents[1]
end

------------------------------ 组件 ------------------------------------
local Tracker = Class(function(self, inst)
	self.inst = inst
	self.loopTimer = nil
	self.motionTimer = nil

	self.chest = nil

	self.suwu = nil
	self.ball = nil
	self.hat = nil

	self.speed = 3
	self.dist = nil
	self.rotate = nil
end)

function Tracker:IsFull()
	return self.suwu ~= nil and self.ball ~= nil and self.hat ~= nil
end

------------------------------ 生成 ------------------------------------
function Tracker:CreateChest()
	if self.motionTimer ~= nil then
		self.motionTimer:Cancel()
		self.motionTimer = nil
	end

	if self:IsFull() then
		aipReplacePrefab(self.suwu, "aip_shadow_wrapper").DoShow()
		aipReplacePrefab(self.ball, "aip_shadow_wrapper").DoShow()
		aipReplacePrefab(self.hat, "aip_shadow_wrapper").DoShow()

		self.suwu = nil
		self.ball = nil
		self.hat = nil

		-- 寻找是否存在盒子
		local tgtPT = nil
		local eyeBox = aipFindEnt("aip_eye_box")

		if eyeBox ~= nil then
			tgtPT = eyeBox:GetPosition()
		else
			local tree = aipFindRandomEnt(
				"evergreen",
				"evergreen_normal", "evergreen_tall", "evergreen_short",
				"evergreen_sparse_normal", "evergreen_sparse_tall", "evergreen_sparse_short"
			)

			if tree ~= nil then
				tgtPT = aipGetSecretSpawnPoint(tree:GetPosition(), 1, 10, 5)
				aipSpawnPrefab(nil, "aip_eye_box", tgtPT.x, tgtPT.y, tgtPT.z)
			end
		end

		if tgtPT ~= nil then
			-- 创建一个飞行轨迹过去
			createProjectile(self.inst, tgtPT, nil, { 0, 0, 0, 5 }, 20)
		end
	end
end

------------------------------ 动画 ------------------------------------
local function initPrefab(inst)
	-- inst.Physics:SetSphere(0)
	inst:AddTag("NOCLICK")
	inst:AddComponent("aipc_float")
	inst:RemoveComponent("inventoryitem")
end

function Tracker:MovePrefab(inst, pos, rotate, offsetHeight)
	local radius = rotate / 180 * PI

	-- 目标位置
	local targetPos = Vector3(
		pos.x + math.cos(radius) * self.dist,
		pos.y + offsetHeight,
		pos.z + math.sin(radius) * self.dist
	)

	inst.components.aipc_float.speed = self.speed
	inst.components.aipc_float:MoveToPoint(targetPos)
end

function Tracker:LoopMotion()
	if not self:IsFull() then
		return
	end

	local pos = self.inst:GetPosition()
	self.rotate = self.rotate + 10

	-- 高度计算
	local startCnt = 2
	local flyCnt = 2

	local rndCnt = self.rotate / 360
	local offsetHeight = math.max(rndCnt - startCnt, 0)
	offsetHeight = math.min(offsetHeight, 2)

	self:MovePrefab(self.suwu, pos, self.rotate, offsetHeight)
	self:MovePrefab(self.ball, pos, self.rotate + 120, offsetHeight)
	self:MovePrefab(self.hat, pos, self.rotate + 240, offsetHeight)

	self.speed = math.min(self.speed + 0.05, 6)

	if rndCnt > startCnt + flyCnt then
		self:CreateChest()
	end
end

-- 启动动画
function Tracker:StartMotion()
	if not self:IsFull() or self.dist ~= nil or self.rotate ~= nil then
		return
	end

	local pos = self.inst:GetPosition()

	initPrefab(self.suwu)
	initPrefab(self.ball)
	initPrefab(self.hat)

	self.dist = 3
	self.rotate = 0

	self.motionTimer = self.inst:DoPeriodicTask(0.1, function()
		self:LoopMotion()
	end, 0.1)
end

------------------------------ 触发 ------------------------------------
function Tracker:StartCheck()
	self:StopCheck()

	self.loopTimer = self.inst:DoPeriodicTask(2, function()
		if self:IsFull() or self.chest ~= nil then
			return
		end

		local pos = self.inst:GetPosition()
		self.suwu = findGroundItem(pos, "aip_suwu")
		self.ball = findGroundItem(pos, "aip_score_ball")
		self.hat = findGroundItem(pos, "aip_wizard_hat")

		if self:IsFull() then
			self:StartMotion()
		end
	end)
end

function Tracker:StopCheck()
	if self.loopTimer ~= nil then
		self.loopTimer:Cancel()
		self.loopTimer = nil
	end
end

function Tracker:OnEntityWake()
	self:StartCheck()
end

function Tracker:OnEntitySleep()
	self:StopCheck()

	if self:IsFull() then
		self:CreateChest()
	end
end

function Tracker:OnRemoveFromEntity()
	if self:IsFull() then
		self:CreateChest()
	end
end

return Tracker