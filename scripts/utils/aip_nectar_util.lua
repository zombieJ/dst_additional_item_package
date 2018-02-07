local cooking = require("cooking")

local function extends(origin, target)
	for k, v in pair(target) do
		origin[k] = v
	end

	return origin
end

local function getNectarValues(item)
	local values = {}

	if not item then
		return values
	end

	----------------------------- 标签属性 -----------------------------
	if item:HasTag("aip_nectar_material") then
		-- 标签
		if item:HasTag("frozen") then
			values.frozen = 2
		end
		if item:HasTag("honeyed") then
			values.sweetener = 2
		end
		if item:HasTag("aip_exquisite") then
			values.exquisite = 1
		end
		if item:HasTag("aip_nectar") then
			values.nectar = 1

			-- 花蜜属性可以继承
			for nectarTag, nectarTagVal in pairs (item.nectarValues or {}) do
				local cloneTagVal = nectarTagVal

				if nectarTag == "exquisite" then
					-- 精酿无法继承
					cloneTagVal = 0

				elseif nectarTag == "frozen" then
					-- 冰镇效果递减
					cloneTagVal = math.ceil(nectarTagVal / 2)
				end
				values[nectarTag] = (values[nectarTag] or 0) + cloneTagVal
			end
		end
	end

	----------------------------- 特殊物品 -----------------------------
	local prefab = item.prefab

	-- 荧光珠
	if prefab == "lightbulb" then
		values.light = 1

	-- 光莓
	elseif prefab == "wormlight" then
		values.light = 2

	-- 较弱的光莓
	elseif prefab == "wormlight_lesser" then
		values.light = 1

	-- 大便
	elseif prefab == "poop" or prefab == "guano" then
		values.terrible = 2

	-- 腐烂物
	elseif prefab == "spoiled_food" or prefab == "ash" or prefab == "beardhair" then
		values.terrible = 1

	-- 食人花种子
	elseif prefab == "lureplantbulb" then
		values.vampire = 1

	-- 蜂刺
	elseif prefab == "stinger" then
		values.damage = 1

	-- 蜘蛛卵
	elseif prefab == "spidereggsack" or prefab == "walrus_tusk" then
		values.damage = 2
	end

	----------------------------- 素材价值 -----------------------------
	local ingredient = cooking.ingredients[prefab]
	if ingredient and ingredient.tags then
		-- 素材价值
		if ingredient.tags.fruit or ingredient.tags.sweetener or ingredient.tags.frozen then
			values = extends(values, ingredient.tags)
		end
	end

	return values
end

return getNectarValues