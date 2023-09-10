local _G = GLOBAL
local State = _G.State

---------------------------------------------------------------------------------
--                                   域外空间                                   --
---------------------------------------------------------------------------------
local RANGE = 1900

-- 是否在特殊空间里
local function inPlace(x, z, offset)
    offset = offset or 50
    return x >= RANGE - offset and x <= RANGE + offset and
            z >= RANGE - offset and z <= RANGE + offset
end


AddPrefabPostInit("world", function(inst)
    local map = _G.getmetatable(inst.Map).__index
    if map then
        local old_IsAboveGroundAtPoint = map.IsAboveGroundAtPoint
        map.IsAboveGroundAtPoint = function(self, x, y, z, ...)
            if inPlace(x, z) then
                return true
            end
            return old_IsAboveGroundAtPoint(self, x, y, z, ...)
        end

        local old_IsVisualGroundAtPoint = map.IsVisualGroundAtPoint
        map.IsVisualGroundAtPoint = function(self, x, y, z, ...)
            if inPlace(x, z) then
                return true
            end
            return old_IsVisualGroundAtPoint(self, x, y, z, ...)
        end

        local old_GetTileCenterPoint = map.GetTileCenterPoint
        map.GetTileCenterPoint = function(self, x, y, z)
            if inPlace(x, z, 0) then
                return math.floor(x / 4) * 4 + 2, 0, math.floor(z / 4) * 4 + 2
            end
            if z then
                return old_GetTileCenterPoint(self, x, y, z)
            else
                return old_GetTileCenterPoint(self, x, y)
            end
        end
    end
end)

AddComponentPostInit("birdspawner", function(self)
	local oriSpawnBird = self.SpawnBird

	function self:SpawnBird(spawnpoint, ...)
		-- 黑域不会有鸟
		if inPlace(spawnpoint.x, spawnpoint.z) then
			_G.aipPrint("BLOCK Bird Spawn")
			return
		end

		return oriSpawnBird(self, spawnpoint, ...)
	end
end)

AddPrefabPostInit("world", function(inst)
	if _G.TheNet:GetIsServer() or _G.TheNet:IsDedicated() then
		if not inst.components.aipc_blackhole then
			inst:AddComponent("aipc_blackhole")
		end
	end
end)


---------------------------------------------------------------------------------
--                                   鸟类劫持                                   --
---------------------------------------------------------------------------------
-- 鸟不允许随机离开，只能往目标点跳过去
AddStategraphPostInit("bird", function(sg)
	-- 覆盖默认行为
	local originIdleTimeout = sg.states.idle.ontimeout

	sg.states.idle.ontimeout = function(inst, ...)
		if inst._aipHome then
			local r = math.random()

			inst.sg:GoToState(
				(r < .7 and "hop") or
				(r < .8 and "peck") or
				(r < .9 and "idle") or
				"caw"
			)
			return
		end

		return originIdleTimeout(inst, ...)
	end

	
	-- 不能飞走
	local originFlyaway = sg.states.flyaway.onenter
	
	sg.states.flyaway.onenter = function(inst, ...)
		if inst._aipHome then
			inst.sg:GoToState("idle")
			return
		end

		return originFlyaway(inst, ...)
	end
end)

---------------------------------------------------------------------------------
--                                   落水状态                                   --
---------------------------------------------------------------------------------
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

				local pos = inst:GetPosition()
				-- 触发游戏状态
				if _G.TheWorld.components.aipc_blackhole then
					_G.TheWorld.components.aipc_blackhole:StartGame()

					pos = _G.TheWorld.components.aipc_blackhole.gamePos
				end

				-- 设置坐标
				local pt = inst:GetPosition()
				inst.components.drownable.dest_x = pos.x
				inst.components.drownable.dest_y = pos.y
				inst.components.drownable.dest_z = pos.z
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
