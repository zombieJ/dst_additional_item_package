-- TODO: Change back when prod
-- TODO: 把mod优先级调低
local PROBABILITY = 1

require('prefabs/aip_veggies.lua')

-- 添加其他种子概率
function mergePickProduct(oriFunc, probability)
	return function(inst)
		-- 产生自定义的新物品
		if math.random() < probability then
			local total_w = 0
			for k,v in pairs(VEGGIES) do
				total_w = total_w + (v.seed_weight or 1)
			end

			local rnd = math.random()*total_w
			for k,v in pairs(VEGGIES) do
				rnd = rnd - (v.seed_weight or 1)
				if rnd <= 0 then
					return k
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