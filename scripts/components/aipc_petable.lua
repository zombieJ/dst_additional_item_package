local dev_mode = aipGetModConfig("dev_mode") == "enabled"

local VISIBLE_DURAION = dev_mode and 3 or 10

local petConfig = require("configurations/aip_pet")

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

	-- 宠物信息，因为总是被赋值，所以这里不用保存
	self.data = nil

	--主人，默认为空
	self.owner = nil

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

			local color = petConfig.QUALITY_COLORS[self:GetQuality()]
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

-- 获取宠物信息，没有就随机（宠物信息是抓到时才会生成的）
function Petable:GetInfo()
	if self.data ~= nil then
		return self.data
	end

	local prefab = self.inst.prefab
	local quality = self.inst.components.aipc_petable:GetQuality()

	local data = {
		id = os.time(),			-- ID
		prefab = prefab,		-- 名字
		quality = quality,		-- 品质
		skills = {},			-- 技能
	}

	-- 根据品质等级添加对应数量的技能
	local skillCnt = 0
	for i = 1, 99 do -- 循环 99 次，理论上可能有人抓到不满足数量技能的宠物，但是概率极低
		local rndSkill = aipRandomEnt(petConfig.SKILL_LIST)

		if data.skills[rndSkill] == nil then
			local skillQuality = math.random(quality - 1, quality)

			data.skills[rndSkill] = {
				-- 随机技能质量
				quality = skillQuality,
				lv = 1,
			}
		
			skillCnt = skillCnt + 1
		end

		-- 到达对应数量了
		if skillCnt >= quality then
			break
		end
	end

	-- TODO: 如果 skillCnt 小于 quality 则给予 闪光 特效

	self.data = data

	return data
end

-- 设置宠物信息（临时设置，不保存）
function Petable:SetInfo(data, owner)
	self.owner = owner
	self.data = data
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