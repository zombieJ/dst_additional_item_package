local dev_mode = aipGetModConfig("dev_mode") == "enabled"

local VISIBLE_DURAION = dev_mode and 3 or 10


local QUALITY_COLORS = require("configurations/aip_pet").QUALITY_COLORS

local function syncClientAura(inst)
	if inst.components.aipc_petable ~= nil then
		inst.components.aipc_petable:ShowAura()
	end
end

-- 双端通用，宠物组件
local Petable = Class(function(self, inst)
	self.inst = inst
	self.aura = nil
	self.auraTask = nil

	self.inst:AddTag("aip_petable")

	self.syncAura = net_event(inst.GUID, "aipc_petable.sync_aura")
	self.quality = net_tinybyte(inst.GUID, "aipc_petable.quality", "aipc_petable.quality_dirty")
	if TheWorld.ismastersim then
		self.quality:set(dev_mode and 3 or 1)
	end
	if not TheNet:IsDedicated() then
        inst:ListenForEvent("aipc_petable.sync_aura", syncClientAura)
	end
end)

function Petable:GetQuality()
	return self.quality:value()
end

-- 获取捕捉概率
function Petable:GetQualityChance()
	local chances = { 1, 0.6, 0.3, 0.1, 0.05 }
	return chances[self:GetQuality()] or 0
end

function Petable:SetQuality(val)
	if TheWorld.ismastersim then
		self.quality:set(val)
	end
end

function Petable:CleanAura()
	if self.aura ~= nil then
		aipRemove(self.aura)
		self.aura = nil
	end
	if self.auraTask ~= nil then
		self.auraTask:Cancel()
		self.auraTask = nil
	end
end

function Petable:ShowClientAura()
	self.syncAura:push()
end

function Petable:ShowAura()
	if not TheNet:IsDedicated() then
		if self.aura == nil then
			-- 展示 Aura
			self.aura = SpawnPrefab("aip_aura_buffer")
			self.inst:AddChild(self.aura)

			local color = QUALITY_COLORS[self:GetQuality()]
			self.aura.AnimState:OverrideMultColour(color[1] / 255, color[2] / 255, color[3] / 255, 1)
		end

		if self.auraTask ~= nil then
			self.auraTask:Cancel()
		end

		self.auraTask = self.inst:DoTaskInTime(VISIBLE_DURAION, function()
			self:CleanAura()
		end)
	end
end

function Petable:OnSave()
	return {
		quality = self:GetQuality(),
	}
end

function Petable:OnLoad(data)
	if data ~= nil then
		self:SetQuality(data.quality or 1)
	end
end

return Petable