local _G = GLOBAL

local function onEyeDiff(inst)
    local seeEyes = inst.aip_see_eyes:value()
    _G.aipPrint("Changed", seeEyes)

    inst._parent.AnimState:SetClientSideBuildOverrideFlag("aip_see_eyes", seeEyes)
end

-- player_classified 在服务端每个玩家都有，而在客机只有当前玩家有
AddPrefabPostInit("player_classified", function(inst)
    inst.aip_see_eyes = _G.net_bool(inst.GUID, "aip_see_eyes", "aip_see_eyes_dirty")

    inst:ListenForEvent("aip_see_eyes_dirty", onEyeDiff)
end)