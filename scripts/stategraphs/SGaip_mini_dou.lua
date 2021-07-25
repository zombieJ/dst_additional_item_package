require("stategraphs/commonstates")

local events = {
    CommonHandlers.OnLocomote(true, true),
    EventHandler("talk", function(inst)
        inst.components.locomotor:Stop()
        inst:ClearBufferedAction()

        inst.sg:GoToState("talk")
    end),
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

    State{  -- 说话
        name = "talk",
        tags = { "idle", "talking", "busy" },

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("dial_loop", true)
            inst.sg:SetTimeout(2 + math.random())
        end,

        ontimeout = function(inst)
            inst.sg:GoToState("idle")
        end,

        events = {
            EventHandler("donetalking", function(inst)
                inst.sg:GoToState("idle")
            end),
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