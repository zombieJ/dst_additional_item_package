local petConfig = require("configurations/aip_pet")
local QUALITY_LANG = petConfig.QUALITY_LANG
local QUALITY_COLORS = petConfig.QUALITY_COLORS

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
		aipPrint("InitNetKeys")
		self.inst.components.aipc_info_client:SetString("aip_info", nil, true)
		self.inst.components.aipc_info_client:SetByteArray("aip_info_color", nil, true)
	end
end

function Quality:SetQuality(q)
	self.quality = q
	self:syncToClient()
end

function Quality:syncToClient()
	if self.inst.components.aipc_info_client then
		self.inst.components.aipc_info_client:SetString("aip_info", self:GetName())
		self.inst.components.aipc_info_client:SetByteArray("aip_info_color", self:GetColor())

		aipPrint("syncToClient", self:GetName(), self:GetColor())
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
