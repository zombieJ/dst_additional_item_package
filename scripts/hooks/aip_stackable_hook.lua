local _G = GLOBAL
local tonumber = _G.tonumber
local DEFAULT_QUALITY = 1

local function getStackSize(item)
	return item.components ~= nil and item.components.stackable ~= nil and item.components.stackable:StackSize() or 1
end

AddComponentPostInit("stackable", function(self)
	local oldPut = self.Put
	local oldIsFull = self.IsFull
	local oldGet = self.Get

	function self:Get(...)
		local num = ...
		local count = math.max(1, math.floor(tonumber(num) or 1))
		local splitQualities = nil
		local quality = self.inst.components.aipc_quality

		if quality ~= nil and self.stacksize > count then
			splitQualities = quality:TakeQualities(count)
		end

		local result = oldGet(self, ...)

		if result ~= self.inst and result ~= nil and splitQualities ~= nil then
			if result.components.aipc_quality then
				result.components.aipc_quality:SetQualities(splitQualities)
			end
		end

		return result
	end

	function self:Put(item, source_pos, ...)
		local mergeType = self.aipMergeType

		if mergeType ~= nil then
			local canMerge = false

			if type(mergeType) == "function" then
				canMerge = mergeType(self.inst, item, source_pos)
			elseif type(mergeType) == "string" then
				local otherMergeType = item.components.stackable ~= nil and item.components.stackable.aipMergeType or nil
				canMerge = otherMergeType == mergeType
			else
				canMerge = true
			end

			if not canMerge then
				self.aipIsFullLocked = true
				self.inst:DoTaskInTime(0.1, function()
					self.aipIsFullLocked = false
				end)
				return item
			end
		end

		local addedQualities = nil
		local quality = self.inst.components.aipc_quality
		local canStack = item ~= nil and item.components ~= nil and item.components.stackable ~= nil and
			item.prefab == self.inst.prefab and item.skinname == self.inst.skinname

		if quality ~= nil and canStack then
			local numberAdded = math.min(math.max(0, self.maxsize - self.stacksize), getStackSize(item))

			if numberAdded > 0 then
				if item.components.aipc_quality ~= nil then
					addedQualities = item.components.aipc_quality:TakeQualities(numberAdded)
				else
					addedQualities = { [DEFAULT_QUALITY] = numberAdded }
				end
			end
		end

		if quality ~= nil and addedQualities ~= nil then
			quality:AddQualities(addedQualities)
		end

		return oldPut(self, item, source_pos, ...)
	end

	function self:IsFull()
		if self.aipIsFullLocked then
			return true
		end
		return oldIsFull(self)
	end
end)
