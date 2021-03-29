require("stategraphs/commonstates")

local events =
{
	EventHandler("death", function(inst) inst.sg:GoToState("death") end),
    CommonHandlers.OnAttack(),
    CommonHandlers.OnLocomote(false, true),
}

local states =
{
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
        name = "attack",
        tags = { "attack", "busy" },

        onenter = function(inst, target)
            inst.sg.statemem.target = target
            inst.Physics:Stop()
            inst.components.combat:StartAttack()
            inst.AnimState:PlayAnimation("attack")
            -- PlayExtendedSound(inst, "attack_grunt")
            inst.sg.statemem.target = inst.components.combat.target
        end,

        timeline = {
            -- TimeEvent(14*FRAMES, function(inst) PlayExtendedSound(inst, "attack") end),
            TimeEvent(12*FRAMES, function(inst) inst.components.combat:DoAttack(inst.sg.statemem.target) end),
        },
        events = {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

	State{
        name = "death",
        tags = { "busy" },

        onenter = function(inst)
			-- PlayExtendedSound(inst, "death")
			inst.AnimState:PlayAnimation("death")
            inst.Physics:Stop()
            RemovePhysicsColliders(inst)
            inst.components.lootdropper:DropLoot(inst:GetPosition())
            inst:AddTag("NOCLICK")
            inst.persists = false
        end,
        onexit = function(inst)
            inst:RemoveTag("NOCLICK")
        end
    },
}

CommonStates.AddWalkStates(states, nil, nil, true)

return StateGraph("SGaip_dragon", states, events, "idle")