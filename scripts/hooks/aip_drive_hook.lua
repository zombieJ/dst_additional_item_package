local _G = GLOBAL
local State = _G.State

AddStategraphState("wilson", State {
    name = "aip_drive",
    tags = {"doing", "busy",},
    onenter = function(inst)
        _G.aipPrint("SG!!!")
        inst.components.locomotor:Stop()
		inst.AnimState:PlayAnimation("aip_drive", true)
        inst.AnimState:Show("ARM_carry")
        inst.AnimState:Hide("ARM_carry")
        inst.AnimState:Hide("ARM_normal")
        inst.AnimState:OverrideSymbol("minecar_front", "aip_fish_sword_swap", "aip_fish_sword_swap")
    end,
    timeline = {},
    events = {}
})


AddStategraphState("wilson_client", State {
    name = "aip_drive",
    tags = {"doing", "busy",},
    onenter = function(inst)
        inst.components.locomotor:Stop()
		inst.AnimState:PlayAnimation("aip_drive", true)
        inst.AnimState:Show("ARM_carry")
        inst.AnimState:Hide("ARM_carry")
        inst.AnimState:Hide("ARM_normal")
        inst.AnimState:OverrideSymbol("minecar_front", "aip_fish_sword_swap", "aip_fish_sword_swap")
    end,
    timeline = {},
    events = {}
})