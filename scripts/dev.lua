local dev_mode = GLOBAL.aipGetModConfig("dev_mode") == "enabled"

if not dev_mode then
	return
end

----------------- 锁定玩家 3 值 -----------------
function PlayerPrefabPostInit(inst)
    if not GLOBAL.TheWorld.ismastersim then
        return
    end

    if not inst.components.aipc_timer then
        inst:AddComponent("aipc_timer")
    end

    inst.components.aipc_timer:Interval(1, function()
        inst.components.health:DoDelta(100)
        inst.components.sanity:DoDelta(100)
        inst.components.hunger:DoDelta(100)
    end)
end

AddPlayerPostInit(PlayerPrefabPostInit)