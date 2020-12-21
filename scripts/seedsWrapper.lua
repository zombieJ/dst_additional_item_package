-- 食物
local additional_food = GLOBAL.aipGetModConfig("additional_food")
if additional_food ~= "open" then
	return nil
end

-- 开发模式
local dev_mode = GLOBAL.aipGetModConfig("dev_mode") == "enabled"


-- 概率
local PROBABILITY = dev_mode and 1 or 0.15

local veggiesList = GLOBAL.require('prefabs/aip_veggies_list')
local VEGGIES = veggiesList.VEGGIES
local VEGGIE_DEFS = veggiesList.VEGGIE_DEFS

-- 添加其他种子概率
function mergePickProduct(oriFunc, probability)
	return function(inst)
		-- 产生自定义的新物品
		if math.random() < probability then
			local total_w = 0
			for veggiename,v in pairs(VEGGIES) do
				total_w = total_w + (v.seed_weight or 1)
			end

			local rnd = math.random()*total_w
			for veggiename,v in pairs(VEGGIES) do
				rnd = rnd - (v.seed_weight or 1)
				if rnd <= 0 then
					return "aip_"..veggiename
				end
			end
		end

		-- 产生原本的物品
		return oriFunc(inst)
	end
end

-- 更多的蔬菜种子
AddPrefabPostInit("seeds", function(inst)
	if not GLOBAL.TheWorld.ismastersim then
		return
	end

	-- 添加概率钩子
	if inst.components.plantable then
		local originPickProduct = inst.components.plantable.product
		inst.components.plantable.product = mergePickProduct(originPickProduct, PROBABILITY)
	end
end)

-- 给蔬菜赋值
for name, data in pairs(VEGGIES) do
	env.AddIngredientValues({"aip_"..name}, data.tags or {}, data.cancook or false, data.candry or false)
end

------------------------------------------------- 新版农场 -------------------------------------------------
if GROUND.FARMING_SOIL ~= nil then
	-- 添加作物
	AddSimPostInit(function()
		if GLOBAL.VEGGIES ~= nil then
			for name, data in pairs(VEGGIES) do
				GLOBAL.VEGGIES[name] = data

				if dev_mode then
					data.seed_weight = 999999999
				end
			end
		end
	end)

	-- 注入作物
	local PLANT_DEFS = require("prefabs/farm_plant_defs").PLANT_DEFS
	for name, data in pairs(VEGGIE_DEFS) do
		PLANT_DEFS[name] = data
	end

end