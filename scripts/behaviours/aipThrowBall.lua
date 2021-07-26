ThrowBall = Class(BehaviourNode, function(self, inst)
    BehaviourNode._ctor(self, "ThrowBall")
    self.inst = inst
end)

function ThrowBall:__tostring()
    return string.format("target %s", tostring(self.target))
end

local MUST_TAGS = { "aip_score_ball" }

function ThrowBall:Visit()
    if self.status == READY then
        self.target = nil
		local x, y, z = self.inst.Transform:GetWorldPosition()

        local balls = TheSim:FindEntities(x, 0, z, 15, MUST_TAGS)
        for i, ball in ipairs(balls) do
            if ball.components.aipc_score_ball:CanFollow() then
                self.target = ball
                break
            end
        end

        if self.target ~= nil then
            self.status = RUNNING
            self.inst.components.locomotor:Stop()
            self.done = false
        else
            self.status = FAILED
        end
    end

    if self.status == RUNNING then
        if
			self.target == nil or not self.target.entity:IsValid() or
			(self.target.components.health ~= nil and self.target.components.health:IsDead()) or
			self.target.components.aipc_score_ball:CanFollow() == false or
            self.inst.components.timer:TimerExists("aip_mini_dou_dall_throw")
		then
            self.status = FAILED
            self.inst.components.locomotor:Stop()
        else
			local target_position = Point(self.target.Transform:GetWorldPosition())
			self.inst.components.locomotor:GoToPoint(
                self.target.components.aipc_score_ball:PredictPoint(0.1),
                -- target_position,
                nil,
                true
            )

			local me = Point(self.inst.Transform:GetWorldPosition())
			if self.target.components.aipc_score_ball:CanThrow() and distsq(target_position, me) < 1 then
				self.inst:PushEvent("throw", {target = self.target})
                self.inst.components.timer:StartTimer("aip_mini_dou_dall_throw", 2)
			end
            
			-- -- 不知道干啥的，就当优化用了
			-- self:Sleep(.125)
        end
    end
end
