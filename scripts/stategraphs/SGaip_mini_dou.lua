require("stategraphs/commonstates")

local events = {
    CommonHandlers.OnLocomote(false, true),
}

local states = {
    State{ -- 击球
        name = "throw",
        tags = { "busy" },

        onenter = function(inst)
            inst.AnimState:PlayAnimation("throw")
            inst.Physics:Stop()
        end,

        events = {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end)
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
}

CommonStates.AddWalkStates(states)
CommonStates.AddRunStates(states)

return StateGraph("SGaip_mini_dou", states, events, "idle")