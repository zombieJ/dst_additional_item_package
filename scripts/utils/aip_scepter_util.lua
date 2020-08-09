local categories = {
	FIRE = "element",
	ICE = "element",
	FOLLOW = "action",
	THROUGH = "action",
	AREA = "action",
}

local function getType(item)
	local type = categories[item._douTag]
	return { name = item._douTag, type = type }
end

local function createGroup()
	return {
		action = nil,
		element = nil,
		damage = 5,
	}
end

function calculateProjectile(items)
	local projectileInfo = {
		action = nil,
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
					group.element = typeInfo.name

				elseif typeInfo.type == "action" then
					-- 施法动作
					group.action = typeInfo.name
					table.insert(projectileInfo.queue, group)
					group = nil
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