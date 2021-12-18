local _G = GLOBAL
local State = _G.State

AddStategraphState("wilson", State {
    name = "aip_drive",
    tags = {"doing", "busy",},
    onenter = function(inst)
        _G.aipPrint("SG!!!")
        inst.components.locomotor:Stop()
		inst.AnimState:PlayAnimation("aip_drive", true)
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
    end,
    timeline = {},
    events = {}
})