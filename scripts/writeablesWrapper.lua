local _G = GLOBAL
local writeables = _G.require "writeables"

local kinds = {}

local layout = {
    prompt = _G.STRINGS.SIGNS.MENU.PROMPT,
    animbank = "ui_board_5x3",
    animbuild = "ui_board_5x3",
    menuoffset = _G.Vector3(6, -70, 0),

    cancelbtn = { text = _G.STRINGS.SIGNS.MENU.CANCEL, cb = nil, control = _G.CONTROL_CANCEL },
    acceptbtn = { text = _G.STRINGS.SIGNS.MENU.ACCEPT, cb = nil, control = _G.CONTROL_ACCEPT },
}

writeables.AddLayout("aip_fly_totem", layout)
writeables.AddLayout("aip_fake_fly_totem", layout)
writeables.AddLayout("aip_pet_rabbit", layout)