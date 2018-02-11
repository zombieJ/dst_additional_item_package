---------------------------------------- 搬运者 ----------------------------------------
local AIP_PACKAGER = env.AddAction("AIP_PACKAGER", "Package", function(act)
	-- Client Only Code
	local doer = act.doer
	local target = act.target
	local item = act.invobject

	-- 检查目标是否可以搬运
	if false then
		return false, "INUSE"
	end

	if item.components.aipc_action then
		item.components.aipc_action:DoTargetAction(doer, target)
		return true
	end

	return false, "INUSE"
end)
AddStategraphActionHandler("wilson", GLOBAL.ActionHandler(AIP_PACKAGER, "doshortaction"))
AddStategraphActionHandler("wilson_client", GLOBAL.ActionHandler(AIP_PACKAGER, "doshortaction"))

--------------------------------------- 绑定搬运 ---------------------------------------
env.AddComponentAction("USEITEM", "aipc_info_client", function(inst, doer, target, actions, right)
	-- 检查目标是否可以搬运
	if false then
		-- target
		return
	end

	-- 检查是否可驾驶
	table.insert(actions, GLOBAL.ACTIONS.AIP_PACKAGER)
end)
