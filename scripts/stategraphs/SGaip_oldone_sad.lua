require("stategraphs/commonstates")

local events = {
	EventHandler("death", function(inst)
        inst.sg:GoToState("death")
    end),
    CommonHandlers.OnAttack(),
    CommonHandlers.OnLocomote(false, true),
}

local states = {
    State{
        name = "appear",
        tags = { "busy" },

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("appear", false)
        end,
        events = {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

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
        tags = { "busy" },

        onenter = function(inst)
            inst.AnimState:PlayAnimation("death")

            inst.Physics:Stop()
            RemovePhysicsColliders(inst)
            inst:AddTag("NOCLICK")
            inst.persists = false
        end,
        events = {
            EventHandler("animover", function(inst) inst:Remove() end),
        },
    },
}

CommonStates.AddWalkStates(states, nil, nil, true)

return StateGraph("SGaip_oldone_sad", states, events, "appear")