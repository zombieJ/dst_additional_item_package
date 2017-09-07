local COMMON = 3
local UNCOMMON = 1
local RARE = .5

local VEGGIES =
{
	wheat = {
		seed_weight = COMMON,

		health = 1,
		hunger = 12.5,
		sanity = 0,
		perishtime = 30,
		cooked_health = 5,
		cooked_hunger = 25,
		cooked_sanity = 0,
		cooked_perishtime = 5,
	},
	--[[onion = {
		seed_weight = COMMON,
		health = HP * 5,
		hunger = HU * 12.5,
		sanity = SAN * 0,
		perishtime = PER * 30,
		cooked_health = HP * 5,
		cooked_hunger = HU * 25,
		cooked_sanity = SAN * 5,
		cooked_perishtime = PER * 5,
	},]]
}

return VEGGIES