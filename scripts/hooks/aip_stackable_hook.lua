local _G = GLOBAL

AddComponentPostInit("stackable", function(self)
	local oldPut = self.Put
	local oldIsFull = self.IsFull
	local oldGet = self.Get

	function self:Get(...)
		local result = oldGet(self, ...)
		if result and self.inst and self.inst.components.aipc_quality then
			local sourceQuality = self.inst.components.aipc_quality:GetVal()
			if result.components.aipc_quality then
				result.components.aipc_quality:SetVal(sourceQuality)
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

		return oldPut(self, item, source_pos, ...)
	end

	function self:IsFull()
		if self.aipIsFullLocked then
			return true
		end
		return oldIsFull(self)
	end
end)
