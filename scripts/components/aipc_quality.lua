local petConfig = require("configurations/aip_pet")
local QUALITY_LANG = petConfig.QUALITY_LANG
local QUALITY_COLORS = petConfig.QUALITY_COLORS
local language = aipGetModConfig("language")

local QUALITY_MIN = 1
local QUALITY_MAX = 5
local DEFAULT_QUALITY = 1
local MIXED_SUFFIX = language == "chinese" and "等" or "+"

local function clampQuality(q)
	q = tonumber(q) or DEFAULT_QUALITY
	return math.min(QUALITY_MAX, math.max(QUALITY_MIN, math.floor(q)))
end

local function getStackSize(inst)
	return inst.components.stackable ~= nil and inst.components.stackable:StackSize() or 1
end

local function readCounts(data)
	local counts = {}

	if type(data) ~= "table" then
		return counts
	end

	for quality, count in pairs(data) do
		if type(count) == "table" then
			quality = count.quality
			count = count.count
		end

		quality = clampQuality(quality)
		count = math.floor(tonumber(count) or 0)

		if count > 0 then
			counts[quality] = (counts[quality] or 0) + count
		end
	end

	return counts
end

local function writeCounts(counts)
	local data = {}

	for quality = QUALITY_MIN, QUALITY_MAX do
		local count = counts[quality] or 0
		if count > 0 then
			table.insert(data, {
				quality = quality,
				count = count,
			})
		end
	end

	return data
end

local function getCountsTotal(counts)
	local total = 0

	for quality = QUALITY_MIN, QUALITY_MAX do
		total = total + (counts[quality] or 0)
	end

	return total
end

local function getTopQuality(counts)
	for quality = QUALITY_MAX, QUALITY_MIN, -1 do
		if (counts[quality] or 0) > 0 then
			return quality
		end
	end

	return DEFAULT_QUALITY
end

local function isMixedCounts(counts)
	local kindCount = 0

	for quality = QUALITY_MIN, QUALITY_MAX do
		if (counts[quality] or 0) > 0 then
			kindCount = kindCount + 1
		end
	end

	return kindCount > 1
end

local function takeCounts(counts, count)
	local taken = {}
	local left = math.max(0, math.floor(count or 0))

	for quality = QUALITY_MAX, QUALITY_MIN, -1 do
		local qualityCount = counts[quality] or 0
		local takeCount = math.min(qualityCount, left)

		if takeCount > 0 then
			taken[quality] = takeCount
			counts[quality] = qualityCount - takeCount
			left = left - takeCount
		end

		if left <= 0 then
			break
		end
	end

	return taken
end

local Quality = Class(function(self, inst)
	self.inst = inst
	self.quality = DEFAULT_QUALITY
	self.qualities = { [DEFAULT_QUALITY] = 1 }
	self:InitNetKeys()
	self.inst:ListenForEvent("stacksizechange", function(inst, data)
		self:SyncStackSize(data ~= nil and data.stacksize or nil)
	end)
	self:syncToClient()
end)

function Quality:InitNetKeys()
	if self.inst.components.aipc_info_client then
		self.inst.components.aipc_info_client:SetUInt("aip_quality", nil, true)
		self.inst.components.aipc_info_client:SetString("aip_info", nil, true)
		self.inst.components.aipc_info_client:SetByteArray("aip_info_color", nil, true)
	end
end

function Quality:SetVal(q)
	q = clampQuality(q)
	self.quality = q
	self.qualities = { [q] = getStackSize(self.inst) }
	self:syncToClient()
end

function Quality:DoDelta(delta)
	delta = math.floor(tonumber(delta) or 0)
	self:SyncStackSize()

	local qualities = {}
	for quality = QUALITY_MIN, QUALITY_MAX do
		local count = self.qualities[quality] or 0
		if count > 0 then
			local nextQuality = clampQuality(quality + delta)
			qualities[nextQuality] = (qualities[nextQuality] or 0) + count
		end
	end

	self.qualities = qualities
	self.quality = getTopQuality(self.qualities)
	self:syncToClient()
end

-- 同步品质计数与堆叠数量，兜底处理直接 SetStackSize 的情况。
function Quality:SyncStackSize(stacksize)
	stacksize = math.max(1, math.floor(stacksize or getStackSize(self.inst)))
	local total = getCountsTotal(self.qualities)

	if total <= 0 then
		self.qualities = { [self.quality] = stacksize }
	elseif total < stacksize then
		self.qualities[self.quality] = (self.qualities[self.quality] or 0) + stacksize - total
	elseif total > stacksize then
		takeCounts(self.qualities, total - stacksize)
	end

	self.quality = getTopQuality(self.qualities)
	self:syncToClient()
end

-- 合并另一组品质数量到当前堆中。
function Quality:AddQualities(qualities)
	self:SyncStackSize()

	for quality, count in pairs(readCounts(qualities)) do
		self.qualities[quality] = (self.qualities[quality] or 0) + count
	end

	self.quality = getTopQuality(self.qualities)
	self:syncToClient()
end

-- 从当前堆中取出指定数量，并返回取出的品质数量。
function Quality:TakeQualities(count)
	self:SyncStackSize()

	local qualities = takeCounts(self.qualities, count)
	self.quality = getTopQuality(self.qualities)
	self:syncToClient()

	return qualities
end

-- 使用指定的品质数量覆盖当前堆。
function Quality:SetQualities(qualities)
	self.qualities = readCounts(qualities)
	self.quality = getTopQuality(self.qualities)
	self:SyncStackSize()
end

function Quality:IsMixed()
	return isMixedCounts(self.qualities)
end

function Quality:syncToClient()
	if TheWorld ~= nil and not TheWorld.ismastersim then
		return
	end

	if self.inst.components.aipc_info_client then
		self.inst.components.aipc_info_client:SetUInt("aip_quality", self.quality)
		self.inst.components.aipc_info_client:SetString("aip_info", self:GetName())
		self.inst.components.aipc_info_client:SetByteArray("aip_info_color", self:GetColor())
	end
end

function Quality:GetVal()
	if TheWorld ~= nil and not TheWorld.ismastersim and self.inst.components.aipc_info_client then
		local clientQuality = self.inst.components.aipc_info_client:Get("aip_quality")
		if clientQuality ~= nil and clientQuality > 0 then
			return clientQuality
		end
	end

	return self.quality
end

function Quality:GetName()
	local name = QUALITY_LANG[self:GetVal()] or ""
	return self:IsMixed() and name..MIXED_SUFFIX or name
end

function Quality:GetColor()
	return QUALITY_COLORS[self:GetVal()]
end

function Quality:OnSave()
	self:SyncStackSize()

	return {
		quality = self.quality,
		qualities = writeCounts(self.qualities),
	}
end

function Quality:OnLoad(data)
	if data ~= nil then
		self.quality = clampQuality(data.quality)
		self.qualities = readCounts(data.qualities)

		if getCountsTotal(self.qualities) <= 0 then
			self.qualities = { [self.quality] = getStackSize(self.inst) }
		end
	end

	self:SyncStackSize()
end

return Quality
