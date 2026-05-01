-- 每高一级品质，正面效果增加 25%，负面效果减少 25%。
local QUALITY_EFFECT_STEP = 0.25

-- 有品质才加成；正数变强，负数变弱，普通品质不变。
local function applyQualityBonus(value, edible)
	if value == nil or value == 0 then
		return value
	end

	local quality = edible.inst.components.aipc_quality
	if quality == nil then
		return value
	end

	local bonus = math.max(0, quality:GetVal() - 1) * QUALITY_EFFECT_STEP
	if value > 0 then
		return value * (1 + bonus)
	end

	-- 高品质也会削弱负面效果。
	return value * math.max(0, 1 - bonus)
end

AddComponentPostInit("edible", function(self)
	local oldGetHealth = self.GetHealth
	local oldGetHunger = self.GetHunger
	local oldGetSanity = self.GetSanity

	function self:GetHealth(eater, ...)
		-- 生命先处理铁胃，再处理品质倍率。
		local health = oldGetHealth(self, eater, ...)

		if health < 0 and eater ~= nil and eater.components.aipc_pet_owner ~= nil then
			local skillInfo = eater.components.aipc_pet_owner:GetSkillInfo("taster")
			if skillInfo ~= nil then
				return 0
			end
		end

		return applyQualityBonus(health, self)
	end

	function self:GetHunger(eater, ...)
		return applyQualityBonus(oldGetHunger(self, eater, ...), self)
	end

	function self:GetSanity(eater, ...)
		return applyQualityBonus(oldGetSanity(self, eater, ...), self)
	end
end)

AddComponentPostInit("cookable", function(self)
	local oldCook = self.Cook

	function self:Cook(cooker, chef, ...)
		-- 生蔬果烤熟后，熟食继承原来的品质。
		local product = oldCook(self, cooker, chef, ...)
		local quality = self.inst.components.aipc_quality

		if product ~= nil and quality ~= nil and product.components.aipc_quality ~= nil then
			product.components.aipc_quality:SetVal(quality:GetVal())
		end

		return product
	end
end)
