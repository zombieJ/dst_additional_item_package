local _G = GLOBAL

---------------------------------------- 驾驶 ----------------------------------------
local AIP_DRIVE = env.AddAction("AIP_DRIVE", "Drive", function(act)
	-- Client Only Code
	local doer = act.doer
	local target = act.target

	-- 驾驶吧
	if target.components.aipc_minecar ~= nil and target.components.aipc_minecar.driver == nil then
		target.components.aipc_minecar:AddDriver(doer)
		return true
	end
	return false, "INUSE"
end)
AddStategraphActionHandler("wilson", GLOBAL.ActionHandler(AIP_DRIVE, "dolongaction"))
AddStategraphActionHandler("wilson_client", GLOBAL.ActionHandler(AIP_DRIVE, "dolongaction"))

-------------------------------------- 停止驾驶 --------------------------------------
local AIP_UNDRIVE = env.AddAction("AIP_UNDRIVE", "Stop Drive", function(act)
	-- Client Only Code
	local doer = act.doer
	local target = act.target

	-- 停止驾驶吧
	if target.components.aipc_minecar ~= nil and target.components.aipc_minecar.driver == doer then
		target.components.aipc_minecar:RemoveDriver(doer)
		return true
	end
	return false, "INUSE"
end)
AddStategraphActionHandler("wilson", GLOBAL.ActionHandler(AIP_UNDRIVE, "doshortaction"))
AddStategraphActionHandler("wilson_client", GLOBAL.ActionHandler(AIP_UNDRIVE, "doshortaction"))

------------------------------------ 绑定矿车行为 ------------------------------------
env.AddComponentAction("SCENE", "aipc_minecar_client", function(inst, doer, actions, right)
	-- 检查是否是驾驶设备
	if not inst.components.aipc_minecar_client then
		return
	end

	-- 检查是否可驾驶
	if inst.components.aipc_minecar_client:CanDrive() and not doer:HasTag("aip_minecar_driver") then
		table.insert(actions, GLOBAL.ACTIONS.AIP_DRIVE)
		return
	end

	-- 检查是否可停止驾驶
	if inst.components.aipc_minecar_client:HasDriver(doer) then
		table.insert(actions, GLOBAL.ACTIONS.AIP_UNDRIVE)
		return
	end
end)

-------------------------------------------------------------------------------------
---------------------------------------- 修理 ----------------------------------------
local AIP_PATCH = env.AddAction("AIP_PATCH", "Patch", function(act)
	local doer = act.doer
	local item = act.invobject
	local target = act.target

	-- 由于还没有其他的地方需要用到修理，这里简单判断一下就行了
	if item ~= nil and target.components.finiteuses ~= nil and target.components.finiteuses:GetPercent() < 1 then
		local currentUses = target.components.finiteuses:GetUses()
		local totalUses = target.components.finiteuses.total
		local repairValue = item.prefab == "boards" and 5 or 1

		-- 薇诺娜 可以修复的更好
		if doer.prefab ~= "winona" then
			repairValue = math.floor(repairValue / 2)
		end

		-- 移除物资
		_G.aipRemove(item)

		currentUses = math.min(totalUses, currentUses + repairValue)
		target.components.finiteuses:SetUses(currentUses)
		target.SoundEmitter:PlaySound("dontstarve/common/place_structure_wood")
		return true
	end
	return false, "INUSE"
end)
AddStategraphActionHandler("wilson", GLOBAL.ActionHandler(AIP_PATCH, "dolongaction"))
AddStategraphActionHandler("wilson_client", GLOBAL.ActionHandler(AIP_PATCH, "dolongaction"))

------------------------------------ 修理矿车行为 ------------------------------------
env.AddComponentAction("USEITEM", "fuel", function(inst, doer, target, actions, right)
	if not inst or not target then
		return
	end

	if target.components.aipc_minecar ~= nil then
		if (doer.prefab == "winona" and inst.prefab == "log") or inst.prefab == "boards" then
			table.insert(actions, GLOBAL.ACTIONS.AIP_PATCH)
		end
	end
end)

