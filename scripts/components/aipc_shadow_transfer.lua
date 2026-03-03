-- 跨端通用
local Transfer = Class(function(self, inst)
	self.inst = inst
	self.sanityCost = TUNING.SANITY_MED
	self.target = nil
	self.aura = nil
	self.onToggle = nil

	self.prefabName = net_string(inst.GUID, "aipc_shadow_transfer_prefab", "aipc_shadow_transfer_prefab_dirty")

	-- 替换贴图名称
	self.inst:ListenForEvent("aipc_shadow_transfer_prefab_dirty", function()
		self.inst.overridedeployplacername = self.prefabName:value().."_placer"
	end)
end)

function Transfer:CanMark(target)
	if not target then
		return false
	end

	if self.inst:HasTag("aip_marked") then
		return false
	end

	-- 只有建筑可以被搬运
	if not target:HasTag("structure") then
		return false
	end

	-- 只有玩家可以建造的可以搬走
	if
		not IsRecipeValid(target.prefab) and
		not target:HasTag("aip_world_drop")
	then
		return false
	end

	return true
end

function Transfer:Mark(target, doer)
	if self.target then
		return
	end

	aipSpawnPrefab(target, "aip_shadow_wrapper").DoShow()

	self.inst:AddTag("aip_marked")
	self.aura = SpawnPrefab("aip_aura_transfer")
	self.target = target

	target:AddTag("aipc_transfer_marked")
	target:AddChild(self.aura)

	if self.onToggle ~= nil then
		self.onToggle(self.inst, true)
	end

	self.prefabName:set(target.prefab)

	-- Damage Sanity
	if doer.components.sanity then
		doer.components.sanity:DoDelta(-TUNING.SANITY_MED)
	end
end

function Transfer:MoveTo(pt, doer)
	if not self.target then
		return
	end

	-- 位移
	if self.target.Physics ~= nil then
		self.target.Physics:Teleport(pt.x, pt.y, pt.z)
	else
		self.target.Transform:SetPosition(pt.x, pt.y, pt.z)
	end
	aipSpawnPrefab(self.target, "aip_shadow_wrapper").DoShow()

	-- 直接替换掉
	local container = self.inst.components.inventoryitem:GetContainer()
	if doer ~= nil and doer.components.inventory ~= nil then
		doer.components.inventory:GiveItem(SpawnPrefab("aip_shadow_transfer"))
	end

	-- 清理
	self.target:RemoveTag("aipc_transfer_marked")
	self.target:RemoveChild(self.aura)
	self.target = nil

	self.inst:RemoveTag("aip_marked")
	self.aura:Remove()
	self.aura = nil

	self.inst.overridedeployplacername = nil

	-- Damage Sanity
	if doer.components.sanity then
		doer.components.sanity:DoDelta(-TUNING.SANITY_MED)
	end

	if self.onToggle ~= nil then
		self.onToggle(self.inst, false)
	end

	aipRemove(self.inst)
end

return Transfer