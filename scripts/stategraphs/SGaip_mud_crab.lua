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
        name = "poop",
		tags = { "busy", "poop" },

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("poop")
        end,
    },

    State{
        name = "anger",
        tags = { "busy" },

        onenter = function(inst)
            if inst.components.inventoryitem then
                inst.components.inventoryitem.canbepickedup = true
            end

            inst.Physics:Stop()
            inst.AnimState:PushAnimation("anger_loop", true)
            inst.sg:SetTimeout(GetRandomWithVariance(4, 1) )
        end,
        onexit = function(inst)
            if inst.components.inventoryitem then
                inst.components.inventoryitem.canbepickedup = false
            end
        end,
        ontimeout = function(inst) inst.sg:GoToState("idle") end,
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
        name = "hide",
        tags = {"busy"},

        onenter = function(inst)
            inst.Physics:Stop()
			inst:ClearBufferedAction()
            inst.AnimState:PlayAnimation("sleep_pre", false)
        end,
		events = {
            EventHandler("animover", function(inst) inst.sg:GoToState("poop") end),
        },
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

CommonStates.AddSleepStates(states)
CommonStates.AddWalkStates(states)

return StateGraph("SGaip_mud_crab", states, events, "poop")