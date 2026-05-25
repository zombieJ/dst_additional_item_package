local _G = GLOBAL

-- 每高一级品质，正面效果增加 25%，负面效果减少 25%。
local QUALITY_EFFECT_STEP = 0.25
local DEFAULT_QUALITY = 1
local POST_INIT_QUALITY_FOODS = {}

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

-- 给料理成品补上品质展示与品质组件。
local function setupQuality(inst)
	if inst.components.aipc_info_client == nil then
		inst:AddComponent("aipc_info_client")
	end

	if inst.components.aipc_quality == nil then
		inst:AddComponent("aipc_quality")
	end
end

-- 有品质的料理只和同品质合堆，避免食用时品质被混掉。
local function patchQualityStackableComponent(inst)
	local stackable = inst.components.stackable

	if stackable == nil or stackable._aip_quality_stackable_patched then
		return
	end
	stackable._aip_quality_stackable_patched = true

	local oldMergeType = stackable.aipMergeType
	stackable.aipMergeType = function(this, other, source_pos)
		if oldMergeType ~= nil then
			if type(oldMergeType) == "function" then
				if not oldMergeType(this, other, source_pos) then
					return false
				end
			elseif type(oldMergeType) == "string" then
				local otherMergeType = other.components.stackable ~= nil and other.components.stackable.aipMergeType or nil
				if otherMergeType ~= oldMergeType then
					return false
				end
			end
		end

		return getQuality(this) == getQuality(other)
	end
end

-- 有品质的料理只和同品质合堆，避免食用时品质被混掉。
local function patchQualityStackable(inst)
	if inst._aip_quality_stackable_fn_patched then
		patchQualityStackableComponent(inst)
		return
	end
	inst._aip_quality_stackable_fn_patched = true

	local oldCanStackWithFn = inst.stackable_CanStackWithFn
	inst.stackable_CanStackWithFn = function(this, other)
		if oldCanStackWithFn ~= nil and not oldCanStackWithFn(this, other) then
			return false
		end

		return getQuality(this) == getQuality(other)
	end

	patchQualityStackableComponent(inst)
end

-- 料理锅成品需要能承载食材平均品质。
local function setupPreparedFoodQuality(inst)
	if inst:HasTag("preparedfood") then
		setupQuality(inst)
		patchQualityStackable(inst)
	end
end

-- 精确注册原版料理 prefab，避免每个 prefab 生成时都跑全局 Any hook。
local function addPreparedFoodPostInit(name)
	if name ~= nil and not POST_INIT_QUALITY_FOODS[name] then
		POST_INIT_QUALITY_FOODS[name] = true
		AddPrefabPostInit(name, setupPreparedFoodQuality)
	end
end

local function addPreparedFoodPostInits(moduleName)
	local ok, foods = pcall(_G.require, moduleName)
	if not ok or foods == nil then
		return
	end

	for name, data in pairs(foods) do
		addPreparedFoodPostInit(data.name or name)
	end
end

addPreparedFoodPostInits("preparedfoods")
addPreparedFoodPostInits("preparedfoods_warly")
addPreparedFoodPostInits("spicedfoods")

_G.aipRegisterQualityPreparedFood = addPreparedFoodPostInit

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

	-- 服务端添加 edible 时再次兜底，兼容其它已带 preparedfood 标签的料理。
	setupPreparedFoodQuality(self.inst)

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

AddComponentPostInit("stackable", function(self)
	if self.inst:HasTag("preparedfood") and self.inst.components.aipc_quality ~= nil then
		patchQualityStackable(self.inst)
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
		if self.targettime == nil and self.inst.components.container ~= nil then
			quality = getAverageQuality(self.inst.components.container.slots)
		end

		local result = oldStartCooking(self, doer, ...)

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

		local ok, result = pcall(fn, self, ...)
		_G.SpawnPrefab = oldSpawnPrefab

		if not ok then
			error(result)
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
