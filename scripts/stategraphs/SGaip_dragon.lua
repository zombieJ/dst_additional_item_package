require("stategraphs/commonstates")


local function FinishExtendedSound(inst, soundid)
    inst.SoundEmitter:KillSound("sound_"..tostring(soundid))
    inst.sg.mem.soundcache[soundid] = nil
end

local function PlayExtendedSound(inst, soundname)
    if inst.sg.mem.soundcache == nil then
        inst.sg.mem.soundcache = {}
        inst.sg.mem.soundid = 0
    else
        inst.sg.mem.soundid = inst.sg.mem.soundid + 1
    end
    inst.sg.mem.soundcache[inst.sg.mem.soundid] = true
    inst.SoundEmitter:PlaySound(inst.sounds[soundname], "sound_"..tostring(inst.sg.mem.soundid))
    inst:DoTaskInTime(5, FinishExtendedSound, inst.sg.mem.soundid)
end

local events =
{
	EventHandler("death", function(inst) inst.sg:GoToState("death") end),
    CommonHandlers.OnAttack(),
    CommonHandlers.OnLocomote(false, true),
}

local states =
{
    State{
        name = "appear",
        tags = { "busy" },

        onenter = function(inst)
            inst.AnimState:PlayAnimation("appear")
            inst.Physics:Stop()
            PlayExtendedSound(inst, "appear")
        end,

        events =
        {
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

        timeline = {-- 1 秒 30 次渲染/1000 帧，200 帧时造成伤害。
            TimeEvent(0*FRAMES, function(inst) PlayExtendedSound(inst, "attack") end),
            -- 30*200/1000
            TimeEvent(6*FRAMES, function(inst) inst.components.combat:DoAttack(inst.sg.statemem.target) end),
        },
        events = {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

	State{
        name = "death",
        tags = { "busy" },

        onenter = function(inst)
			PlayExtendedSound(inst, "death")
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

return StateGraph("SGaip_dragon", states, events, "appear")