local CD = 5
local DIV = 15
local DIST = 3

local function onHealthDelta(owner, data)
	local sb = owner.components.aipc_steel_ball

	if sb ~= nil and data ~= nil and data.amount < 0 then
		if not sb:CanSteel() then
			return
		end

		-- 转移了，重置一下时间
		sb.lastTransTime = os.time()

		local uselessBalls = {}
		local doEffect = false

		for _, ball in pairs(sb.balls) do
			if doEffect then
				break
			end

			if ball ~= nil and ball:IsValid() then
				-- 寻找球附近的物体
				local pt = ball:GetPosition()
				local ents = TheSim:FindEntities(pt.x, pt.y, pt.z, DIST, nil, { "INLIMBO" })

				for _, ent in pairs(ents) do
					if
						ent ~= nil and ent:IsValid() and not ent:IsInLimbo() and
						ent.components.workable ~= nil and ent.components.workable:CanBeWorked()
					then
						ent.components.workable:WorkedBy(owner, math.ceil(- data.amount / DIV))
						data.amount = 0
						doEffect = true
						aipSpawnPrefab(ent, "aip_shadow_wrapper").DoShow()

						-- 重置 CD
						sb.canSteel = false
						sb.syncTask = sb.inst:DoTaskInTime(CD, function()
							sb.canSteel = true
							sb.syncTask = nil
							sb:SyncState()
						end)

						break
					end
				end

				if not doEffect then
					table.insert(uselessBalls, ball)
				end
			end
		end

		-- 移除无用之球（直接创建一个新的掉落）
		for _, ball in pairs(uselessBalls) do
			sb:Unregister(ball)

			aipFlingItem(
				aipReplacePrefab(ball, "aip_steel_ball")
			)
		end

		sb:SyncState()
	end
end

local SteelBall = Class(function(self, inst)
	self.inst = inst

	self.balls = {}
	self.aura = nil
	self.canSteel = nil
	self.syncTask = nil

	inst:ListenForEvent("aip_healthdelta", onHealthDelta)
end)

function SteelBall:CanSteel()
	return self.canSteel
end

function SteelBall:SyncState()
	-- 初始化时总是可以
	if self.canSteel == nil then
		self.canSteel = true
	end

	-- 如果没有球则不行
	if #self.balls == 0 then
		self.canSteel = false
	end

	if self.canSteel and self.aura == nil then
		self.aura = SpawnPrefab("aip_aura_steel")
		self.aura.AnimState:PlayAnimation("in")
		self.aura.AnimState:PushAnimation("idle", true)
		self.inst:AddChild(self.aura)
	elseif not self.canSteel and self.aura ~= nil then
		aipSpawnPrefab(self.inst, "aip_shadow_wrapper").DoShow()
		self.aura:Remove()
		self.aura = nil
	end
end

function SteelBall:Register(ball)
	table.insert(self.balls, ball)
	self:SyncState()
end

function SteelBall:Unregister(ball)
	aipTableRemove(self.balls, ball)
	self:SyncState()
end

function SteelBall:OnRemoveEntity()
	self.inst:RemoveEventCallback("aip_healthdelta", onHealthDelta)
	if self.syncTask ~= nil then
		self.syncTask:Cancel()
		self.syncTask = nil
	end
end

SteelBall.OnRemoveFromEntity = SteelBall.OnRemoveEntity

return SteelBall