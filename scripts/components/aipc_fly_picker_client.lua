local function SyncFlyTotems()
	if TheWorld.aip_sync_fly_task ~= nil then
		TheWorld.aip_sync_fly_task:Cancel()
		TheWorld.aip_sync_fly_task = nil
	end

	-- 总是延迟 1 秒同步，以防止过多图腾不断占用网络
	TheWorld:DoTaskInTime(1, function()
		local totemNames = {}
		for i, totem in ipairs(TheWorld.components.world_common_store.flyTotems) do
			local text = totem.components.writeable:GetText()
			table.insert(totemNames, text or STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_FLY_TOTEM_UNNAMED)
		end

		if TheWorld.components.aip_world_common_store_client ~= nil then
			TheWorld.components.aip_world_common_store_client:UpdateTotems(totemNames)
		end
	end)
end

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
		SyncFlyTotems()

		-- 移除
		inst:ListenForEvent("onremove", function()
			aipTableRemove(TheWorld.components.world_common_store.flyTotems, inst)
			SyncFlyTotems()
		end)

		-- 更新
		inst:DoTaskInTime(0.1, function()
			if inst.components.writeable ~= nil then
				inst.components.writeable.onAipEndWriting = SyncFlyTotems
			end
		end)
	end
end)

function FlyPicker:ShowPicker(doer)
	-- 加一个时间戳以便于玩家反复打开时强制触发
	self.trigger:set(doer.userid.."|"..os.time())
end

return FlyPicker