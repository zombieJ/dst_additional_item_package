local petConfig = require("configurations/aip_pet")
local QUALITY_LANG = petConfig.QUALITY_LANG
local QUALITY_COLORS = petConfig.QUALITY_COLORS

local QUALITY_MIN = 1
local QUALITY_MAX = 5

_G.aipTypePrint("thx", petConfig)

_G.aipTypePrint(QUALITY_LANG)

_G.aipTypePrint(QUALITY_COLORS)

local Quality = Class(function(self, inst)
	self.inst = inst
	self.quality = 1
	self:InitNetKeys()
	self:syncToClient()
end)

function Quality:InitNetKeys()
	if self.inst.components.aipc_info_client then
		self.inst.components.aipc_info_client:SetString("aip_info", nil, true)
		self.inst.components.aipc_info_client:SetByteArray("aip_info_color", nil, true)
	end
end

function Quality:SetVal(q)
	self.quality = math.min(QUALITY_MAX, math.max(QUALITY_MIN, q))
	self:syncToClient()
end

function Quality:DoDelta(delta)
	self:SetVal(self.quality + delta)
end

function Quality:syncToClient()
	if self.inst.components.aipc_info_client then
		if self.quality > 1 then
			self.inst.components.aipc_info_client:SetString("aip_info", self:GetName())
		else
			self.inst.components.aipc_info_client:SetString("aip_info", "")
		end

		self.inst.components.aipc_info_client:SetByteArray("aip_info_color", self:GetColor())
	end
end

function Quality:GetVal()
	return self.quality
end

function Quality:GetName()
	return QUALITY_LANG[self.quality]
end

function Quality:GetColor()
	return QUALITY_COLORS[self.quality]
end

function Quality:OnSave()
	return { quality = self.quality }
end

function Quality:OnLoad(data)
	if data ~= nil and data.quality ~= nil then
		self.quality = data.quality
	end
	self:syncToClient()
end

return Quality
