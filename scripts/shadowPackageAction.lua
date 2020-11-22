GLOBAL.require("recipe")

--local PlayerHud = GLOBAL.require("screens/playerhud")
--local ConfigWidget = GLOBAL.require("widgets/aipConfigWidget")

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

----------------------------------------- 注入 -----------------------------------------
-- 2018-07-22 不知道这段代码干什么用的了，先全部注释了
--[[function PlayerHud:ShowAIPAutoConfigWidget(inst, config)
	self.aipAutoConfigScreen = ConfigWidget(self.owner, inst, config)
	self:OpenScreenUnderPause(self.aipAutoConfigScreen)
	return self.aipAutoConfigScreen
	[if writeable == nil then
		return
	else
		self.writeablescreen = WriteableWidget(self.owner, writeable, config)
		self:OpenScreenUnderPause(self.writeablescreen)
		if TheFrontEnd:GetActiveScreen() == self.writeablescreen then
			-- Have to set editing AFTER pushscreen finishes.
			self.writeablescreen.edit_text:SetEditing(true)
		end
		return self.writeablescreen
	end]
end

function PlayerHud:CloseAIPAutoConfigWidget()
	if self.aipAutoConfigScreen then
		self.aipAutoConfigScreen:Close()
		self.aipAutoConfigScreen = nil
	end
end]]

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

	if old_HAMMER then
		return old_HAMMER(act, ...)
	end

	return false, "INUSE"
end

---------------------------------------- 搬运者 ----------------------------------------
--rmb=true
local AIP_PACKAGER = env.AddAction("AIP_PACKAGER", "Package", function(act, ...)
	return GLOBAL.ACTIONS.HAMMER.fn(act, ...)
	--[[-- Client Only Code
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

	return false, "INUSE"]]
end)
AIP_PACKAGER.rmb = true
AIP_PACKAGER.priority = 10
AIP_PACKAGER.mount_valid = true

AddStategraphActionHandler("wilson", GLOBAL.ActionHandler(AIP_PACKAGER, "doshortaction"))
AddStategraphActionHandler("wilson_client", GLOBAL.ActionHandler(AIP_PACKAGER, "doshortaction"))

--------------------------------------- 绑定搬运 ---------------------------------------
env.AddComponentAction("USEITEM", "aipc_info_client", function(inst, doer, target, actions, right)
	-- 检查目标是否可以搬运
	if not canPackage(target) then
		return
	end

	if inst:HasTag("aip_package") then
		table.insert(actions, GLOBAL.ACTIONS.AIP_PACKAGER)
	end
end)
