-- 添加服务端和客户端通讯的代码，用于简化调用逻辑。
-- 可以用此调用客户端的函数，或者服务端的函数。

local _G = GLOBAL

-- local scFunctions = {}

---------------------------------- 添加通知 ----------------------------------
-- player_classified 在服务端每个玩家都有，而在客机只有当前玩家有
AddPrefabPostInit("player_classified", function(inst)
	-- inst.aip_s2c_funs = scFunctions
	-- inst.aip_s2c_call = _G.net_string(inst.GUID, "aip_s2c_call", "aip_s2c_call_dirty")

	-- -- 服务端 调用 客户端
	-- inst.aipServerCallClient = function(funcName)
	-- 	inst.aip_s2c_call:set(
	-- 		_G.aipJoin({
	-- 			tostring(_G.os.time()), funcName
	-- 		}, "|")
	-- 	)
	-- end

	-- -- 根据事件打开窗口
	-- inst:ListenForEvent("aip_s2c_call_dirty", function()
	-- 	local cells = _G.aipSplit(inst.aip_s2c_call:value(), "|")
	-- 	local funcName = cells[2]

	-- 	-- 如果不是当前玩家的实例，直接返回
	-- 	if not _G.ThePlayer or _G.ThePlayer.player_classified ~= inst then
	-- 		return
	-- 	end

	-- 	if scFunctions[funcName] then
	-- 		scFunctions[funcName](_G.ThePlayer)
	-- 	end
	-- end)


end)

---------------------------------- 事件列表 ----------------------------------
-- -- 飞鞋函数，飞到目的地去
-- scFunctions.travelBoots = function(player)
-- 	player.components.playercontroller:PullUpMap(mergedTarget, _G.ACTIONS.AIPC_MAP_USE)
-- end
