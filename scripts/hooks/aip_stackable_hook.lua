local _G = GLOBAL
local dev_mode = _G.aipGetModConfig("dev_mode") == "enabled"

AddComponentPostInit("stackable", function(self)
	local oldPut = self.Put
	local oldIsFull = self.IsFull

	function self:Put(item, source_pos, ...)
		local mergeType = self.aipMergeType

		_G.aipTypePrint("mergeType", self.inst, mergeType)

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

		return oldPut(self, item, source_pos, ...)
	end

	function self:IsFull()
		if self.aipIsFullLocked then
			return true
		end
		return oldIsFull(self)
	end
end)
