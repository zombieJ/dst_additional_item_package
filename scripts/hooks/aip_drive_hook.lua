local _G = GLOBAL
local State = _G.State
local language = _G.aipGetModConfig("language")


local LANG_MAP = {
	english = {
		DRIVE = "Drive",
	},
	chinese = {
		DRIVE = "驾驶",
	},
}
local LANG = LANG_MAP[language] or LANG_MAP.english

---------------------------------------------------------------------------------
--                                   玩家动作                                   --
---------------------------------------------------------------------------------

------------------------------------ 坐上矿车 ------------------------------------
-- 注册动作
local AIPC_MINECAR_DRIVE_ACTION = env.AddAction("AIPC_MINECAR_DRIVE_ACTION", LANG.DRIVE, function(act)
	local doer = act.doer
	local item = act.invobject	-- INVENTORY
	local target = act.target	-- SCENE

    if target ~= nil and target.components.aipc_orbit_point ~= nil then
        target.components.aipc_orbit_point:Drive(doer)
    end

	return true
end)
AIPC_MINECAR_DRIVE_ACTION.priority = 99

AddStategraphActionHandler("wilson", _G.ActionHandler(AIPC_MINECAR_DRIVE_ACTION, "doshortaction"))
AddStategraphActionHandler("wilson_client", _G.ActionHandler(AIPC_MINECAR_DRIVE_ACTION, "doshortaction"))

-- 根据是否有车决定可上车
env.AddComponentAction("SCENE", "aipc_orbit_point", function(inst, doer, actions, right)
	if not inst or not right then
		return
	end

	if inst.components.aipc_orbit_point:CanDrive() then
		table.insert(actions, GLOBAL.ACTIONS.AIPC_MINECAR_DRIVE_ACTION)
	end
end)

---------------------------------------------------------------------------------
--                                   开车状态                                   --
---------------------------------------------------------------------------------
AddStategraphState("wilson", State {
    name = "aip_drive",
    tags = {"doing", "busy",},
    onenter = function(inst)
        inst.components.locomotor:Stop()
		inst.AnimState:PlayAnimation("aip_drive", true)
        inst.AnimState:OverrideSymbol("minecar_down_front", "aip_glass_minecar", "swap_aip_minecar_down_front")
        inst.AnimState:OverrideSymbol("minecar_down_end", "aip_glass_minecar", "swap_aip_minecar_down_end")
        inst.AnimState:OverrideSymbol("minecar_side_front", "aip_glass_minecar", "swap_aip_minecar_side_front")
        inst.AnimState:OverrideSymbol("minecar_side_end", "aip_glass_minecar", "swap_aip_minecar_side_end")
        inst.AnimState:OverrideSymbol("minecar_up_front", "aip_glass_minecar", "swap_aip_minecar_up_front")
        inst.AnimState:OverrideSymbol("minecar_up_end", "aip_glass_minecar", "swap_aip_minecar_up_end")
    end,
    timeline = {},
    events = {}
})

---------------------------------------------------------------------------------
--                                   键盘操作                                   --
---------------------------------------------------------------------------------
local KEY_UP = 119
local KEY_RIGHT = 100
local KEY_DOWN = 115
local KEY_LEFT = 97
local KEY_EXIT = 120

local keys = { KEY_UP, KEY_RIGHT, KEY_DOWN, KEY_LEFT, KEY_EXIT }

-- 获取控制方向
local function GetWorldControllerVector()
    local xdir = _G.TheInput:GetAnalogControlValue(_G.CONTROL_MOVE_RIGHT) - _G.TheInput:GetAnalogControlValue(_G.CONTROL_MOVE_LEFT)
    local ydir = _G.TheInput:GetAnalogControlValue(_G.CONTROL_MOVE_UP) - _G.TheInput:GetAnalogControlValue(_G.CONTROL_MOVE_DOWN)
    local deadzone = .3
    if math.abs(xdir) >= deadzone or math.abs(ydir) >= deadzone then
        local dir = _G.TheCamera:GetRightVec() * xdir - _G.TheCamera:GetDownVec() * ydir
        return dir:GetNormalized()
    end

	return nil
end

local function driveMineCar(player, x, z, exit)
	if player ~= nil and player.components.aipc_orbit_driver ~= nil then
		player.components.aipc_orbit_driver:DriveTo(x, z, exit)
	end
end

--- Movement must in server-side, so listen for a RPC.
env.AddModRPCHandler(env.modname, "driveMineCar", function(player, x, z, exit)
	driveMineCar(player, x, z, exit)
end)



-- 遍历键盘操作
for i, keyCode in ipairs(keys) do
	_G.TheInput:AddKeyDownHandler(keyCode, function()
		local player = _G.ThePlayer

		if
			not player
			or player.HUD:IsConsoleScreenOpen()
			or player.HUD:IsChatInputScreenOpen()
			-- or not player:HasTag("aip_orbit_driver")
		then
			return
		end

		-- 计算方向
		local dir = GetWorldControllerVector()
		local x = 0
		local y = 0
		if dir then
			x = dir.x
			z = dir.z
		end

		-- 发送方向数据给服务器
		_G.aipRPC("driveMineCar", x, z, keyCode == KEY_EXIT)
	end)
end

---------------------------------------------------------------------------------
--                                   司机组件                                   --
---------------------------------------------------------------------------------
AddPlayerPostInit(function(player)
	if not _G.TheWorld.ismastersim then
		return
	end
	
	if not player.components.aipc_orbit_driver then
		player:AddComponent("aipc_orbit_driver")
	end
end)