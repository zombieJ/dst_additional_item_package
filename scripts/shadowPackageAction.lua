GLOBAL.require("recipe")

local function canPackage(inst)
	if not inst then
		return false
	end

	-- 只有建筑可以被搬运
	if not inst:HasTag("structure") then
		return false
	end

	-- 只有玩家可以建造的可以搬走
	if not GLOBAL.IsRecipeValid(inst.prefab) then
		return false
	end

	return true
end

---------------------------------------- 搬运者 ----------------------------------------
local old_HAMMER = GLOBAL.ACTIONS.HAMMER.fn

-- 复用锤子操作来支持防熊锁mod
GLOBAL.ACTIONS.HAMMER.fn = function(act, ...)
	local doer = act.doer
	local target = act.target
	local item = act.invobject

	if item and item:HasTag("aip_proxy_action") and item.components.aipc_action then
		-- 检查目标是否可以搬运
		if not canPackage(target) then
			return false, "INUSE"
		end

		-- 做动作
		if item.components.aipc_action then
			item.components.aipc_action:DoTargetAction(doer, target)
			return true
		end

		return false, "INUSE"
	end

	return old_HAMMER(act, ...)
end

---------------------------------------- 搬运者 ----------------------------------------
--[[local AIP_PACKAGER = env.AddAction("AIP_PACKAGER", "Package", function(act)
	-- Client Only Code
	local doer = act.doer
	local target = act.target
	local item = act.invobject

	-- 检查目标是否可以搬运
	if not canPackage(target, doer) then
		return false, "INUSE"
	end

	if item.components.aipc_action then
		item.components.aipc_action:DoTargetAction(doer, target)
		return true
	end

	return false, "INUSE"
end)
AddStategraphActionHandler("wilson", GLOBAL.ActionHandler(AIP_PACKAGER, "doshortaction"))
AddStategraphActionHandler("wilson_client", GLOBAL.ActionHandler(AIP_PACKAGER, "doshortaction"))]]

--------------------------------------- 绑定搬运 ---------------------------------------
env.AddComponentAction("USEITEM", "aipc_info_client", function(inst, doer, target, actions, right)
	-- 检查目标是否可以搬运
	if not canPackage(target) then
		return
	end

	-- 检查是否可驾驶
	table.insert(actions, GLOBAL.ACTIONS.HAMMER)
end)
