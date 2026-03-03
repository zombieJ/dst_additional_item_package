require("stategraphs/commonstates")

local events = {
    CommonHandlers.OnLocomote(true, true),
    EventHandler("talk", function(inst)
        inst.components.locomotor:Stop()
        inst:ClearBufferedAction()

        inst.sg:GoToState("talk")
    end),
    EventHandler("throw", function(inst, data)
        if not inst.sg:HasStateTag("busy") then
            inst.components.locomotor:Stop()
            inst:ClearBufferedAction()

            inst.sg:GoToState("throw", data.target)
        end
    end),
}

local states = {
    State{ -- 击球
        name = "throw",
        tags = { "throw", "busy" },

        onenter = function(inst, target)
            inst.sg.statemem.target = target
            inst.AnimState:PlayAnimation("throw")
            inst.Physics:Stop()
        end,

        timeline = {-- 30*100/1000
            TimeEvent(3*FRAMES, function(inst)
                inst.aipThrowBallBack(inst, inst.sg.statemem.target)
            end),
        },

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