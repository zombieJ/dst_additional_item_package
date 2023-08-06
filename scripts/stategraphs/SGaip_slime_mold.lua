require("stategraphs/commonstates")

local events = {
	EventHandler("death", function(inst)
        inst.sg:GoToState("death")
    end),
	CommonHandlers.OnSleep(),
    CommonHandlers.OnLocomote(false, true),
}

local states = {
    State{
        name = "idle",
        tags = { "idle", "canrotate" },

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            if not inst.AnimState:IsCurrentAnimation("idle_loop") then
                inst.AnimState:PlayAnimation("idle_loop", true)
            end
        end,
    },

	State{
        name = "death",
        tags = { "busy", "death" },

        onenter = function(inst)
			inst.AnimState:PlayAnimation("death")

            inst.Physics:Stop()
            RemovePhysicsColliders(inst)
            inst:AddTag("NOCLICK")
            inst.persists = false
        end,
    },
}

CommonStates.AddWalkStates(states)

return StateGraph("SGaip_mud_crab", states, events, "idle")