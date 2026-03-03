local _G = GLOBAL

-- 硬直劫持
AddStategraphPostInit("wilson", function(sg)
    local originAttackedFn = sg.events.attacked.fn

    sg.events.attacked = _G.EventHandler('attacked', function(inst, data, ...)
        if -- 暗影生物打不出硬直
			inst.replica.inventory:EquipHasTag("aip_no_shadow_stun") and
			data.attacker and
			(_G.aipIsShadowCreature(data.attacker) or data.attacker:HasTag("ghost"))
		then
            if not inst.sg:HasStateTag('frozen') and not inst.sg:HasStateTag('sleeping') then
                return
            end
        end

        return originAttackedFn(inst, data, ...)
    end)
end)