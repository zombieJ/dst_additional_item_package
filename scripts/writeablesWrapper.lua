local _G = GLOBAL
local writeables = _G.require "writeables"

local kinds = {}

kinds["aip_fly_totem"] = {
    prompt = _G.STRINGS.SIGNS.MENU.PROMPT,
    animbank = "ui_board_5x3",
    animbuild = "ui_board_5x3",
    menuoffset = _G.Vector3(6, -70, 0),

    cancelbtn = { text = _G.STRINGS.SIGNS.MENU.CANCEL, cb = nil, control = _G.CONTROL_CANCEL },
    acceptbtn = { text = _G.STRINGS.SIGNS.MENU.ACCEPT, cb = nil, control = _G.CONTROL_ACCEPT },
}

local originMakescreen = writeables.makescreen

writeables.makescreen = function(inst, doer, ...)
	local data = kinds[inst.prefab]
	if doer and doer.HUD and data then
		return doer.HUD:ShowWriteableWidget(inst, data)
	end

	return originMakescreen(inst, doer, _G.unpack(arg))
end