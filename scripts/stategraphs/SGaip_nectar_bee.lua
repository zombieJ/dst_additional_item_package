require("stategraphs/commonstates")

local actionhandlers = {
    ActionHandler(ACTIONS.EAT, "eat"),
}

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

	State{  -- 吃东西
        name = "eat",
        tags = { "eating", "busy" },

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("eat", false)
        end,

        timeline = {
            TimeEvent(10 * FRAMES, function(inst)
                inst:PerformBufferedAction()
            end),
        },

        events = {
            EventHandler("animover", function(inst)
                if inst._aipGift ~= nil then
                    inst.sg:GoToState("gift")
                else
                    inst.sg:GoToState("idle")
                end
            end)
        },
    },

	State{  -- 送礼
        name = "gift",
        tags = { "busy" },

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("gift", false)
        end,

        timeline = {
            TimeEvent(10 * FRAMES, function(inst)
                if inst._aipGift ~= nil then
                    local pt = inst:GetPosition()
                    pt.y = pt.y + 2
                    aipFlingItem(aipSpawnPrefab(inst, inst._aipGift), pt)
                end
            end),
        },

        events = {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end)
        },
    },
}

CommonStates.AddWalkStates(states)

return StateGraph("SGaip_nectar_bee", states, events, "idle", actionhandlers)