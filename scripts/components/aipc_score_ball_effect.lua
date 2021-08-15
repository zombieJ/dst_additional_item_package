-- 一个只会飞行到目标地点的投掷物
local ScoreBallEffect = Class(function(self, inst)
	self.inst = inst
	self.ball = nil
	self.ySpeed = net_float(inst.GUID, "aipc_score_y_speed")
end)

-- 播放动画
function ScoreBallEffect:StartPlay(continueBump, speed, y)
	if not self.ball then
		return
	end

	if continueBump ~= true then
		local anim = math.random() > .5 and "runLeft" or "runRight"

		if self.ball.AnimState:IsCurrentAnimation("idle") then
			self.ball.AnimState:PlayAnimation(anim, true)
		elseif not self.ball.AnimState:IsCurrentAnimation(anim) then
			local len = self.ball.AnimState:GetCurrentAnimationLength() / FRAMES
			local time = self.ball.AnimState:GetCurrentAnimationTime()
			local reverseTime = len - time
			self.ball.AnimState:PlayAnimation(anim, true)
			self.ball.AnimState:SetTime(math.max(reverseTime, 1))
		end
	end
	self.ball.AnimState:SetDeltaTimeMultiplier(0.5 + speed * 2)
	self.ball.AnimState:Resume()

	self.ball.Physics:Teleport(0, y, 0)
	self.inst:StartUpdatingComponent(self)
end

-- 停止动画
function ScoreBallEffect:StopPlay()
	if not self.ball then
		return
	end

	self.ball.AnimState:Pause()

	self.ball.Physics:Teleport(0, 0, 0)
	self.inst:StopUpdatingComponent(self)
end

-- 同步高度
function ScoreBallEffect:SyncYSpeed(ySpeed)
	self.ySpeed:set(ySpeed)
end

function ScoreBallEffect:OnUpdate(dt)
	local x, y, z = self.ball.Transform:GetWorldPosition()
	self.ball.Physics:Teleport(0, y + self.ySpeed:value() * dt, 0)
end


return ScoreBallEffect