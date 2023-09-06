local _G = GLOBAL
local State = _G.State

local function ForceStopHeavyLifting(inst)
    if inst.components.inventory:IsHeavyLifting() then
        inst.components.inventory:DropItem(
            inst.components.inventory:Unequip(EQUIPSLOTS.BODY),
            true,
            true
        )
    end
end

local function StartTeleporting(inst)
    inst.sg.statemem.isteleporting = true

    inst.components.health:SetInvincible(true)
    if inst.components.playercontroller ~= nil then
        inst.components.playercontroller:Enable(false)
    end
    inst:Hide()
    inst.DynamicShadow:Enable(false)
end

local function DoneTeleporting(inst)
    inst.sg.statemem.isteleporting = false

    inst.components.health:SetInvincible(false)
    if inst.components.playercontroller ~= nil then
        inst.components.playercontroller:Enable(true)
    end
    inst:Show()
    inst.DynamicShadow:Enable(true)
end

---------------------------------------------------------------------------------
--                                   转换状态                                   --
---------------------------------------------------------------------------------
AddStategraphState("wilson", State {
    name = "aip_sink_space",
	tags = { "busy", "nopredict", "nomorph", "drowning", "nointerrupt" },

	onenter = function(inst, shore_pt)
		ForceStopHeavyLifting(inst)
		inst:ClearBufferedAction()

		inst.components.locomotor:Stop()
		inst.components.locomotor:Clear()

		inst.AnimState:PlayAnimation("sink")
		inst.SoundEmitter:PlaySound((inst.talker_path_override or "dontstarve/characters/")..(inst.soundsname or inst.prefab).."/sinking")
		if inst.components.rider:IsRiding() then
			inst.sg:AddStateTag("dismounting")
		end

		-- if shore_pt ~= nil then
		-- 	inst.components.drownable:OnFallInOcean(shore_pt:Get())
		-- else
		-- 	inst.components.drownable:OnFallInOcean()
		-- end
		inst.DynamicShadow:Enable(false)

		inst:ShowHUD(false)
	end,

	timeline = {
		_G.TimeEvent(75 * _G.FRAMES, function(inst)
			-- inst.components.drownable:DropInventory()
			inst.SoundEmitter:PlaySound("turnoftides/common/together/water/splash/medium")
		end),
	},

	events = {
		_G.EventHandler("animover", function(inst)
			if inst.AnimState:AnimDone() then
				StartTeleporting(inst)

				if inst.sg:HasStateTag("dismounting") then
					inst.sg:RemoveStateTag("dismounting")

					local mount = inst.components.rider:GetMount()
					inst.components.rider:ActualDismount()
					-- if mount ~= nil then
					-- 	if mount.components.drownable ~= nil then
					-- 		mount:Hide()
					-- 		mount:PushEvent("onsink", {noanim = true, shore_pt = Vector3(inst.components.drownable.dest_x, inst.components.drownable.dest_y, inst.components.drownable.dest_z)})
					-- 	elseif mount.components.health ~= nil then
					-- 		mount:Hide()
					-- 		mount.components.health:Kill()
					-- 	end
					-- end
				end

				-- 设置坐标
				local pt = inst:GetPosition()
				inst.components.drownable.dest_x = pt.x
				inst.components.drownable.dest_y = pt.y
				inst.components.drownable.dest_z = pt.z
				inst.components.drownable:WashAshore() -- TODO: try moving this into the timeline
			end
		end),

		_G.EventHandler("on_washed_ashore", function(inst)
			-- inst.sg:GoToState("washed_ashore")
			inst.sg:GoToState("wakeup")
		end),
	},

	onexit = function(inst)
		-- if inst.sg.statemem.isphysicstoggle then
		-- 	ToggleOnPhysics(inst)
		-- end

		if inst.sg.statemem.isteleporting then
			DoneTeleporting(inst)
		end

		inst.DynamicShadow:Enable(true)
		inst:ShowHUD(true)
	end,
})
