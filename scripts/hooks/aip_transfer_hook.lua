local _G = GLOBAL
local language = _G.aipGetModConfig("language")

local LANG_MAP = {
	english = {
		MARK = "Mark",
		LAY = "Transfer",
	},
	chinese = {
		MARK = "标记",
		LAY = "放置",
	},
}
local LANG = LANG_MAP[language] or LANG_MAP.english

---------------------------------------------------------------------------------
--                                   玩家动作                                   --
---------------------------------------------------------------------------------

------------------------------------ 卸载轨道 ------------------------------------
-- 注册动作
local AIPC_TRANSFER_MARK_ACTION = env.AddAction("AIPC_TRANSFER_MARK_ACTION", LANG.MARK, function(act)
	local doer = act.doer
	local target = act.target
	local item = act.invobject

	if item ~= nil and target ~= nil and item.components.aipc_shadow_transfer ~= nil then
		item.components.aipc_shadow_transfer:Mark(target)
	end

	return true
end)

AddStategraphActionHandler("wilson", _G.ActionHandler(AIPC_TRANSFER_MARK_ACTION, "doshortaction"))
AddStategraphActionHandler("wilson_client", _G.ActionHandler(AIPC_TRANSFER_MARK_ACTION, "doshortaction"))

------------------------------------ 绑定动作 ------------------------------------
-- 对建筑打包
env.AddComponentAction("USEITEM", "aipc_shadow_transfer", function(inst, doer, target, actions, right)
	if not inst or not target then
		return
	end

	if inst.components.aipc_shadow_transfer:CanMark(target) then
		table.insert(actions, _G.ACTIONS.AIPC_TRANSFER_MARK_ACTION)
	end
end)
