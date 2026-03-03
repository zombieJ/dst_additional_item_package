require("stategraphs/commonstates")

local events = {
    CommonHandlers.OnStep(),
    CommonHandlers.OnLocomote(true, true),
}

local states = {
	State{
        name = "idle",
        tags = { "idle" },

        onenter = function(inst)
            inst.Physics:Stop()

            inst.AnimState:PlayAnimation("idle_loop", true)
        end,

        events = {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },
}

CommonStates.AddWalkStates(states, {
    walktimeline = {
        TimeEvent(0, PlayFootstep),
        TimeEvent(12 * FRAMES, PlayFootstep),
    },
})

CommonStates.AddRunStates(states, {
    starttimeline = {
        -- TimeEvent(0, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/perd/run") end),
    },
    runtimeline = {
        TimeEvent(0, PlayFootstep),
        -- TimeEvent(5 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/perd/run") end),
        TimeEvent(10 * FRAMES, PlayFootstep),
    },
})

CommonStates.AddIdle(states, "gobble_idle")

return StateGraph("SGaip_dragon_footprint", states, events, "idle")