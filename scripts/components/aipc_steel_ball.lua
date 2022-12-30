local CD = 0.1
local DIV = 15
local DIST = 3

local function onHealthDelta(owner, data)
	local sb = owner.components.aipc_steel_ball

	if sb ~= nil and data ~= nil and data.amount < 0 then
		local now = os.time()

		if now - sb.lastTransTime < CD then
			return
		end

		-- 转移了，重置一下时间
		sb.lastTransTime = now

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
	end
end

local SteelBall = Class(function(self, inst)
	self.inst = inst

	self.balls = {}
	self.lastTransTime = 0

	inst:ListenForEvent("aip_healthdelta", onHealthDelta)
end)

function SteelBall:Register(ball)
	table.insert(self.balls, ball)
end

function SteelBall:Unregister(ball)
	aipTableRemove(self.balls, ball)
end

function SteelBall:OnRemoveEntity()
	self.inst:RemoveEventCallback("aip_healthdelta", onHealthDelta)
end

SteelBall.OnRemoveFromEntity = SteelBall.OnRemoveEntity

return SteelBall