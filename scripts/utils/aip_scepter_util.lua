local categories = {
	FIRE = "element",
	ICE = "element",
	FOLLOW = "action",
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
		queue = {},
	}

	--[[
		规则：一个施法动作为一组，遍历时直到遇到一个施法动作为止。
		施法动作：line(default) - 直线, area - 抛物区域, trough - 直线穿透, follow - 追踪
	]]

	if #items == 0 then
		projectileInfo.queue = { createGroup() }
		return projectileInfo
	end

	local group = nil

	for i, item in pairs(items) do
		if group == nil then
			group = createGroup()
		end

		local typeInfo = getType(item)
		if typeInfo.type == "element" then
			-- 元素类型
			group.element = typeInfo.name
		elseif typeInfo.type == "action" then
			-- 施法动作
			group.action = typeInfo.action
			table.insert(projectileInfo.queue, group)
			group = nil
		end
	end

	-- 如果有剩余，添加进去
	if group ~= nil then
		table.insert(projectileInfo.queue, group)
	end

	return projectileInfo
end

return calculateProjectile