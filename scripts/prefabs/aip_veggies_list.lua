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

		tags = { starch = 1, veggie=.1 },
		cancook = true,
		candry = false,
	},
	sunflower = {
		seed_weight = COMMON,

		health = 1,
		hunger = 0,
		sanity = 5,
		perishtime = TUNING.PERISH_FAST,
		cooked_health = 1,
		cooked_hunger = 5,
		cooked_sanity = 5,
		cooked_perishtime = TUNING.PERISH_MED,

		tags = { starch = 1, veggie=.1 },
		cancook = true,
		candry = false,
	},
	grape = {
		seed_weight = COMMON,

		health = 5,
		hunger = 10,
		sanity = 0,
		perishtime = TUNING.PERISH_FAST,
		cooked_health = 10,
		cooked_hunger = 15,
		cooked_sanity = 0,
		cooked_perishtime = TUNING.PERISH_FAST,

		tags = { fruit = 1 },
		cancook = true,
		candry = false,
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