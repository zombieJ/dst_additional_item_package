local _G = GLOBAL
local State = _G.State

AddStategraphState("wilson", State {
    name = "aip_drive",
    tags = {"doing", "busy",},
    onenter = function(inst)
        _G.aipPrint("SG!!!")
        inst.components.locomotor:Stop()
		inst.AnimState:PlayAnimation("aip_drive", true)
        inst.AnimState:OverrideSymbol("minecar_down_front", "aip_glass_minecar", "swap_aip_minecar_down_front")
        inst.AnimState:OverrideSymbol("minecar_side", "aip_glass_minecar", "swap_aip_minecar_side")
        inst.AnimState:OverrideSymbol("minecar_up_front", "aip_glass_minecar", "swap_aip_minecar_up_front")
        inst.AnimState:OverrideSymbol("minecar_up_end", "aip_glass_minecar", "swap_aip_minecar_up_end")
    end,
    timeline = {},
    events = {}
})


AddStategraphState("wilson_client", State {
    name = "aip_drive",
    tags = {"doing", "busy",},
    onenter = function(inst)
        -- inst.components.locomotor:Stop()
		-- inst.AnimState:PlayAnimation("aip_drive", true)
        -- inst.AnimState:Show("ARM_carry")
        -- inst.AnimState:Hide("ARM_carry")
        -- inst.AnimState:Hide("ARM_normal")
        -- inst.AnimState:OverrideSymbol("minecar_front", "aip_fish_sword_swap", "aip_fish_sword_swap")
    end,
    timeline = {},
    events = {}
})