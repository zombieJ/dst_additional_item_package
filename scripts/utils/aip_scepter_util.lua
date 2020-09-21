local categories = {
	FIRE = "element",
	ICE = "element",
	SAND = "element",
	HEAL = "element",
	FOLLOW = "action",
	THROUGH = "action",
	AREA = "action",
	SPLIT = "split", -- 分裂是特殊的
}

local damages = {
	FIRE = 5, -- 火焰有燃烧效果，只给予少量伤害
	ICE = 20, -- 冰冻能冰冻敌人，但是没有附加伤害
	SAND = 10, -- 沙子本身是地形影响，减少伤害量
	HEAL = 25, -- 治疗比较特殊，但是叠加的时候算伤害
	PLANT = 5, -- 植物会用树苗包围目标
	SPLIT = 0.01, -- 分裂很 IMBA
}

local defaultColor = { 0.6, 0.6, 0.6, 0.1 }

local colors = {
	FIRE = { 1, 0.8, 0, 1 },
	ICE = { 0.2, 0.4, 1, 1 },
	SAND = { 1, 0.8, 0.1, 1 },
	HEAL = { 0, 0.6, 0.1, 0.5 },
	PLANT = { 0, 0.6, 0.1, 0.5 },
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
		-- 伤害
		damage = prev.damage or 5,
		-- 颜色
		color = prev.color or defaultColor,
		-- 分裂
		split = 0,
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

	if #items == 0 then
		projectileInfo.queue = { createGroup() }
	else
		local group = nil
		local prevGroup = nil

		for i, item in pairs(items) do
			if group == nil then
				group = createGroup(prevGroup)
			end

			if item ~= nil then
				local typeInfo = getType(item)
				local damage = group.damage + (damages[typeInfo.name] or 5)

				if typeInfo.type == "element" then
					-- 元素类型
					if group.element ~= typeInfo.name then
						group.elementCount = 0
					end
					
					group.element = typeInfo.name
					group.elementCount = group.elementCount + 1
					group.damage = group.damage + damage
					group.color = colors[typeInfo.name] or defaultColor

					-- 元素消耗 1 点
					projectileInfo.uses = projectileInfo.uses + 1

				elseif typeInfo.type == "split" then
					group.split = group.split + 1
					group.damage = group.damage + damage

				elseif typeInfo.type == "action" then
					-- 施法动作
					group.action = typeInfo.name
					group.damage = group.damage + damage

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

	return projectileInfo
end

return calculateProjectile