local categories = {
	FIRE = "element",
	ICE = "element",
	SAND = "element",
	HEAL = "element",
	FOLLOW = "action",
	THROUGH = "action",
	AREA = "action",
}

local damages = {
	FIRE = 5, -- 火焰有燃烧效果，只给予少量伤害
	ICE = 20, -- 冰冻能冰冻敌人，但是没有附加伤害
	SAND = 10, -- 沙子本身是地形影响，减少伤害量
	HEAL = 25, -- 治疗比较特殊，但是叠加的时候算伤害
	PLANT = 5, -- 植物会用树苗包围目标
}

local function getType(item)
	local type = categories[item._douTag]
	return { name = item._douTag, type = type }
end

local function createGroup()
	return {
		action = nil,
		element = nil,
		elementCount = 0,
		damage = 5,
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

		for i, item in pairs(items) do
			if group == nil then
				group = createGroup()
			end

			if item ~= nil then
				local typeInfo = getType(item)
				if typeInfo.type == "element" then
					-- 元素类型
					if group.element ~= typeInfo.name then
						group.elementCount = 0
					end
					
					group.element = typeInfo.name
					group.elementCount = group.elementCount + 1
					group.damage = group.damage + (damages[typeInfo.name] or 5)

					-- 元素消耗 1 点
					projectileInfo.uses = projectileInfo.uses + 1

				elseif typeInfo.type == "action" then
					-- 施法动作
					group.action = typeInfo.name
					table.insert(projectileInfo.queue, group)
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