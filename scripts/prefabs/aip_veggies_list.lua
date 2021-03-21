local COMMON = 3
local UNCOMMON = 1
local RARE = .5

--             c_give"aip_veggie_sunflower"

local function onSunflowerDeploy(inst, pt, deployer)
	inst = inst.components.stackable:Get()

	local tgt = SpawnPrefab("aip_sunflower")
	tgt.Transform:SetPosition(pt.x, pt.y, pt.z)
end

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

		tags = { starch = 1 },
		cancook = true,
		candry = false,
		hasSeed = false,
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

		tags = { starch = 1 },
		cancook = true,
		candry = false,
		hasSeed = false,

		post = function(inst)
			inst:AddComponent("deployable")
			inst.components.deployable:SetDeployMode(DEPLOYMODE.PLANT)
			inst.components.deployable.ondeploy = onSunflowerDeploy
		end
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
		hasSeed = false,
	},
}

return VEGGIES