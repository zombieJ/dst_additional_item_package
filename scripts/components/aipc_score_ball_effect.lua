local function onPlayChange(inst)
	local self = inst.components.aipc_score_ball_effect
	if self ~= nil and self.ball ~= nil then
		local xSpeed = self.xSpeed:value()
		if xSpeed ~= 0 then
			self:ClientPlay()
		else
			self:ClientStop()
		end
	end
end

local ScoreBallEffect = Class(function(self, inst)
	self.inst = inst
	self.ball = nil

	self.ySpeed = net_float(inst.GUID, "aipc_score_ball_y_speed")

	-- 动画相关
	self.continueBump = net_bool(inst.GUID, "aipc_score_ball_continue")
	self.xSpeed = net_float(inst.GUID, "aipc_score_ball_x_speed",  "aipc_score_ball_x_speed_dirty")
	self.y = net_float(inst.GUID, "aipc_score_ball_y")

	self.inst:ListenForEvent("aipc_score_ball_x_speed_dirty", onPlayChange)
end)

-----------------------------------------------------------------------------
--                                  服务端                                  --
-----------------------------------------------------------------------------
-- 播放动画
function ScoreBallEffect:StartPlay(continueBump, speed, y)
	self.continueBump:set(continueBump == true)
	self.y:set(y)
	self.xSpeed:set(speed)
end

-- 停止动画
function ScoreBallEffect:StopPlay()
	self.xSpeed:set(0)
end

-----------------------------------------------------------------------------
--                                  客户端                                  --
-----------------------------------------------------------------------------
-- 播放动画
function ScoreBallEffect:ClientPlay()
	local newJump = self.continueBump:value() ~= true

	if newJump then
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

	self.ball.AnimState:SetDeltaTimeMultiplier(0.3 + math.sqrt(self.xSpeed:value() * 5))
	self.ball.AnimState:Resume()

	-- 新弹起的时候重置高度
	if newJump then
		self.ball.Physics:Teleport(0, self.y:value(), 0)
	end

	self.inst:StartUpdatingComponent(self)
end

-- 停止动画
function ScoreBallEffect:ClientStop()
	self.ball.AnimState:Pause()

	self.ball.Physics:Teleport(0, 0, 0)
	self.inst:StopUpdatingComponent(self)
end

-- 同步高度
function ScoreBallEffect:SyncY(y, ySpeed)
	self.y:set(y)
	self.ySpeed:set(ySpeed)
end

function ScoreBallEffect:OnUpdate(dt)
	local x, y, z = self.ball.Transform:GetWorldPosition()
	local realY = self.y:value()
	local targetY = y + self.ySpeed:value() * dt

	-- 努力往服务端的 y 坐标追去
	local diffY = targetY * 0.95 + realY * 0.05

	self.ball.Physics:Teleport(0, diffY, 0)
end


return ScoreBallEffect