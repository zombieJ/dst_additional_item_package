local language = GLOBAL.aipGetModConfig("language")

----------------------------------- 通用组件行为 -----------------------------------
local LANG_MAP = {
	english = {
		GIVE = "Give",
	},
	chinese = {
		GIVE = "给予",
	},
}
local LANG = LANG_MAP[language] or LANG_MAP.english

-- 注册一个 action
local AIPC_ACTION = env.AddAction("AIPC_ACTION", LANG.GIVE, function(act)
	local doer = act.doer
	local item = act.invobject
	local target = act.target

	if item.components.aipc_action ~= nil then
		item.components.aipc_action:DoTargetAction(doer, target)
		return true
	end

	return false, "INUSE"
end)
AddStategraphActionHandler("wilson", GLOBAL.ActionHandler(AIPC_ACTION, "dolongaction"))
AddStategraphActionHandler("wilson_client", GLOBAL.ActionHandler(AIPC_ACTION, "dolongaction"))

-- 为组件绑定 action
env.AddComponentAction("USEITEM", "aipc_action", function(inst, doer, target, actions, right)
	if not inst or not target then
		return
	end

	if inst.components.aipc_action:CanActOn(target, doer) then
		table.insert(actions, GLOBAL.ACTIONS.AIPC_ACTION)
	end
end)

------------------------------------ 贪婪观察者 ------------------------------------
-- 暗影跟随者
function ShadowFollowerPrefabPostInit(inst)
	if not GLOBAL.TheWorld.ismastersim then
		return
	end

	if not inst.components.shadow_follower then
		inst:AddComponent("shadow_follower")
	end
end

AddPrefabPostInit("dragonfly", function(inst) ShadowFollowerPrefabPostInit(inst) end) -- 龙蝇
AddPrefabPostInit("deerclops", function(inst) ShadowFollowerPrefabPostInit(inst) end) -- 鹿角怪
AddPrefabPostInit("bearger", function(inst) ShadowFollowerPrefabPostInit(inst) end) -- 熊獾
AddPrefabPostInit("moose", function(inst) ShadowFollowerPrefabPostInit(inst) end) -- 麋鹿鹅
AddPrefabPostInit("beequeen", function(inst) ShadowFollowerPrefabPostInit(inst) end) -- 蜂后
AddPrefabPostInit("klaus", function(inst) ShadowFollowerPrefabPostInit(inst) end) -- 克劳斯
AddPrefabPostInit("klaus_sack", function(inst) ShadowFollowerPrefabPostInit(inst) end) -- 克劳斯袋子
AddPrefabPostInit("antlion", function(inst) ShadowFollowerPrefabPostInit(inst) end) -- 蚁狮
AddPrefabPostInit("toadstool", function(inst) ShadowFollowerPrefabPostInit(inst) end) -- 蟾蜍王
AddPrefabPostInit("toadstool_dark", function(inst) ShadowFollowerPrefabPostInit(inst) end) -- 苦难蟾蜍王

-- ------------------------------------- 豆酱权杖 -------------------------------------
-- GLOBAL.LOCKTYPE.AIP_DOU_OPAL = "aip_dou_opal"

-- AddPrefabPostInit("cane", function(inst)
-- 	if not GLOBAL.TheWorld.ismastersim then
-- 		return
-- 	end

-- 	-- 添加额外的组件
-- 	inst:AddComponent("aipc_action")
-- end)