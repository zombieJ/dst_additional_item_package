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

    -- 开发模式下移除失眠效果
    inst:RemoveTag("insomniac")

    inst.components.aipc_timer:Interval(1, function()
        if inst.components.health.currenthealth < 50 then
            inst.components.health:DoDelta(50)
        end
        if inst.components.sanity.current < 30 then
            inst.components.sanity:DoDelta(30)
        end
    end)
end

AddPlayerPostInit(PlayerPrefabPostInit)