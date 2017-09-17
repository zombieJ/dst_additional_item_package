-- 体验关闭
local additional_experiment = GetModConfigData("additional_experiment", foldername)
if additional_experiment ~= "open" then
	return nil
end

-- 食物
local additional_food = GetModConfigData("additional_food", foldername)
if additional_food ~= "open" then
	return nil
end

-- 开发模式
local dev_mode = GetModConfigData("dev_mode", foldername) == "enabled"


-- 概率
local PROBABILITY = dev_mode and 1 or 0.1

local VEGGIES = GLOBAL.require('prefabs/aip_veggies_list')

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
					return "aip_veggie_"..veggiename
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
	env.AddIngredientValues({"aip_veggie_"..name}, data.tags or {}, data.cancook or false, data.candry or false)
end
