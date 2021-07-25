require("stategraphs/commonstates")

local events = {
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
}

CommonStates.AddWalkStates(states)
CommonStates.AddRunStates(states)

return StateGraph("SGaip_mini_dou", states, events, "idle")