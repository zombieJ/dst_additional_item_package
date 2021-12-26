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

-- 键盘角度
local function getKeyAngle(keyCode)
	if keyCode == KEY_UP then
		return 0
	elseif keyCode == KEY_RIGHT then
		return 90
	elseif keyCode == KEY_DOWN then
		return 180
	elseif keyCode == KEY_LEFT then
		return 270
	end

	return nil
end

local function driveMineCar(player, keyCode, exit)
end

--- Movement must in server-side, so listen for a RPC.
env.AddModRPCHandler(env.modname, "aipRunMineCar", function(player, keyCode, exit)
	driveMineCar(player, keyCode, exit)
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

		-- 计算角度
		local screenRotation = _G.TheCamera:GetHeading() -- 指向屏幕左侧
		_G.aipPrint("Rotate:", screenRotation)

		-- -- Server-side
		-- if GLOBAL.TheNet:GetIsServer() then
		-- 	driveMineCar(player, keyCode, keyCode == KEY_EXIT)
	
		-- -- Client-side
		-- else
		-- 	_G.aipRPC("aipRunMineCar", keyCode, keyCode == KEY_EXIT)
		-- end
	end)
end