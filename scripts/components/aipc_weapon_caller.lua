-- 跨端通用
local WeaponCaller = Class(function(self, inst)
	self.inst = inst
	self.weaponBox = nil

	self.inst:ListenForEvent("aipUnequipItem", function(inst, data)
		if data then
			self:TryCall(data.item)
		end
	end)
end)

function WeaponCaller:Bind(target)
	self.weaponBox = target
end

function WeaponCaller:TryCall(item)
	if not item then
		return
	end

	local prefab = item.prefab

	-- 延迟检查一下武器是否：已经销毁、手上没有武器
	self.inst:DoTaskInTime(0.1, function()
		-- 没销毁
		if item:IsValid() then
			return
		end

		-- 手上有武器
		if
			not self.inst.components.inventory or
			self.inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
		then
			return
		end

		-- 没有绑定箱子
		if not self.weaponBox then
			return
		end

		-- 寻找箱子里的同类武器
		local boxItem = self.weaponBox.components.container:FindItem(function(boxItem)
			return boxItem.prefab == prefab
		end)

		-- 没找到
		if not boxItem then
			return
		end

		-- 直接给玩家装备
		self.weaponBox.AnimState:PlayAnimation("launch")
		self.weaponBox.AnimState:PushAnimation("idle")

		aipSpawnPrefab(self.weaponBox, "aip_weapon_box_fx")
		aipSpawnPrefab(self.inst, "aip_weapon_box_fx").AnimState:PlayAnimation("end")

		self.weaponBox.components.container:DropItem(boxItem)
		self.inst.components.inventory:Equip(boxItem)
	end)
end

return WeaponCaller