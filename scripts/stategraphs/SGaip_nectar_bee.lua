require("stategraphs/commonstates")

local actionhandlers = {
    ActionHandler(ACTIONS.EAT, "eat"),
}

local events = {
	-- EventHandler("eat", function(inst)
    --     inst.components.locomotor:Stop()
    --     inst:ClearBufferedAction()

    --     inst.sg:GoToState("eat")
    -- end),
	-- CommonHandlers.OnSleep(),
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

	State{  -- 吃东西
        name = "eat",
        tags = { "idle", "eating", "busy" },

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("eat")
        end,

        events = {
            EventHandler("animover", function(inst)
                aipPrint("end eating!")
                inst.sg:GoToState("idle")
            end)
        },
    },
}

CommonStates.AddWalkStates(states)

return StateGraph("SGaip_nectar_bee", states, events, "idle", actionhandlers)