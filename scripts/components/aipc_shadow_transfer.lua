-- 跨端通用
local Transfer = Class(function(self, inst)
	self.inst = inst
	self.target = nil
	self.aura = nil
	self.onToggle = nil

	self.prefabName = net_string(inst.GUID, "aipc_shadow_transfer_prefab", "aipc_shadow_transfer_prefab_dirty")
end)

function Transfer:CanMark(target)
	if not target or not target.Physics then
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
	if not IsRecipeValid(target.prefab) then
		return false
	end

	return true
end

function Transfer:Mark(target)
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
end

function Transfer:MoveTo(pt)
	if not self.target then
		return
	end

	-- 位移
	self.target.Physics:Teleport(pt.x, pt.y, pt.z)

	-- 清理
	self.target:RemoveTag("aipc_transfer_marked")
	self.target:RemoveChild(self.aura)
	self.target = nil

	self.inst:RemoveTag("aip_marked")
	self.aura:Remove()
	self.aura = nil

	if self.onToggle ~= nil then
		self.onToggle(self.inst, false)
	end
end

return Transfer