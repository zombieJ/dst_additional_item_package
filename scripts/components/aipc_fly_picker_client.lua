local function OnPickerTrigger(inst)
	local msg = inst.components.aipc_fly_picker_client.trigger:value()
	local cells = aipSplit(msg, "|")

	if ThePlayer and tostring(TheNet:GetUserID()) == cells[1] and ThePlayer.HUD then
		ThePlayer.HUD:OpenAIPDestination(inst)
	end
end

local FlyPicker = Class(function(self, inst)
	self.inst = inst

	-- 全局通讯开启者
	self.trigger = net_string(inst.GUID, "aipc_fly_picker", "aipc_fly_picker_dirty")
	inst:ListenForEvent("aipc_fly_picker_dirty", OnPickerTrigger)

	-- 更新全局列表
	if TheWorld.ismastersim then
		-- 添加
		table.insert(TheWorld.components.world_common_store.flyTotems, inst)

		-- 移除
		inst:ListenForEvent("onremove", function()
			aipTableRemove(TheWorld.components.world_common_store.flyTotems, inst)
		end)
	end
end)

function FlyPicker:ShowPicker(doer)
	-- 加一个时间戳以便于玩家反复打开时强制触发
	self.trigger:set(doer.userid.."|"..os.time())
end

return FlyPicker