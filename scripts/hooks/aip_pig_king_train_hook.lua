-- 既有矿车组件先完成注册，观光组件再按玩家实例接入驾驶和镜头。
AddPlayerPostInit(function(inst)
	inst:AddComponent("aipc_pig_king_train_passenger")
end)

-- 记录眼骨被拿走的事实，落地或重载后也不再把它当作原始出生景点。
AddPrefabPostInit("chester_eyebone", function(inst)
	if not GLOBAL.TheWorld.ismastersim then return end
	inst:ListenForEvent("onputininventory", function() inst._aip_train_moved = true end)
	local originalSave, originalLoad = inst.OnSave, inst.OnLoad
	inst.OnSave = function(eye, data, ...)
		data.aip_train_moved = eye._aip_train_moved or nil
		if originalSave ~= nil then return originalSave(eye, data, ...) end
	end
	inst.OnLoad = function(eye, data, ...)
		eye._aip_train_moved = data ~= nil and data.aip_train_moved or nil
		if originalLoad ~= nil then return originalLoad(eye, data, ...) end
	end
end)
