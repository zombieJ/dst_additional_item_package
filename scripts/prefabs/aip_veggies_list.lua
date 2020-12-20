local COMMON = 3
local UNCOMMON = 1
local RARE = .5

--[[
	未使用属性： halloweenmoonmutable_settings, secondary_foodtype, lure_data
]]

-- 作物列表
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
		dryable = false,
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
		dryable = false,
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
		dryable = false,
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

-- 作物生长动画
local VEGGIE_DEFS = {}

local function makeVeggieDef(name, drink_rate, good_seasons)
	local prefab = "aip_farm_plant_"..name
	local product = "aip_"..name

	-- 生成生长时间
	local function MakeGrowTimes(germination_min, germination_max, full_grow_min, full_grow_max)
		local grow_time = {}
	
		-- germination time
		grow_time.seed		= {germination_min, germination_max}
	
		-- grow time
		grow_time.sprout	= {full_grow_min * 0.5, full_grow_max * 0.5}
		grow_time.small		= {full_grow_min * 0.3, full_grow_max * 0.3}
		grow_time.med		= {full_grow_min * 0.2, full_grow_max * 0.2}
	
		-- harvestable perish time
		grow_time.full		= 4 * TUNING.TOTAL_DAY_TIME
		grow_time.oversized	= 6 * TUNING.TOTAL_DAY_TIME
		grow_time.regrow	= {4 * TUNING.TOTAL_DAY_TIME, 5 * TUNING.TOTAL_DAY_TIME} -- min, max
	
		return grow_time
	end

	-- 填充数据
	local data = {
		prefab = prefab, -- 植物
		product = product, -- 产物
		product_oversized = product.."_oversized", -- 巨大化产物
		seed = product.."_seeds",
		build = "aip_farm_plant_"..name,
		bank = "aip_farm_plant_"..name,
		grow_time = MakeGrowTimes(12 * TUNING.SEG_TIME, 16 * TUNING.SEG_TIME, 4 * TUNING.TOTAL_DAY_TIME, 7 * TUNING.TOTAL_DAY_TIME),
		moisture = {drink_rate = drink_rate, min_percent = TUNING.FARM_PLANT_DROUGHT_TOLERANCE}, -- 潮湿度
		good_seasons = good_seasons, -- 喜爱季节
		nutrient_consumption = nutrient_consumption, -- 肥料需求
		max_killjoys_tolerance	= TUNING.FARM_PLANT_KILLJOY_TOLERANCE,
		fireproof = false, -- 不防火
		weight_data = { 372.82, 465.65, .26 } -- 巨大化重量
		sounds = PLANT_DEFS.pumpkin.sounds -- 默认声效
		plant_type_tag = prefab,
		family_min_count = TUNING.FARM_PLANT_SAME_FAMILY_MIN,
		family_check_dist = TUNING.FARM_PLANT_SAME_FAMILY_RADIUS,
		stage_netvar = net_tinybyte, -- 植物状态，7 个，byte 足矣

		-- 官方图鉴
		plantregistrywidget = "widgets/redux/farmplantpage",
		plantregistrysummarywidget = "widgets/redux/farmplantsummarywidget",
		pictureframeanim = {anim = "emoteXL_happycheer", time = 0.5}

		-- 状态与动效
		plantregistryinfo = {
			{
				text = "seed",
				anim = "crop_seed",
				grow_anim = "grow_seed",
				learnseed = true,
				growing = true,
			},
			{
				text = "sprout",
				anim = "crop_sprout",
				grow_anim = "grow_sprout",
				growing = true,
			},
			{
				text = "small",
				anim = "crop_small",
				grow_anim = "grow_small",
				growing = true,
			},
			{
				text = "medium",
				anim = "crop_med",
				grow_anim = "grow_med",
				growing = true,
			},
			{
				text = "grown",
				anim = "crop_full",
				grow_anim = "grow_full",
				revealplantname = true,
				fullgrown = true,
			},
			{
				text = "oversized",
				anim = "crop_oversized",
				grow_anim = "grow_oversized",
				revealplantname = true,
				fullgrown = true,
				hidden = true,
			},
			{
				text = "rotting",
				anim = "crop_rot",
				grow_anim = "grow_rot",
				stagepriority = -100,
				is_rotten = true,
				hidden = true,
			},
			{
				text = "oversized_rotting",
				anim = "crop_rot_oversized",
				grow_anim = "grow_rot_oversized",
				stagepriority = -100,
				is_rotten = true,
				hidden = true,
			},
		}
	}

	-- 提供的肥料度（游戏默认逻辑取反）
	data.nutrient_restoration = {}
	for i = 1, #data.nutrient_consumption do
		data.nutrient_restoration[i] = data.nutrient_consumption[i] == 0 or nil
	end

	-- 巨型腐烂物
	data.loot_oversized_rot = {"spoiled_food", "spoiled_food", "spoiled_food", data.seed, "fruitfly", "fruitfly"}

	VEGGIE_DEFS[name] = data
end

return {
	VEGGIES = VEGGIES,
	VEGGIE_DEFS = VEGGIE_DEFS,
}