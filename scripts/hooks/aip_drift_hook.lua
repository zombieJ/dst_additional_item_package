local _G = GLOBAL
local State = _G.State
local language = _G.aipGetModConfig("language")


local LANG_MAP = {
	english = {
		DRIFT = "Water Drift",
	},
	chinese = {
		DRIFT = "打水漂",
	},
}
local LANG = LANG_MAP[language] or LANG_MAP.english

---------------------------------------------------------------------------------
--                                   玩家动作                                   --
---------------------------------------------------------------------------------

------------------------------------- 打水漂 -------------------------------------
-- 注册动作:
local AIPC_DRIFT_ACTION = env.AddAction("AIPC_DRIFT_ACTION", LANG.DRIFT, function(act)
	local doer = act.doer
	local pos = act:GetActionPoint()
	local invobject = act.invobject

    if invobject ~= nil and doer ~= nil and invobject.components.aipc_water_drift ~= nil then
        invobject.components.aipc_water_drift:Launch(pos, doer)
    end

	return true
end)
AIPC_DRIFT_ACTION.distance = 10

AddStategraphActionHandler("wilson", _G.ActionHandler(AIPC_DRIFT_ACTION, "quicktele"))
AddStategraphActionHandler("wilson_client", _G.ActionHandler(AIPC_DRIFT_ACTION, "quicktele"))

------------------------------------ 绑定动作 ------------------------------------
-- 根据是否有车决定可上车，或者卸载轨道
env.AddComponentAction("POINT", "aipc_water_drift", function(inst, doer, pos, actions, right)
	local x, y, z = pos:Get()
	if right then -- and _G.TheWorld.Map:IsOceanAtPoint(x, y, z, false) then
		table.insert(actions, AIPC_DRIFT_ACTION)
	end
end)
