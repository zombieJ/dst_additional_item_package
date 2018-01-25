---------------------------------------- 驾驶 ----------------------------------------
local AIP_DRIVE = env.AddAction("AIP_DRIVE", "Drive", function(act)
	local doer = act.doer
	local target = act.target

	-- 驾驶吧
	if target.components.aipc_minecar ~= nil and target.components.aipc_minecar.driver == nil then
		target.components.aipc_minecar:AddDriver(doer)
		return true
	end
	return false, "INUSE"
end)
AddStategraphActionHandler("wilson", GLOBAL.ActionHandler(AIP_DRIVE, "doshortaction"))
AddStategraphActionHandler("wilson_client", GLOBAL.ActionHandler(AIP_DRIVE, "doshortaction"))

-------------------------------------- 停止驾驶 --------------------------------------
local AIP_UNDRIVE = env.AddAction("AIP_UNDRIVE", "Stop Drive", function(act)
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
env.AddComponentAction("SCENE", "aipc_minecar", function(inst, doer, actions, right)
	-- 检查是否是驾驶设备
	if inst.components.aipc_minecar == nil then
		return
	end

	-- 检查是否可驾驶
	if inst.components.aipc_minecar.driver == nil and not doer:HasTag("aip_minecar_driver") then
		table.insert(actions, GLOBAL.ACTIONS.AIP_DRIVE)
		return
	end

	-- 检查是否可停止驾驶
	if inst.components.aipc_minecar.driver == doer then
		table.insert(actions, GLOBAL.ACTIONS.AIP_UNDRIVE)
		return
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

local function moveMineCar(player, keyCode)
	-- 如果 死了 或者 没有车 就不做操作
	if player.components.health:IsDead() or not player:HasTag("aip_minecar_driver") then
		return
	end

	local x, y, z = player.Transform:GetWorldPosition()
	local mineCars = TheSim:FindEntities(x, y, z, 1.5, { "aip_minecar" })
	local mineCar = nil

	for i, target in ipairs(mineCars) do
		if target.components.aipc_minecar and target.components.aipc_minecar.driver == player then
			mineCar = target
		end
	end

	-- 如果附近没有车就跳过
	if not mineCar then
		return
	end

	-- Key to Direct
	local direct = nil
	if keyCode == KEY_UP then
		direct = "up"
	elseif keyCode == KEY_RIGHT then
		direct = "right"
	elseif keyCode == KEY_DOWN then
		direct = "down"
	elseif keyCode == KEY_LEFT then
		direct = "left"
	end

	if mineCar.components.aipc_minecar then
		-- 延迟一段时间以免玩家按键阻止位移
		mineCar:DoTaskInTime(0.5, function()
			mineCar.components.aipc_minecar:GoDirect(direct)
		end)
	end
end

-------------------------------------- 按键绑定 --------------------------------------
--- Movement must in server-side, so listen for a RPC.
env.AddModRPCHandler(env.modname, "aipRunMineCar", function(player, keyCode)
	moveMineCar(player, keyCode)
end)

local function bindKey(keyCode)
	GLOBAL.TheInput:AddKeyUpHandler(keyCode, function()
		local player = GLOBAL.ThePlayer

		-- print(">>> Dir:"..tostring(keyCode))
		if not player then
			return
		end

		if player.HUD:IsConsoleScreenOpen() or player.HUD:IsChatInputScreenOpen() then
			return
		end

		if player.components.health:IsDead() or not player:HasTag("aip_minecar_driver") then
			return
		end

		-- Server-side
		if GLOBAL.TheNet:GetIsServer() then
			moveMineCar(player, keyCode)
	
		-- Client-side
		else
			SendModRPCToServer(MOD_RPC[modname]["aipRunMineCar"], keyCode)
		end
	end)
end

bindKey(KEY_UP)
bindKey(KEY_RIGHT)
bindKey(KEY_DOWN)
bindKey(KEY_LEFT)