local _G = GLOBAL

---------------------------------- 添加飞行器 ----------------------------------
AddPlayerPostInit(function(inst)
	if not inst.components.aipc_flyer_sc then
		inst:AddComponent("aipc_flyer_sc")
	end
end)

----------------------------------- 添加动作 -----------------------------------
-- 服务端组件
local function flyToTotem(player, index)
	if player.components.aipc_flyer == nil then
		local totem = _G.TheWorld.components.world_common_store.flyTotems[index]

		player.components.aipc_flyer_sc:FlyTo(totem)
	end
end

env.AddModRPCHandler(env.modname, "aipFlyToTotem", function(player, index)
	flyToTotem(player, index)
end)

-- 添加飞行动作
local AIPC_FLY_ACTION = env.AddAction("AIPC_FLY_ACTION", _G.STRINGS.ACTIONS.AIP_USE, function(act)
	local doer = act.doer
	local target = act.target

	if target and target.components.aipc_fly_picker_client ~= nil then
		target.components.aipc_fly_picker_client:ShowPicker(doer)
	end

	return true
end)

AddStategraphActionHandler("wilson", _G.ActionHandler(AIPC_FLY_ACTION, "doshortaction"))
AddStategraphActionHandler("wilson_client", _G.ActionHandler(AIPC_FLY_ACTION, "doshortaction"))

-- 未飞行选择器
env.AddComponentAction("SCENE", "aipc_fly_picker_client", function(inst, doer, actions, right)
	if not inst or not right then
		return
	end

	table.insert(actions, _G.ACTIONS.AIPC_FLY_ACTION)
end)

----------------------------------- 添加动作 -----------------------------------
-- 监听玩家状态
local function AddPlayerSgPostInit(fn)
    AddStategraphPostInit('wilson', fn)
    AddStategraphPostInit('wilson_client', fn)
end

AddPlayerSgPostInit(function(self)
end)