-------------------------------------- 工具方法 --------------------------------------
local function findMineCar(player)
	local x, y, z = player.Transform:GetWorldPosition()
	local mineCars = TheSim:FindEntities(x, y, z, 1.5, { "aip_minecar" })
	local mineCar = nil

	for i, target in ipairs(mineCars) do
		if target.components.aipc_minecar and target.components.aipc_minecar.driver == player then
			mineCar = target
		end
	end

	return mineCar
end

-------------------------------------- 破坏测试 --------------------------------------
env.AddComponentPostInit("workable", function(self, inst)
	local originWorkedBy = self.WorkedBy

	self.WorkedBy = function(self, ...)
		-- 阻止work
		if self.aipCanBeWorkBy then
			local workable = self.aipCanBeWorkBy(inst, ...)
			if workable == false then
				return
			end
		end
		return originWorkedBy(self, ...)
	end
end)

-------------------------------------- 键盘移动 --------------------------------------
-- local KEY_UP = 38
-- local KEY_RIGHT = 39
-- local KEY_DOWN = 40
-- local KEY_LEFT = 37

local KEY_UP = 119
local KEY_RIGHT = 100
local KEY_DOWN = 115
local KEY_LEFT = 97
local KEY_EXIT = 120

local function moveMineCar(player, rotation, exit)
	-- 如果 死了 或者 没有车 就不做操作
	if player.components.health:IsDead() or not player:HasTag("aip_minecar_driver") then
		return
	end

	local mineCar = findMineCar(player)

	-- 如果附近没有车就跳过
	if not mineCar then
		return
	end

	if mineCar.components.aipc_minecar then
		mineCar:DoTaskInTime(0, function()
			if exit then
				mineCar.components.aipc_minecar:RemoveDriver(player)
			else
				mineCar.components.aipc_minecar:GoDirect(rotation)
			end
		end)
	end
end

-------------------------------------- 按键绑定 --------------------------------------
--- Movement must in server-side, so listen for a RPC.
env.AddModRPCHandler(env.modname, "aipRunMineCar", function(player, keyCode, exit)
	moveMineCar(player, keyCode, exit)
end)

local isKeyDown = false
local function bindKey(keyCode)
	GLOBAL.TheInput:AddKeyDownHandler(keyCode, function()
		if isKeyDown then
			return
		end
		isKeyDown = true

		local player = GLOBAL.ThePlayer

		if not player then
			return
		end

		if player.HUD:IsConsoleScreenOpen() or player.HUD:IsChatInputScreenOpen() then
			return
		end

		if not player:HasTag("aip_minecar_driver") then
			return
		end

		-- 计算角度
		local screenRotation = GLOBAL.TheCamera:GetHeading() -- 指向屏幕左侧
		local rotation = -(screenRotation - 45) + 45

		if keyCode == KEY_LEFT then
			rotation = rotation
		elseif keyCode == KEY_DOWN then
			rotation = rotation - 90
		elseif keyCode == KEY_RIGHT then
			rotation = rotation + 180
		elseif keyCode == KEY_UP then
			rotation = rotation + 90
		end

		-- Server-side
		if GLOBAL.TheNet:GetIsServer() then
			moveMineCar(player, rotation, keyCode == KEY_EXIT)
	
		-- Client-side
		else
			_G.aipRPC("aipRunMineCar", rotation, keyCode == KEY_EXIT)
		end
	end)
	
	GLOBAL.TheInput:AddKeyUpHandler(keyCode, function()
		isKeyDown = false
	end)
end

bindKey(KEY_UP)
bindKey(KEY_RIGHT)
bindKey(KEY_DOWN)
bindKey(KEY_LEFT)
bindKey(KEY_EXIT)