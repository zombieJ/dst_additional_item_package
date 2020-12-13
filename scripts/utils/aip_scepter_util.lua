local ILN = Ingredient("aip_leaf_note", 1, "images/inventoryimages/aip_leaf_note.xml")
local IL = Ingredient("log", 1)

local inscriptions = {
	-- Element 元素
	aip_dou_fire_inscription =		{ tag = "FIRE",		recipes = { ILN, IL, Ingredient("redgem", 1) } },
	aip_dou_ice_inscription =		{ tag = "ICE",		recipes = { ILN, IL, Ingredient("bluegem", 1) } },
	aip_dou_sand_inscription =		{ tag = "SAND",		recipes = { ILN, IL, Ingredient("townportaltalisman", 1) } },
	aip_dou_heal_inscription =		{ tag = "HEAL",		recipes = { ILN, IL, Ingredient("butterflywings", 1) } },
	aip_dou_dawn_inscription =		{ tag = "DAWN",		recipes = { ILN, IL, Ingredient("nightmarefuel", 1) } },
	aip_dou_cost_inscription =		{ tag = "COST",		recipes = { ILN, IL, Ingredient("reviver", 1) } },

	-- Inscription 铭文
	aip_dou_follow_inscription =	{ tag = "FOLLOW",	recipes = { ILN, IL, Ingredient("feather_canary", 1) } },
	aip_dou_through_inscription =	{ tag = "THROUGH",	recipes = { ILN, IL, Ingredient("feather_robin_winter", 1) } },
	aip_dou_area_inscription =		{ tag = "AREA",		recipes = { ILN, IL, Ingredient("feather_robin", 1) } },

	-- Enchant 附魔
	aip_dou_split_inscription =		{ tag = "SPLIT",	recipes = { ILN, IL, Ingredient("steelwool", 1) } },
	aip_dou_rock_inscription =		{ tag = "ROCK",		recipes = { ILN, IL, Ingredient("walrus_tusk", 1) } },
}

local categories = {
	FIRE = "element",
	ICE = "element",
	SAND = "element",
	HEAL = "element",
	DAWN = "element",
	COST = "element",
	ROCK = "guard",
	FOLLOW = "action",
	THROUGH = "action",
	AREA = "action",
	SPLIT = "split", -- 分裂是特殊的
}

local damages = {
	FIRE = 12, -- 火焰有燃烧效果，只给予少量伤害
	ICE = 18, -- 冰冻能冰冻敌人，但是没有附加伤害
	SAND = 5, -- 沙子本身是地形影响，减少伤害量
	HEAL = 25, -- 治疗比较特殊，但是叠加的时候算伤害
	DAWN = 10, -- 对暗影怪造成额外伤害，所以本身不高
	COST = 15, -- 痛作为最后元素时则会额外造成伤害，但是如果攻击的目标没有死则反弹 10% 伤害
	ROCK = 24, -- 岩石伤害高，如果用的是环切没有打到目标，会召唤元素图腾
	PLANT = 5, -- 植物会用树苗包围目标
	FOLLOW = 0.01, -- 跟随比较简单，不提供额外伤害
	THROUGH = 15, -- 穿透比较难，增加的多一点
	AREA = 5, -- 范围伤害很多单位
	SPLIT = 0.01, -- 分裂很 IMBA
}

local defaultColor = { 0.6, 0.6, 0.6, 0.1 }

local colors = {
	FIRE = { 1, 0.8, 0, 1 },
	ICE = { 0.6, 0.7, 0.8, 1 },
	SAND = { 0.8, 0.7, 0.5, 1 },
	DAWN = { 0, 0, 0, 0.5 },
	COST = { 0.2, 0.14, 0.14, 1 },
	ROCK = { 0.6, 0.6, 0.6, 1 },
	HEAL = { 0.4, 0.7, 0.4, 0.5 },
	PLANT = { 0, 0.6, 0.1, 0.5 },

	_default = defaultColor,
}

local function getType(item)
	local type = categories[item._douTag]
	return { name = item._douTag, type = type }
end

local function createGroup(prevGrp)
	local prev = prevGrp or {}

	return {
		-- 施法行为
		action = nil,
		-- 元素类型
		element = prev.element or nil,
		-- 元素叠加数量
		elementCount = 0,
		-- 伤害，继承前一个伤害的 75%
		damage = math.max((prev.damage or 0) * 0.75, 5),
		-- 颜色
		color = prev.color or defaultColor,
		-- 分裂
		split = 0,
		-- 岩石守卫
		guard = 0,
		-- 痛
		cost = 0,
	}
end

function calculateProjectile(items)
	local projectileInfo = {
		action = nil,
		uses = 1,
		queue = {},
	}

	--[[
		规则：一个施法动作为一组，遍历时直到遇到一个施法动作为止。
		施法动作：line(default) - 直线, throw - 抛物区域, trough - 直线穿透, follow - 追踪
	]]

	local flattenItems = aipFlattenTable(items)

	if #flattenItems == 0 then
		projectileInfo.queue = { createGroup() }
	else
		local group = nil
		local prevGroup = nil

		for i, item in pairs(flattenItems) do
			if group == nil then
				group = createGroup(prevGroup)
			end

			if item ~= nil then
				local typeInfo = getType(item)
				local slotDamage = damages[typeInfo.name] or 5

				------------------------- 元素 -------------------------
				if typeInfo.type == "element" then
					-- 元素类型
					if group.element ~= typeInfo.name then
						group.elementCount = 0
					end

					group.element = typeInfo.name
					group.elementCount = group.elementCount + 1
					group.damage = group.damage + slotDamage
					group.color = colors[typeInfo.name] or defaultColor

					-- 元素消耗 1 点
					projectileInfo.uses = projectileInfo.uses + 1

				------------------------- 守卫 -------------------------
				elseif typeInfo.type == "guard" then
					group.guard = group.guard + 1
					group.damage = group.damage + slotDamage

					-- 元素消耗 1 点
					projectileInfo.uses = projectileInfo.uses + 1

				------------------------- 附魔 -------------------------
				elseif typeInfo.type == "split" then
					group.split = group.split + 1
					group.damage = group.damage + slotDamage

					-- 元素消耗 1 点
					projectileInfo.uses = projectileInfo.uses + 1

				------------------------- 铭文 -------------------------
				elseif typeInfo.type == "action" then
					-- 施法动作
					group.action = typeInfo.name
					group.damage = group.damage + slotDamage

					table.insert(projectileInfo.queue, group)
					prevGroup = group
					group = nil

					-- 动作消耗 2 点
					projectileInfo.uses = projectileInfo.uses + 2
				end
			end
		end

		-- 如果有剩余，添加进去
		if group ~= nil then
			table.insert(projectileInfo.queue, group)
		end
	end

	-- 填充默认类型
	projectileInfo.action = projectileInfo.queue[1].action or "LINE"

	-- 根据元素叠加额外造成效果（哈哈，原来这是个 bug）
	for i, task in ipairs(projectileInfo.queue) do
		if task.elementCount >= 1 then
			task.damage = task.damage * math.pow(1.25, task.elementCount - 1)
		end
	end

	return projectileInfo
end

return {
	calculateProjectile = calculateProjectile,
	inscriptions = inscriptions,
	colors = colors,
}