local _G = GLOBAL

-- 每高一级品质，正面效果增加 25%，负面效果减少 25%。
local QUALITY_EFFECT_STEP = 0.25
local DEFAULT_QUALITY = 1
local RATATOUILLE_PREFAB = "ratatouille"
local SURPRISE_STEW_PREFAB = "aip_food_surprise_stew"

-- 读取物品品质，没有品质的食材视作普通品质。
local function getQuality(inst)
	return inst ~= nil and inst.components ~= nil and
		inst.components.aipc_quality ~= nil and inst.components.aipc_quality:GetVal() or DEFAULT_QUALITY
end

-- 锅制食物使用整数品质，按所有食材的平均品质四舍五入。
local function getAverageQuality(slots)
	local total = 0
	local count = 0

	for _, item in pairs(slots) do
		total = total + getQuality(item)
		count = count + 1
	end

	return count > 0 and math.floor(total / count + 0.5) or nil
end

-- 调味站继承原料理品质，不让普通香料拉低成品品质。
local function getPreparedFoodQuality(slots)
	for _, item in pairs(slots) do
		if item ~= nil and item:HasTag("preparedfood") then
			return getQuality(item)
		end
	end
end

-- 惊奇炖菜只有自身重新入锅才升品，蔬菜杂烩首做固定普通品质。
local function getSurpriseStewQuality(slots)
	local quality = nil
	local hasRatatouille = false

	for _, item in pairs(slots) do
		if item ~= nil and item.prefab == SURPRISE_STEW_PREFAB then
			quality = math.max(quality or DEFAULT_QUALITY, getQuality(item))
		elseif item ~= nil and item.prefab == RATATOUILLE_PREFAB then
			hasRatatouille = true
		end
	end

	if quality ~= nil then
		return quality + 1
	end

	return hasRatatouille and DEFAULT_QUALITY or nil
end

-- 给料理成品补上品质展示与品质组件。
local function setupQuality(inst)
	if inst.components.aipc_info_client == nil then
		inst:AddComponent("aipc_info_client")
	end

	if inst.components.aipc_quality == nil then
		inst:AddComponent("aipc_quality")
	end
end

-- 料理锅成品需要能承载食材平均品质。
AddPrefabPostInitAny(function(inst)
	if inst:HasTag("preparedfood") then
		setupQuality(inst)
	end
end)

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

AddComponentPostInit("stewer", function(self)
	local oldStartCooking = self.StartCooking
	local oldStopCooking = self.StopCooking
	local oldOnSave = self.OnSave
	local oldOnLoad = self.OnLoad
	local oldHarvest = self.Harvest

	-- 开始烹饪前记录食材平均品质，避免锅具销毁内容后丢失。
	function self:StartCooking(doer, ...)
		local quality = nil
		local surpriseStewQuality = nil

		if self.targettime == nil and self.inst.components.container ~= nil then
			local slots = self.inst.components.container.slots
			quality = self.inst:HasTag("spicer") and getPreparedFoodQuality(slots) or getAverageQuality(slots)
			surpriseStewQuality = getSurpriseStewQuality(slots)
		end

		local result = oldStartCooking(self, doer, ...)

		-- 惊奇炖菜每次重新入锅时优先使用自身的升品规则。
		if self.product == SURPRISE_STEW_PREFAB and surpriseStewQuality ~= nil then
			quality = surpriseStewQuality
		end

		if quality ~= nil and self.product ~= nil and self.targettime ~= nil then
			self.aip_product_quality = quality
		end

		return result
	end

	function self:OnSave(...)
		local data = oldOnSave(self, ...)
		if data ~= nil and self.aip_product_quality ~= nil then
			data.aip_product_quality = self.aip_product_quality
		end
		return data
	end

	function self:OnLoad(data, ...)
		oldOnLoad(self, data, ...)
		self.aip_product_quality = data ~= nil and data.aip_product_quality or nil
	end

	-- 在成品生成瞬间写入品质，后续食用效果沿用 edible 的品质倍率。
	local function withQualitySpawn(fn, ...)
		local product = self.product
		local quality = self.aip_product_quality

		if product == nil or quality == nil then
			return fn(self, ...)
		end

		local oldSpawnPrefab = _G.SpawnPrefab
		_G.SpawnPrefab = function(name, ...)
			local inst = oldSpawnPrefab(name, ...)

			if name == product and inst ~= nil and inst:HasTag("preparedfood") then
				setupQuality(inst)
				inst.components.aipc_quality:SetVal(quality)
			end

			return inst
		end

		local ok, result = _G.pcall(fn, self, ...)
		_G.SpawnPrefab = oldSpawnPrefab

		if not ok then
			_G.error(result)
		end

		return result
	end

	function self:StopCooking(reason, ...)
		local result = withQualitySpawn(oldStopCooking, reason, ...)
		self.aip_product_quality = nil
		return result
	end

	function self:Harvest(harvester, ...)
		local result = withQualitySpawn(oldHarvest, harvester, ...)
		if self.product == nil then
			self.aip_product_quality = nil
		end
		return result
	end
end)
