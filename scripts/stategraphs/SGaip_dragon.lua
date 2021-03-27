require("stategraphs/commonstates")

local events =
{
	EventHandler("death", function(inst) inst.sg:GoToState("death") end),
    CommonHandlers.OnLocomote(false, true),
}

local function OnAnimOverRemove(inst)
    -- inst:Remove()
	aipPrint("dead over!!!")
end

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

		events = {
            EventHandler("animover", OnAnimOverRemove),
        },

        onexit = function(inst)
            inst:RemoveTag("NOCLICK")
        end
    },
}

CommonStates.AddWalkStates(states, nil, nil, true)

return StateGraph("SGaip_dragon", states, events, "idle")