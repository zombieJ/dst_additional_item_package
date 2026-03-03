local petConfig = require("configurations/aip_pet")
local QUALITY_LANG = petConfig.QUALITY_LANG
local QUALITY_COLORS = petConfig.QUALITY_COLORS

local Quality = Class(function(self, inst)
	self.inst = inst
	self.quality = 0
end)

function Quality:SetQuality(q)
	self.quality = q
	self:syncToClient()
end

function Quality:syncToClient()
	if self.inst.components.aipc_info_client then
		self.inst.components.aipc_info_client:SetString("aip_quality", self:GetName())
		self.inst.components.aipc_info_client:SetByteArray("aip_quality_color", self:GetColor())
	end
end

function Quality:GetQuality()
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
