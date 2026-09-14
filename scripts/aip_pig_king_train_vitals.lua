local Vitals = {}

-- 安装只作用于本乘客的临时方法包装，解除时不会覆盖其他模组后装的包装。
local function Wrap(lock, component, method, wrapper)
	local original = component[method]
	if original == nil then return end
	local fn = function(self, ...)
		if not lock.active or lock.allowDeath then return original(self, ...) end
		return wrapper(original, self, ...)
	end
	component[method] = fn
	table.insert(lock.methods, { component = component, method = method, original = original, fn = fn })
end

-- 为各个数值入口安装最低值保护，保留原版的变化事件及治疗效果。
local function Install(lock, inst)
	for _, name in ipairs({ "health", "hunger", "sanity" }) do
		local component = inst.components[name]
		local field = name == "health" and "currenthealth" or "current"
		if component ~= nil and type(component[field]) == "number" then
			local value = math.max(1, component[field])
			if name == "health" then
				component:SetCurrentHealth(value)
			elseif name == "hunger" then
				component:SetCurrent(value)
			else
				component:DoDelta(value - component.current)
			end
			lock.values[name] = { component = component, field = field }
			-- 生命和饥饿的百分比及增减入口最终调用数值 setter，在此统一保底。
			if name == "health" then
				for _, method in ipairs({ "SetVal", "SetCurrentHealth" }) do
					Wrap(lock, component, method, function(original, self, amount, ...)
						return original(self, math.max(1, amount), ...)
					end)
				end
			elseif name == "hunger" then
				Wrap(lock, component, "SetCurrent", function(original, self, amount, ...)
					return original(self, math.max(1, amount), ...)
				end)
			else
				Wrap(lock, component, "DoDelta", function(original, self, delta, ...)
					return original(self, math.max(delta, 1 - self.current), ...)
				end)
			end
		end
	end
	local health = inst.components.health
	if health ~= nil then
		-- 显式 Kill/ForceKill 仍走原版死亡，不能把实际死亡的玩家当作在乘车而复活。
		for _, method in ipairs({ "Kill", "ForceKill" }) do
			Wrap(lock, health, method, function(original, self, ...)
				lock.allowDeath = true
				local ok, result = pcall(original, self, ...)
				lock.allowDeath = false
				if not ok then error(result) end
				return result
			end)
		end
	end
	return lock
end

-- 乘车时三维正常增减，仅在归零前保留 1 点，治疗和恢复不受影响。
function Vitals.Lock(inst)
	local lock = { active = true, methods = {}, values = {}, inst = inst }
	-- 任意组件在安装期间报错，也必须撤销已经安装的包装，防止保护永久残留。
	local ok, err = pcall(Install, lock, inst)
	if not ok then
		Vitals.Release(lock)
		error(err)
	end
	return lock
end

-- 修正绕过方法直接写入的数值；生命已实际归零时尊重死亡而不恢复生命。
function Vitals.Maintain(lock)
	if lock == nil or not lock.active then return end
	local health = lock.inst.components.health
	if health ~= nil and health:IsDead() then return end
	for name, entry in pairs(lock.values) do
		if entry.component[entry.field] < 1 then
			if name == "health" then entry.component:SetCurrentHealth(1)
			elseif name == "hunger" then entry.component:SetCurrent(1)
			else entry.component:DoDelta(1 - entry.component.current) end
		end
	end
end

-- 只解除本次锁定，不补满三维、不撤销乘客原有的无敌或其他保护。
function Vitals.Release(lock)
	if lock == nil or not lock.active then return end
	lock.active = false
	for _, entry in ipairs(lock.methods) do
		if entry.component[entry.method] == entry.fn then entry.component[entry.method] = entry.original end
	end
end

return Vitals
